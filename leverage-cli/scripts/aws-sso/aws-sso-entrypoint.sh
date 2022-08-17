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
PROFILE=$(hcledit -f "$BACKEND_CONFIG_FILE" attribute get profile | sed 's/"//g')
SSO_PROFILE_NAME=${SSO_PROFILE_NAME:-$PROJECT-sso}
SSO_ROLE_NAME=${SSO_ROLE_NAME:-$(hcledit -f "$ACCOUNT_CONFIG_FILE" attribute get sso_role | sed 's/"//g')}
SSO_CACHE_DIR=${SSO_CACHE_DIR:-/root/tmp/$PROJECT/sso/cache}
debug "SCRIPT_LOG_LEVEL=$SCRIPT_LOG_LEVEL"
debug "COMMON_CONFIG_FILE=$COMMON_CONFIG_FILE"
debug "ACCOUNT_CONFIG_FILE=$ACCOUNT_CONFIG_FILE"
debug "BACKEND_CONFIG_FILE=$BACKEND_CONFIG_FILE"
debug "SSO_PROFILE_NAME=$SSO_PROFILE_NAME"
debug "SSO_ROLE_NAME=$SSO_ROLE_NAME"
debug "SSO_CACHE_DIR=$SSO_CACHE_DIR"


# -----------------------------------------------------------------------------
# Get profiles used by Terraform
# -----------------------------------------------------------------------------
RAW_PROFILES=()
# Most profiles should be found in `config.tf`
if [[ -f "config.tf" ]] && PARSED_PROFILES=$(grep -v 'lookup' config.tf | grep -E '^\s+profile'); then
    while IFS= read -r line ; do
        RAW_PROFILES+=("$(echo "$line" | sed 's/ //g' | sed 's/[\"\$\{\}]//g')")
    done <<< "$PARSED_PROFILES"
fi
# But some can be found in `locals.tf`
if [[ -f "locals.tf" ]] && PARSED_PROFILES=$(grep -E '^\s+profile' locals.tf); then
    while IFS= read -r line; do
        RAW_PROFILES+=("$(echo "$line" | sed 's/ //g' | sed 's/[\"\$\{\}]//g')")
    done <<< "$PARSED_PROFILES"
fi
# In some cases different IAM roles are needed in different accounts, so we store such correspondence in ACCS_IAM_ROLES
TF_PROFILES=()
declare -A ACCS_IAM_ROLES
for p in "${RAW_PROFILES[@]}"; do
    TMP_PROFILE=$(echo "$p" | sed 's/profile=//' | sed "s/var.profile/$PROFILE/" | sed "s/var.project/$PROJECT/")
    TF_PROFILES+=("$TMP_PROFILE")

    TMP_PROFILE=$(echo "$TMP_PROFILE" | cut -d '-' -f2-) # le-apps-devstg-devops -> apps-devstg-devops
    ROLE=$(echo "$TMP_PROFILE" | rev | cut -d '-' -f1 | rev) # apps-devstg-devops -> devops
    ACC=$(echo "$TMP_PROFILE" | rev | cut -d '-' -f2- | rev) # apps-devstg-devops -> apps-devstg
    ACCS_IAM_ROLES[$ACC]=$ROLE
done

set +u
if [[ ${#TF_PROFILES[@]} -eq 0 ]]; then
    error "Unable to locate relevant profiles in the layer definition."
    exit 30
fi
set -u

TF_PROFILES=( $(echo "${TF_PROFILES[@]}" | tr ' ' '\n' | sort | uniq) )
debug "${BOLD}Terraform${RESET} relevant profiles: ${TF_PROFILES[*]}"

# -----------------------------------------------------------------------------
# Get credentials for the layer
# -----------------------------------------------------------------------------
SSO_ACCESS_TOKEN=$(jq -r '.accessToken' "$SSO_CACHE_DIR/$SSO_ROLE_NAME") # Token obtained during login
ACCS_TO_GET_CREDENTIALS=( $(echo "${!ACCS_IAM_ROLES[@]}" | tr ' ' '\n' | sort) )
for ACCOUNT in "${ACCS_TO_GET_CREDENTIALS[@]}"; do
    info "Attempting to get temporary credentials for $BOLD$ACCOUNT$RESET account."

    SSO_ACC_PROFILE="$PROJECT-sso-$ACCOUNT-$SSO_ROLE_NAME"
    debug "Account AWS CLI SSO profile name: $BOLD$SSO_ACC_PROFILE$RESET"

    # If profile wasn't configured during configuration step it means we do not have permissions for the role in the account
    if ! ACCOUNT_ID=$(aws configure get account_id --profile "$SSO_ACC_PROFILE" 2>&1); then
        error "Missing $BOLD$SSO_ROLE_NAME$RESET permission for account $BOLD'$ACCOUNT'$RESET."
        exit 40
    fi
    debug "Account ID: $BOLD$ACCOUNT_ID$RESET"

    ACC_PROFILE="$PROJECT-$ACCOUNT-${ACCS_IAM_ROLES[$ACCOUNT]}"
    debug "AWS CLI profile: $BOLD$ACC_PROFILE$RESET"
    
    # Check if credentials need to be renewed
    if TOKEN_EXPIRATION=$(aws configure get expiration --profile "$ACC_PROFILE" 2>&1); then
        TOKEN_EXPIRATION=$(("$TOKEN_EXPIRATION" / 1000)) # Token expiration was in miliseconds
        debug "Token expiration time: $BOLD$TOKEN_EXPIRATION$RESET"

        CURRENT_TIME=$(date +"%s")
        RENEWAL_TIME=$(("$CURRENT_TIME" + (30 * 60)))
        debug "Token renewal time: $BOLD$RENEWAL_TIME$RESET"

        [[ $RENEWAL_TIME -lt $TOKEN_EXPIRATION ]] && info "Using already configured temporary credentials." && continue
    fi

    # Retrieve credentials 
    if ! PROFILE_CREDENTIALS=$(aws --output json sso get-role-credentials \
                                                        --role-name "$SSO_ROLE_NAME" \
                                                        --account-id "$ACCOUNT_ID" \
                                                        --access-token "$SSO_ACCESS_TOKEN"); then
        error "Unable to get valid credentials for role $BOLD$SSO_ROLE_NAME$RESET in account $BOLD$ACCOUNT$RESET.\nPlease check SSO configuration."
        exit 50
    fi

    # Write credentials
    AWS_ACCESS_KEY_ID=$(echo "$PROFILE_CREDENTIALS" | jq -r '.roleCredentials.accessKeyId') 
    AWS_SECRET_ACCESS_KEY=$(echo "$PROFILE_CREDENTIALS" | jq -r '.roleCredentials.secretAccessKey')
    AWS_SESSION_TOKEN=$(echo "$PROFILE_CREDENTIALS" | jq -r '.roleCredentials.sessionToken')
    debug "Access Key Id: ${AWS_ACCESS_KEY_ID:0:4}***************"
    debug "Secret Access Key: ${AWS_SECRET_ACCESS_KEY:0:4}***************"
    debug "Session Token: ${AWS_SESSION_TOKEN:0:4}***************"
    aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID" --profile "$ACC_PROFILE"
    aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY" --profile "$ACC_PROFILE"
    aws configure set aws_session_token "$AWS_SESSION_TOKEN" --profile "$ACC_PROFILE"
    aws configure set expiration "$(echo "$PROFILE_CREDENTIALS" | jq -r '.roleCredentials.expiration')" --profile "$ACC_PROFILE"

    info "Credentials for $BOLD$ACCOUNT$RESET account written successfully."
done

# Hand control back to main process
exec "$@"
