ARG TERRAFORM_VERSION

FROM hashicorp/terraform:${TERRAFORM_VERSION}

LABEL vendor="Binbash Leverage (info@binbash.com.ar)"

ARG GLIBC_VERSION=2.34-r0
ARG AWSCLI_VERSION=2.4.7
ARG AWSVAULT_VERSION=v6.3.1
ARG HCLEDIT_VERSION=0.2.2

# Install python3 and other useful dependencies
RUN apk update
RUN set -ex && \
        apk add ca-certificates && update-ca-certificates && \
	apk add --no-cache --update \
        curl \
        unzip \
        bash \
        make \
        tree \
        tzdata \
        groff \
        jq \
        oath-toolkit-oathtool \
        python3
RUN rm /var/cache/apk/*

# Download and install glibc
# NOTE: Keep an eye on the issue https://github.com/aws/aws-cli/pull/6352 regarding installation of the AWS CLI from source in order to avoid
# the need of installing glibc
# With newer versions of Alpine (e.g. 3.16, used in Terraform 1.3.5 container image) this error can show up:
# ERROR: glibc-2.34-r0: trying to overwrite etc/nsswitch.conf owned by alpine-baselayout-data-3.2.0-r23
# if this happen, use the --force-overwrite flag in apk add
# issue here https://github.com/sgerrand/alpine-pkg-glibc/issues/185
RUN curl -sL "https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub" -o /etc/apk/keys/sgerrand.rsa.pub \
        && curl -sLO "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk" \
        && curl -sLO "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk" \
        && apk add --no-cache --force-overwrite \
        glibc-${GLIBC_VERSION}.apk \
        glibc-bin-${GLIBC_VERSION}.apk \
        && rm glibc-${GLIBC_VERSION}.apk glibc-bin-${GLIBC_VERSION}.apk

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWSCLI_VERSION}.zip" -o awscliv2.zip \
        && unzip awscliv2.zip \
        && ./aws/install \
        && rm -rf awscliv2.zip aws

# Add aws-mfa script
RUN mkdir -p /root/scripts/aws-mfa
COPY ./scripts/aws-mfa/aws-mfa-entrypoint.sh  /root/scripts/aws-mfa/aws-mfa-entrypoint.sh
# Add aws-sso scripts
RUN mkdir -p /root/scripts/aws-sso
COPY ./scripts/aws-sso/aws-sso-configure.sh  /root/scripts/aws-sso/aws-sso-configure.sh
COPY ./scripts/aws-sso/aws-sso-login.sh  /root/scripts/aws-sso/aws-sso-login.sh
COPY ./scripts/aws-sso/aws-sso-logout.sh  /root/scripts/aws-sso/aws-sso-logout.sh
COPY ./scripts/aws-sso/aws-sso-entrypoint.sh  /root/scripts/aws-sso/aws-sso-entrypoint.sh

RUN chmod -R +x /root/scripts/

# Add aws-vault
RUN curl -LO "https://github.com/99designs/aws-vault/releases/download/${AWSVAULT_VERSION}/aws-vault-linux-amd64" \
        && chmod +x aws-vault-linux-amd64 \
        && mv aws-vault-linux-amd64 /usr/local/bin/aws-vault

# Install hcledit
RUN curl -LO "https://github.com/minamijoyo/hcledit/releases/download/v${HCLEDIT_VERSION}/hcledit_${HCLEDIT_VERSION}"_linux_amd64.tar.gz \
        && tar -xzf hcledit_${HCLEDIT_VERSION}_linux_amd64.tar.gz hcledit -C /usr/local/bin \
        && rm hcledit_${HCLEDIT_VERSION}_linux_amd64.tar.gz

# Install tfautomv
ARG TFAUTOMV_VERSION="0.5.0"
RUN curl -LO "https://github.com/padok-team/tfautomv/releases/download/v${TFAUTOMV_VERSION}/tfautomv_${TFAUTOMV_VERSION}_Linux_x86_64.tar.gz" \
    && tar -xvf tfautomv_${TFAUTOMV_VERSION}_Linux_x86_64.tar.gz \
    && chmod +x tfautomv \
    && mv tfautomv /usr/local/bin/tfautomv \
    && rm tfautomv_${TFAUTOMV_VERSION}_Linux_x86_64.tar.gz
ENTRYPOINT ["terraform"]
