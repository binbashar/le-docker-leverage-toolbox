#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# - In a nutshell, what the script does is:
# -----------------------------------------------------------------------------
#   1. Figure out all the AWS profiles used by Terraform
#   2. For each profile:
#       2.1. Get the role, MFA serial number, and source profile
#       2.2. Figure out the OTP or prompt the user
#       2.3. Assume the role to create temporary credentials
#       2.4. Generate the AWS profiles config files
#   3. Pass the control back to the main process (e.g. Terraform)
# -----------------------------------------------------------------------------

set -o errexit
set -o pipefail
set -o nounset


# ---------------------------
# Formatting helpers
# ---------------------------
BOLD="\033[1m"
DATE="\033[0;90m"
ERROR="\033[41;37m"
INFO="\033[0;34m"
DEBUG="\033[0;32m"
RESET="\033[0m"

# ---------------------------
# Helper Functions
# ---------------------------

# Simple logging functions
function error { log "${ERROR}ERROR${RESET}\t$1" 0; }
function info { log "${INFO}INFO${RESET}\t$1" 1; }
function debug { log "${DEBUG}DEBUG${RESET}\t$1" 2; }
function log {
    if [[ $MFA_SCRIPT_LOG_LEVEL -gt "$2" ]]; then
        echo -e "${DATE}[$(date +"%H:%M:%S")]${RESET}   $1"
    fi
}

# ---------------------------
# Set right access to ssh
# ---------------------------
if [[ -d /tmp/.ssh ]];
then
    log "Setting .ssh permissions..." 1
    cp -r /tmp/.ssh ~/.ssh
    chown $(id -u):$(id -g) -R ~/.ssh
    chmod 600 ~/.ssh
fi

# -----------------------------------------------------------------------------
# Pass the control back to the main process
# -----------------------------------------------------------------------------
exec "$@"
