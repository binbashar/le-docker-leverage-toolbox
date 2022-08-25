.PHONY: help
SHELL         := /bin/bash
MAKEFILE_PATH := ./Makefile
MAKEFILES_DIR := ./@bin/makefiles
MAKEFILES_VER := v0.2.9

LOCAL_OS_USER_ID      = $(shell id -u)
LOCAL_OS_GROUP_ID     = $(shell id -g)
LOCAL_PWD_DIR         = $(shell pwd)
LOCAL_OS_AWS_CONF_DIR := ~/.aws/bb
AWS_REGION            := us-east-1
AWS_IAM_PROFILE       := bb-apps-devstg-devops
AWS_DOCKER_ENTRYPOINT := aws

# ###############################################################
# TERRAFORM AND CLI VERSIONS                                    #
# ###############################################################
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
TERRAFORM_TAG    := 1.2.7
LEVERAGE_CLI_TAG := 0.0.3
DOCKER_TAG       := ${TERRAFORM_TAG}-${LEVERAGE_CLI_TAG}
DOCKER_REPO_NAME := binbash
DOCKER_IMG_NAME  := leverage-toolbox
# ###############################################################

CURRENT_TAG      := $(shell git describe --tags --abbrev=0 2> /dev/null)

#
# ADDITIONAL ARGS FOR THE DOCKER BUILD PROCESS
#
ADDITIONAL_DOCKER_ARGS := "TERRAFORM_VERSION='${TERRAFORM_TAG}'"

#
# GIT-RELEASE
#
# pre-req -> https://github.com/pnikosis/semtag
GIT_RELEASE_IMAGE_VERSION := 'latest'
define GIT_CHGLOG_CMD_PREFIX
docker run --rm \
-v ${LOCAL_PWD_DIR}:/data:rw \
-it binbash/git-release:${GIT_RELEASE_IMAGE_VERSION}
endef

#
# AWS CLI PREFIX
#
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

#==============================================================#
# INITIALIZATION                                               #
#==============================================================#
init-makefiles: ## initialize makefiles
	@rm -rf ${MAKEFILES_DIR}
	@mkdir -p ${MAKEFILES_DIR}
	@git clone https://github.com/binbashar/le-dev-makefiles.git ${MAKEFILES_DIR} -q
	@cd ${MAKEFILES_DIR} && git checkout ${MAKEFILES_VER} -q

-include ${MAKEFILES_DIR}/circleci/circleci.mk
-include ${MAKEFILES_DIR}/release-mgmt/release.mk
-include ${MAKEFILES_DIR}/docker/docker-hub-build-push-single-arg-multi-arch.mk

#==============================================================#
# DOCKER | BUILD ALL IMAGES                                    #
#==============================================================#
build-all: check-version-bumping build ## build all docker images
build-local: build ## build all docker images

#==============================================================#
# DOCKER | TEST ALL IMAGES                                     #
#==============================================================#
test-all: build-all test ## build all docker images
test-local: build-local test ## build all docker images

#==============================================================#
# DOCKER | BUILD AND PUSH ALL IMAGES                           #
#==============================================================#
push-all: check-version-bumping setver push clearver create-changelog ## build all docker images

#==============================================================#
# DOCKER | GENERATE CHANGELOG                                  #
#==============================================================#
create-changelog:
	${GIT_CHGLOG_CMD_PREFIX} -o CHANGELOG.md --next-tag ${DOCKER_TAG} \
	| grep -v 'Warning: Permanently added the RSA host key for IP address'
	sudo chown -R ${LOCAL_OS_USER_ID}:${LOCAL_OS_GROUP_ID} ./CHANGELOG.md
	git status
	git add CHANGELOG.md
	git commit -m "Updating CHANGELOG.md via make create-changelog for ${DOCKER_TAG} [ci skip]"
	git push origin master
	git tag ${DOCKER_TAG} -a -m "Tag created via make create-changelog [ci skip]"
	git push origin ${DOCKER_TAG}

#==============================================================#
# DOCKER | SPECIFIC RECIPES									   #
#==============================================================#

#
# check version bumping was done (avoid pushing already existing images)
#
check-version-bumping:
ifeq ($(CURRENT_TAG),)
	@echo "Totally new version set to ${DOCKER_TAG}"
else
ifeq ($(CURRENT_TAG),$(DOCKER_TAG))
	@echo 'Version not bumped'; \
	exit 1
else
	@echo "Verion bumped from $(CURRENT_TAG) to ${DOCKER_TAG}"
endif
endif

#==============================================================#
# TESTS														   #
#==============================================================#

test: run-awscli-version run-python-version run-terraform-version ## ci docker image tests

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

