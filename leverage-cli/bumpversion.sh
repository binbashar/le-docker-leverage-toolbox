#!/usr/bin/env bash

ACTION='retrieve'
if [ ! -z $1 ];
then
    ACTION=$1
fi
FULLVERSIONREGEX='([0-9\.]+)-([0-9\.]+)'
SEMVERREGEX='[^0-9]*\([0-9]*\)[.]\([0-9]*\)[.]\([0-9]*\)\([0-9A-Za-z-]*\)'
NEWTERRAVER="1.2.1"
if [ ! -z $2 ];
then
    NEWTERRAVER=$2
fi
BASECLIVER="0.0.1"
CHANGELEVEL="patch"
if [ ! -z $3 ];
then
    CHANGELEVEL=$3
fi

print_help() {
    echo "Usage:"
    echo "$0 [retrieve|bump]"
    echo "(default: retrieve)"
    echo ""
    echo "If bump:"
    echo "$0 bump [terraform_version [patch_level]]"
    echo ""
    echo "$0 bump 1.1.1 minor"
}

CURRENTVER=$((T=$(git describe --tags --abbrev=0 2> /dev/null) && echo "$T") || echo "")

if [ "$ACTION" = "retrieve" ] || [ "$ACTION" = "ret" ];
then
    echo $CURRENTVER;
elif [ "$ACTION" = "bump" ] || [ "$ACTION" = "bu" ];
then
    if [ -z $CURRENTVER ];
    then
        echo "${NEWTERRAVER}-${BASECLIVER}";
    else
    (
        CURRENTTERRAVER=$(echo $CURRENTVER | sed -E "s#$FULLVERSIONREGEX#\1#") && \
        CURRENTCLIVER=$(echo $CURRENTVER | sed -E "s#$FULLVERSIONREGEX#\2#") && \
        if [ $CURRENTTERRAVER = $NEWTERRAVER ];\
        then \
            MAJOR=$(echo $CURRENTCLIVER | sed -e "s#$SEMVERREGEX#\1#") && \
            MINOR=$(echo $CURRENTCLIVER | sed -e "s#$SEMVERREGEX#\2#") && \
            PATCH=$(echo $CURRENTCLIVER | sed -e "s#$SEMVERREGEX#\3#") && \
            if [[ "$CHANGELEVEL" = "patch" ]]; \
            then \
                PATCH=$((PATCH + 1)); \
            elif [[ "$CHANGELEVEL" = "minor" ]]; \
            then \
                MINOR=$((MINOR + 1)); \
            elif [[ "$CHANGELEVEL" = "major" ]]; \
            then \
                MAJOR=$((MAJOR + 1)); \
            fi && \
            echo "${NEWTERRAVER}-${MAJOR}.${MINOR}.${PATCH}"; \
        else \
            echo "${NEWTERRAVER}-${BASECLIVER}"; \
        fi \
    )
    fi
else
    echo "Unkown action $ACTION" >&2
    print_help
    exit 1
fi
