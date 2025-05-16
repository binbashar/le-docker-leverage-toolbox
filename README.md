<div align="center">
    <img src="https://raw.githubusercontent.com/binbashar/le-ref-architecture-doc/master/docs/assets/images/logos/binbash-leverage-banner.png" 
    alt="drawing" width="100%"/>
</div>

# le-docker-leverage

![GitHub](https://img.shields.io/github/license/binbashar/le-docker-leverage.svg)
![GitHub language count](https://img.shields.io/github/languages/count/binbashar/le-docker-leverage.svg)
![GitHub top language](https://img.shields.io/github/languages/top/binbashar/le-docker-leverage.svg)
![GitHub repo size](https://img.shields.io/github/repo-size/binbashar/le-docker-leverage.svg)
![GitHub issues](https://img.shields.io/github/issues/binbashar/le-docker-leverage.svg)
![GitHub closed issues](https://img.shields.io/github/issues-closed/binbashar/le-docker-leverage.svg)
![GitHub pull requests](https://img.shields.io/github/issues-pr/binbashar/le-docker-leverage.svg)
![GitHub closed pull requests](https://img.shields.io/github/issues-pr-closed/binbashar/le-docker-leverage.svg)
![GitHub release](https://img.shields.io/github/release/binbashar/le-docker-leverage.svg)
![GitHub Release Date](https://img.shields.io/github/release-date/binbashar/le-docker-leverage.svg)
![GitHub contributors](https://img.shields.io/github/contributors/binbashar/le-docker-leverage.svg)

![GitHub followers](https://img.shields.io/github/followers/binbashar.svg?style=social)
![GitHub forks](https://img.shields.io/github/forks/binbashar/le-docker-leverage.svg?style=social)
![GitHub stars](https://img.shields.io/github/stars/binbashar/le-docker-leverage.svg?style=social)
![GitHub watchers](https://img.shields.io/github/watchers/binbashar/le-docker-leverage.svg?style=social)

# Release Management

### CircleCi PR auto-release job
<div align="left">
  <img src="https://raw.githubusercontent.com/binbashar/le-docker-leverage/master/%40doc/figures/circleci.png" alt="leverage-circleci" width="130"/>
</div>

- ### 🚀 [**>> View Releases here <<**](https://github.com/binbashar/le-docker-leverage/releases) 🚀
- [**pipeline-job**](https://app.circleci.com/pipelines/github/binbashar/le-docker-leverage) (**NOTE:** Will only run after merged PR)
- [**changelog**](https://github.com/binbashar/le-docker-leverage/blob/master/CHANGELOG.md) 

# Version bumping process

*This process will be automated in the furure.*

For now is manual, but there is a check, when image built is requested, verifying whether or not the version was bumped.

Container image tagging or versioning process is as follows:

- Image tag is composed of <TOFU_VERSION>-<LEVERAGE_TOOLBOX_IMAGE_VERSION>
- The full name then is *binbash/leverage-toolbox:<TOFU_VERSION>-<LEVERAGE_TOOLBOX_IMAGE_VERSION>*
- When bumping version (tag):
  - If TOFU_VERSION has changed:
    - LEVERAGE_TOOLBOX_IMAGE_VERSION = 0.0.1
  - If TOFU_VERSION has not changed:
    - LEVERAGE_TOOLBOX_IMAGE_VERSION is bumped (using semver as needed)
    
E.g., given image *binbash/leverage-toolbox:1.2.1-0.0.1*:

- We know it contains Terraform 1.2.1 and it is the first iteration for this toolbox set.
- If something other than Terraform is updated the LEVERAGE_TOOLBOX_IMAGE_VERSION is bumped, e.g.:
  - *binbash/leverage-toolbox:1.2.1-0.0.2* or *binbash/leverage-toolbox:1.2.1-0.1.0* (these examples are a patch and a minor)
- If Terraform is updated then LEVERAGE_TOOLBOX_IMAGE_VERSION is reset and TOFU_VERSION is bumped accordingly to the Terraform version, e.g.:
  - *binbash/leverage-toolbox:1.2.2-0.0.1* or *binbash/leverage-toolbox:1.3.0-0.0.1*

Another example, e.g., given image *binbash/leverage-toolbox:1.2.1-0.5.3*:

- We know it contains Terraform 1.2.1 and it is the iteration 0.5.3 for the toolbox set.
- If something other than Terraform is updated the LEVERAGE_TOOLBOX_IMAGE_VERSION is bumped, e.g.:
  - *binbash/leverage-toolbox:1.2.1-0.5.4* or *binbash/leverage-toolbox:1.2.1-0.6.0* (these examples are a patch and a minor)
- If Terraform is updated then LEVERAGE_TOOLBOX_IMAGE_VERSION is reset and TOFU_VERSION is bumped accordingly to the Terraform version, e.g.:
  - *binbash/leverage-toolbox:1.2.2-0.0.1* or *binbash/leverage-toolbox:1.3.0-0.0.1*

## Where to change it?

In the `Makefile`:

``` shell
# ###############################################################
# TOFU AND CLI VERSIONS                                         #
# ###############################################################
# The LEVERAGE_CLI_TAG should be set per TOFU_TAG
# e.g. if you have TOFU 1.6.0 and LEVERAGE 0.0.1 and
# you update some script other that tofu in the image
# the LEVERAGE tag should be upgraded, let's say to 0.0.2
# But if then you update the tofu tag to 1.3.0 the
# LEVERAGE tag should be reset but used under this new
# tofu tag, e.g. 1.6.0 and 0.0.1
# The resulting images should be:
# 1.2.1-0.0.1
# 1.2.1-0.0.2
# 1.3.0-0.0.1
TOFU_TAG         := 1.6.0
LEVERAGE_CLI_TAG := 0.0.2
```

**NOTE** In any case, as a rule of thumb no version (tag) has to be pushed into the image repository if it already exists there.

# Dev and Deploy

The container image components are, basically, the `Dockerfile` and the `scripts/*`.

Then, there is a Makefile and a few other configuration files for tools.

*Note* for an image to be built the version (a.k.a. the image tag) has to change!

## Pipelines

CircleCi pipelines are being used.

There are two basic pipelines: SumoLogic tests and BuildDeploy.

The first one will be triggered in any modification.

The second one, will be only when `Dockerfile`, `scripts/*` or `Makefile` are changed.

## Basic Procedure

- 1. create your working branch
- 2. do your changes
- 3. if any of `Dockerfile`, `scripts/*` or `Makefile` were modified then bump the version
- 4. create a PR (add labels!)
- 5. merge the PR

If none of the files listed in 3 were modified (e.g. only README.md changed), the PR can be merged and no image will be deployed.

Finally the image can be found [here](https://hub.docker.com/r/binbash/leverage-toolbox/tags).

# Working locally

Requirements: some container engine up and running.

``` shell
git clone git@github.com:binbashar/le-docker-leverage-toolbox.git
cd le-docker-leverage-toolbox
make init-makefiles
# only for building the image
make build-local
# or just for testing
make test-local
```

# TODO List

- [TODO] [2022/08/25] Check CircleCI-Slack connection
