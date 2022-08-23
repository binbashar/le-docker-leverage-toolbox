.PHONY: help
SHELL         := /bin/bash
MAKEFILE_PATH := ./Makefile
MAKEFILES_DIR := ./@bin/makefiles
MAKEFILES_VER := v0.2.4

DOCKER_IMG    := "leverage-cli"

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

#==============================================================#
# DOCKER | BUILD ALL IMAGES                                    #
#==============================================================#
build-all: ## build all docker images
	@set -e;\
	echo -----------------------;\
	echo DOCKER IMG: ${DOCKER_IMG};\
	echo -----------------------;\
			cd ${DOCKER_IMG};\
			make build-leverage-cli;\
			cd ..;\
	echo -----------------------;\
	echo "DOCKER BUILD DONE";\
	echo "";\


#==============================================================#
# DOCKER | TEST ALL IMAGES                                     #
#==============================================================#
test-all: ## build all docker images
	@set -e;\
	echo -----------------------;\
	echo DOCKER IMG: ${DOCKER_IMG};\
	echo -----------------------;\
			cd ${DOCKER_IMG};\
			make test;\
			cd ..;\
	echo -----------------------;\
	echo "DOCKER BUILD DONE";\
	echo "";\

#==============================================================#
# DOCKER | PUSH ALL IMAGES                                     #
#==============================================================#
push-all: ## build all docker images
	set -e;\
	echo -----------------------;\
	echo DOCKER IMG: ${DOCKER_IMG};\
	echo -----------------------;\
			cd ${DOCKER_IMG};\
			make push-leverage-cli;\
			cd ..;\
	echo -----------------------;\
	echo "DOCKER BUILD DONE";\
	echo "";\
