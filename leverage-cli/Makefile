.PHONY: build
SHELL            := /bin/bash
MAKEFILES_DIR    := ../@bin/makefiles

# 
# TERRAFORM AND CLI VERSIONS
#
# The LEVERAGE_CLI_TAG should be set per TERRAFORM_TAG
# e.g. if you have TERRA 1.2.1 and LEVERAGE 0.0.1 and
# you update some script other that terraform in the image
# the LEVERAGE tag should be upgraded, let's say tp 0.0.2
# But if then you update the terraform tag to 1.3.0 the
# LEVERAGE tag should be resetted to bu used under this new
# terraform tag, e.g. 1.3.0 and 0.0.1
# The resulting images should be:
# 1.2.1-0.0.1
# 1.2.1-0.0.2
# 1.3.0-0.0.1
TERRAFORM_TAG    := 1.2.1
LEVEL            := 'patch'
SCRIPT           := 'bumpversion.sh'
SHELL            := 'bash'

REQ_TARGET       := $(shell ${SHELL} -c "echo \"${MAKECMDGOALS}\" | cut -d \" \" -f 1")
BUMPING_TARGET   := 'build-leverage-cli'
SCRIPT_ACTION    := $(shell ${SHELL} -c "if [ \"${REQ_TARGET}\" == "${BUMPING_TARGET}" ]; then echo 'bump'; else echo 'retrieve'; fi")

DOCKER_TAG       := $(shell ${SHELL} ${SCRIPT} ${SCRIPT_ACTION} ${TERRAFORM_TAG} ${LEVEL})

DOCKER_REPO_NAME := binbash
DOCKER_IMG_NAME  := leverage-toolbox

LOCAL_OS_AWS_CONF_DIR := ~/.aws/bb
AWS_REGION            := us-east-1
AWS_IAM_PROFILE       := bb-apps-devstg-devops
AWS_DOCKER_ENTRYPOINT := aws

define AWSCLI_CMD_PREFIX
docker run -it --rm \
--name ${DOCKER_IMG_NAME} \
-v ${LOCAL_OS_AWS_CONF_DIR}:/root/.aws \
-e "AWS_DEFAULT_REGION=us-east-1" \
--entrypoint=${AWS_DOCKER_ENTRYPOINT} \
${DOCKER_REPO_NAME}/${DOCKER_IMG_NAME}:${DOCKER_TAG}
endef

help:
	@echo 'Available Commands:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf " - \033[36m%-18s\033[0m %s\n", $$1, $$2}'

-include ${MAKEFILES_DIR}/docker/docker-hub-build-push-single-arg-multi-arch.mk

#
# docker meta method
#
build-leverage-cli: setver build clearver

#
# docker settings
#
setver: ## set version
	@echo "Creating Dockerfile for ${DOCKER_TAG}" && \
	cp Dockerfile.template Dockerfile && \
	sed -i -E 's/TERRAFORM_VERSION/'${TERRAFORM_TAG}'/' Dockerfile

clearver: ## clear version files
	@echo "Deleting Dockerfile for ${DOCKER_TAG}..." && \
	rm Dockerfile

#
# docker run tests
#

# awscli
#
run-awscli-version: ## docker run awscli commands
	${AWSCLI_CMD_PREFIX} --version

# terraform & python
#
run-python-version: ## docker run python --version
	docker run -it --rm --entrypoint=python3 \
	${DOCKER_REPO_NAME}/${DOCKER_IMG_NAME}:${DOCKER_TAG} --version

run-terraform-version: ## docker run terraform --version
	docker run -it --rm \
	${DOCKER_REPO_NAME}/${DOCKER_IMG_NAME}:${DOCKER_TAG} --version

test: run-awscli-version run-python-version run-terraform-version ## ci docker image tests

