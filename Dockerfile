ARG TERRAFORM_VERSION

ARG AWSCLI_VERSION=2.7.32
ARG HCLEDIT_VERSION=0.2.2
ARG TFAUTOMV_VERSION=0.5.0
ARG KUBECTL_VERSION=v1.28.9
################################################################
################################################################

FROM debian:bullseye-20240423-slim AS base

LABEL vendor="Binbash Leverage (info@binbash.com.ar)"

################################
# Versions
################################

ARG AWSCLI_VERSION
ARG HCLEDIT_VERSION
ARG TFAUTOMV_VERSION
ARG KUBECTL_VERSION
ARG BUILDPLATFORM
ARG TARGETPLATFORM

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
        git \
        vim
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
ARG TFAUTOMV_VERSION
ARG KUBECTL_VERSION
ARG BUILDPLATFORM
ARG TARGETPLATFORM

################################
# Setting platform
################################
RUN if [  $(echo "${TARGETPLATFORM}" | grep -E "^.*arm64.*$" | wc -l) -gt 0 ]; \
    then \
      echo "PLATFORM=arm64" >> .machinetype.env; \
      echo "AWSPLATFORM=aarch64" >> .machinetype.env; \
    else \
      if [  $(echo "${TARGETPLATFORM}" | grep -E "^.*amd64.*$" | wc -l) -gt 0 ]; \
      then \
        echo "PLATFORM=amd64" >> .machinetype.env; \
        echo "AWSPLATFORM=x86_64" >> .machinetype.env; \
      else \
        exit 1; \
      fi; \
    fi

################################
# Install Terraform
################################

RUN ["/bin/bash", "-c", ". .machinetype.env && \
    wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${PLATFORM}.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_${PLATFORM}.zip && \
    mv terraform /usr/local/bin/ && \
    ln -s /usr/local/bin/terraform /bin/terraform && \
    terraform --version "]

################################
# Install AWS CLI
################################

RUN ["/bin/bash", "-c", ". .machinetype.env && \
    curl \"https://awscli.amazonaws.com/awscli-exe-linux-${AWSPLATFORM}-${AWSCLI_VERSION}.zip\" -o awscliv2.zip && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws"]

################################################################
################################################################

FROM leverage-base AS leverage-toolbox

################################
# Versions
################################

ARG TERRAFORM_VERSION
ARG AWSCLI_VERSION
ARG HCLEDIT_VERSION
ARG TFAUTOMV_VERSION
ARG KUBECTL_VERSION
ARG BUILDPLATFORM
ARG TARGETPLATFORM

################################
# Setting platform
################################
RUN if [  $(echo "${TARGETPLATFORM}" | grep -E "^.*arm64.*$" | wc -l) -gt 0 ]; \
    then \
      echo "PLATFORM=arm64" >> .machinetype.env; \
      echo "TFAUTOMVPLATFORM=arm64" >> .machinetype.env; \
    else \
      if [  $(echo "${TARGETPLATFORM}" | grep -E "^.*amd64.*$" | wc -l) -gt 0 ]; \
      then \
        echo "PLATFORM=amd64" >> .machinetype.env; \
        echo "TFAUTOMVPLATFORM=x86_64" >> .machinetype.env; \
      else \
        exit 1; \
      fi; \
    fi

################################
# Install HCLEdit
################################

RUN ["/bin/bash", "-c", ". .machinetype.env && \
    curl -LO \"https://github.com/minamijoyo/hcledit/releases/download/v${HCLEDIT_VERSION}/hcledit_${HCLEDIT_VERSION}_linux_${PLATFORM}.tar.gz\" && \
    tar -xzf hcledit_${HCLEDIT_VERSION}_linux_${PLATFORM}.tar.gz hcledit && \
    chmod +x hcledit && \
    mv hcledit /usr/local/bin/hcledit && \
    rm hcledit_${HCLEDIT_VERSION}_linux_${PLATFORM}.tar.gz"]

################################
# Install TFautomv
################################

RUN ["/bin/bash", "-c", ". .machinetype.env && \
    curl -LO \"https://github.com/padok-team/tfautomv/releases/download/v${TFAUTOMV_VERSION}/tfautomv_${TFAUTOMV_VERSION}_Linux_${TFAUTOMVPLATFORM}.tar.gz\" && \
    tar -xvf tfautomv_${TFAUTOMV_VERSION}_Linux_${TFAUTOMVPLATFORM}.tar.gz && \
    chmod +x tfautomv && \
    mv tfautomv /usr/local/bin/tfautomv && \
    rm tfautomv_${TFAUTOMV_VERSION}_Linux_${TFAUTOMVPLATFORM}.tar.gz"]

################################
# Install Kubectl
################################

RUN ["/bin/bash", "-c", ". .machinetype.env && \
    curl -LO \"https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${PLATFORM}/kubectl\" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/kubectl"]

################################
# Install Scripts
################################

RUN mkdir -p /root/scripts/aws-mfa
COPY ./scripts/aws-mfa/aws-mfa-entrypoint.sh  /root/scripts/aws-mfa/aws-mfa-entrypoint.sh
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
