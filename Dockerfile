ARG TERRAFORM_VERSION

ARG AWSCLI_VERSION=2.7.32
ARG HCLEDIT_VERSION=0.2.2

################################################################
################################################################

FROM debian:11.6-slim AS base

LABEL vendor="Binbash Leverage (info@binbash.com.ar)"

################################
# Versions
################################

ARG AWSCLI_VERSION
ARG HCLEDIT_VERSION

################################
# System update and intalls
################################

RUN \
# Update
apt-get update && \
apt-get install -y \
        curl \
        unzip \
        bash \
        make \
        tree \
        tzdata \
        groff \
        jq \
        oathtool \
        wget \
        python3 \
        git
        # oath-toolkit-oathtool \

#RUN ln -s /usr/bin/python3 python

################################################################
################################################################

FROM base AS leverage-base

################################
# Versions
################################

ARG TERRAFORM_VERSION
ARG AWSCLI_VERSION
ARG HCLEDIT_VERSION

################################
# Install Terraform
################################

# Download terraform for linux
RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Unzip
RUN unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Move to local bin
RUN mv terraform /usr/local/bin/
RUN ln -s /usr/local/bin/terraform /bin/terraform
# Check that it's installed
RUN terraform --version

################################
# Install AWS CLI
################################

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWSCLI_VERSION}.zip" -o awscliv2.zip \
        && unzip awscliv2.zip \
        && ./aws/install \
        && rm -rf awscliv2.zip aws

################################################################
################################################################

FROM leverage-base AS leverage-toolbox

################################
# Versions
################################

ARG TERRAFORM_VERSION
ARG AWSCLI_VERSION
ARG HCLEDIT_VERSION

################################
# Install
################################

# Install hcledit
RUN curl -LO "https://github.com/minamijoyo/hcledit/releases/download/v${HCLEDIT_VERSION}/hcledit_${HCLEDIT_VERSION}"_linux_amd64.tar.gz \
        && tar -xzf hcledit_${HCLEDIT_VERSION}_linux_amd64.tar.gz hcledit \
        && chmod +x hcledit \
        && mv hcledit /usr/local/bin/hcledit \
        && rm hcledit_${HCLEDIT_VERSION}_linux_amd64.tar.gz

################################
# Install
################################

# Install tfautomv
ARG TFAUTOMV_VERSION="0.5.0"
RUN curl -LO "https://github.com/padok-team/tfautomv/releases/download/v${TFAUTOMV_VERSION}/tfautomv_${TFAUTOMV_VERSION}_Linux_x86_64.tar.gz" \
    && tar -xvf tfautomv_${TFAUTOMV_VERSION}_Linux_x86_64.tar.gz \
    && chmod +x tfautomv \
    && mv tfautomv /usr/local/bin/tfautomv \
    && rm tfautomv_${TFAUTOMV_VERSION}_Linux_x86_64.tar.gz

################################
# Install Kubectl
################################

ARG KUBECTL_VERSION="v1.23.15"
RUN curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/kubectl

################################
# Install
################################

# Add aws-mfa script
RUN mkdir -p /root/scripts/aws-mfa
COPY ./scripts/aws-mfa/aws-mfa-entrypoint.sh  /root/scripts/aws-mfa/aws-mfa-entrypoint.sh
# Add aws-sso scripts
RUN mkdir -p /root/scripts/aws-sso
COPY ./scripts/aws-sso/aws-sso-configure.sh  /root/scripts/aws-sso/aws-sso-configure.sh
COPY ./scripts/aws-sso/aws-sso-login.sh  /root/scripts/aws-sso/aws-sso-login.sh
COPY ./scripts/aws-sso/aws-sso-logout.sh  /root/scripts/aws-sso/aws-sso-logout.sh
COPY ./scripts/aws-sso/aws-sso-entrypoint.sh  /root/scripts/aws-sso/aws-sso-entrypoint.sh

################################
# Install
################################

RUN chmod -R +x /root/scripts/

################################
# Install
################################

ENTRYPOINT ["terraform"]
