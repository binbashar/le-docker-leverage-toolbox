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
SSO_ROLE_NAME=${SSO_ROLE_NAME:-$(hcledit -f "$ACCOUNT_CONFIG_FILE" attribute get sso_role | sed 's/"//g')}
SSO_CACHE_DIR=${SSO_CACHE_DIR:-/root/tmp/$PROJECT/sso/cache}
SSO_TOKEN_FILE_NAME='token'
debug "SCRIPT_LOG_LEVEL=$SCRIPT_LOG_LEVEL"
debug "COMMON_CONFIG_FILE=$COMMON_CONFIG_FILE"
debug "ACCOUNT_CONFIG_FILE=$ACCOUNT_CONFIG_FILE"
debug "BACKEND_CONFIG_FILE=$BACKEND_CONFIG_FILE"
debug "SSO_PROFILE_NAME=$SSO_PROFILE_NAME"
debug "SSO_ROLE_NAME=$SSO_ROLE_NAME"
debug "SSO_CACHE_DIR=$SSO_CACHE_DIR"
debug "SSO_TOKEN_FILE_NAME=$SSO_TOKEN_FILE_NAME"

# -----------------------------------------------------------------------------
# Configure accounts profiles
# -----------------------------------------------------------------------------
TOKEN=$(jq -r '.accessToken' "$SSO_CACHE_DIR/$SSO_TOKEN_FILE_NAME")
ACCOUNTS=$(aws sso list-accounts --access-token "$TOKEN")
debug "Accounts: $(echo "$ACCOUNTS" | jq -c '.')"

for account in $(echo "$ACCOUNTS" | jq -c '.accountList[]'); do
    PROFILE_NAME="$SSO_PROFILE_NAME-$(echo "$account" | jq -r '.accountName' | cut -d '-' -f2-)-$SSO_ROLE_NAME"
    info "Configuring $BOLD$PROFILE_NAME$RESET."

    aws configure set role_name "$SSO_ROLE_NAME" --profile "$PROFILE_NAME"
    aws configure set account_id "$(echo "$account" | jq -r '.accountId')" --profile "$PROFILE_NAME"
done

info "Account profiles written successfully!"
