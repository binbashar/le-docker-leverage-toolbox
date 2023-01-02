#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

# -----------------------------------------------------------------------------
# Formatting helpers
# -----------------------------------------------------------------------------
BOLD="\033[1m"
DATE="\033[0;90m"
ERROR="\033[41;37m"
INFO="\033[0;34m"
DEBUG="\033[0;32m"
RESET="\033[0m"

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------
# Simple logging functions
function error { log "${ERROR}ERROR${RESET}\t$1" 0; }
function info { log "${INFO}INFO${RESET}\t$1" 1; }
function debug { log "${DEBUG}DEBUG${RESET}\t$1" 2; }
function log {
    if [[ $SCRIPT_LOG_LEVEL -gt $2 ]]; then
        printf "%b[%(%T)T]%b    %b\n" "$DATE" "$(date +%s)" "$RESET" "$1"
    fi
}

# -----------------------------------------------------------------------------
# Initialize variables
# -----------------------------------------------------------------------------
SCRIPT_LOG_LEVEL=${SCRIPT_LOG_LEVEL:-2}
PROJECT=$(hcledit -f "$COMMON_CONFIG_FILE" attribute get project | sed 's/"//g')
SSO_PROFILE_NAME=${SSO_PROFILE_NAME:-$PROJECT-sso}
SSO_CACHE_DIR=${SSO_CACHE_DIR:-/root/tmp/$PROJECT/sso/cache}
SSO_TOKEN_FILE_NAME='token'
debug "SCRIPT_LOG_LEVEL=$SCRIPT_LOG_LEVEL"
debug "COMMON_CONFIG_FILE=$COMMON_CONFIG_FILE"
debug "ACCOUNT_CONFIG_FILE=$ACCOUNT_CONFIG_FILE"
debug "BACKEND_CONFIG_FILE=$BACKEND_CONFIG_FILE"
debug "SSO_PROFILE_NAME=$SSO_PROFILE_NAME"
debug "AWS_CONFIG_FILE=$AWS_CONFIG_FILE"
debug "SSO_CACHE_DIR=$SSO_CACHE_DIR"
debug "SSO_TOKEN_FILE_NAME=$SSO_TOKEN_FILE_NAME"

# -----------------------------------------------------------------------------
# Configure accounts profiles
# -----------------------------------------------------------------------------
info "Clearing profiles"
awk '/^\[profile/{if($0~/profile '"'${SSO_PROFILE_NAME}'-"'/){found=1}else{found=""}} !found' "$AWS_CONFIG_FILE" > aws2 && mv aws2 "$AWS_CONFIG_FILE"

info "Getting available accounts and roles"
TOKEN=$(jq -r '.accessToken' "$SSO_CACHE_DIR/$SSO_TOKEN_FILE_NAME")
ACCOUNTS=$(aws sso list-accounts --access-token "$TOKEN")
debug "Accounts: $(echo "$ACCOUNTS" | jq -c '.')"

CONF_SSO_REGION=$(aws configure get sso_region --profile $SSO_PROFILE_NAME)
CONF_START_URL=$(aws configure get sso_start_url --profile $SSO_PROFILE_NAME)


for account in $(echo "$ACCOUNTS" | jq -c '.accountList[]'); do

    ACCOUNT_ROLES=$(aws sso list-account-roles --region us-east-1 --access-token $(jq -r '.accessToken'  "$SSO_CACHE_DIR/$SSO_TOKEN_FILE_NAME") --region us-east-1 --account-id $(echo "$account" | jq -r '.accountId'))
    for account_role in $(echo "$ACCOUNT_ROLES" | jq -c '.roleList[]'); do
        PROFILE_NAME="$SSO_PROFILE_NAME-$(echo "$account" | jq -r '.accountName' | cut -d '-' -f2-)-$(echo "$account_role" | jq -r '.roleName' | cut -d '-' -f2-)"

        info "Configuring $BOLD$PROFILE_NAME$RESET."

        RN=$(echo "$account_role" | jq -r '.roleName' | cut -d '-' -f2-)
        AI=$(echo "$account" | jq -r '.accountId')
        aws configure set role_name "${RN}" --profile "$PROFILE_NAME"
        aws configure set bbchk "$( echo ${RN}${AI}| md5sum | cut -d ' ' -f1)" --profile "$PROFILE_NAME"
        aws configure set account_id "${AI}" --profile "$PROFILE_NAME"
        aws configure set sso_region "$CONF_SSO_REGION" --profile "$PROFILE_NAME"
        aws configure set sso_start_url "$CONF_START_URL" --profile "$PROFILE_NAME"
    done
done

info "Account profiles written successfully!"
