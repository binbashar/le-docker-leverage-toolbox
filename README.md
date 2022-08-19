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

- [**pipeline-job**](https://app.circleci.com/pipelines/github/binbashar/le-docker-leverage) (**NOTE:** Will only run after merged PR)
- [**releases**](https://github.com/binbashar/le-docker-leverage/releases) 
- [**changelog**](https://github.com/binbashar/le-docker-leverage/blob/master/CHANGELOG.md) 

# Versioning process

*This process will be automated.*

Container image tagging or versioning process is as follows:

- Image tag is composed of <TERRAFORM_VERSION>-<LEVERAGE_TOOLBOX_IMAGE_VERSION>
- The full name then is *binbash/leverage-toolbox:<TERRAFORM_VERSION>-<LEVERAGE_TOOLBOX_IMAGE_VERSION>*
- When bumping version (tag):
  - If TERRAFORM_VERSION has changed:
    - LEVERAGE_TOOLBOX_IMAGE_VERSION = 0.0.1
  - If TERRAFORM_VERSION has not changed:
    - LEVERAGE_TOOLBOX_IMAGE_VERSION is bumped (using semver as needed)
    
E.g., given image *binbash/leverage-toolbox:1.2.1-0.0.1*:

- We know it contains Terraform 1.2.1 and it is the first iteration for this toolbox set.
- If something other than Terraform is updated the LEVERAGE_TOOLBOX_IMAGE_VERSION is bumped, e.g.:
  - *binbash/leverage-toolbox:1.2.1-0.0.2* or *binbash/leverage-toolbox:1.2.1-0.1.0* (these examples are a patch and a minor)
- If Terraform is updated then LEVERAGE_TOOLBOX_IMAGE_VERSION is reset and TERRAFORM_VERSION is bumped accordingly to the Terraform version, e.g.:
  - *binbash/leverage-toolbox:1.2.2-0.0.1* or *binbash/leverage-toolbox:1.3.0-0.0.1*

Another example, e.g., given image *binbash/leverage-toolbox:1.2.1-0.5.3*:

- We know it contains Terraform 1.2.1 and it is the iteration 0.5.3 for the toolbox set.
- If something other than Terraform is updated the LEVERAGE_TOOLBOX_IMAGE_VERSION is bumped, e.g.:
  - *binbash/leverage-toolbox:1.2.1-0.5.4* or *binbash/leverage-toolbox:1.2.1-0.6.0* (these examples are a patch and a minor)
- If Terraform is updated then LEVERAGE_TOOLBOX_IMAGE_VERSION is reset and TERRAFORM_VERSION is bumped accordingly to the Terraform version, e.g.:
  - *binbash/leverage-toolbox:1.2.2-0.0.1* or *binbash/leverage-toolbox:1.3.0-0.0.1*

**NOTE** In any case, as a rule of thumb no version (tag) has to be pushed into the image repository if it already exists there.
