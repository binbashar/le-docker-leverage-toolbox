#!/usr/bin/env bash

FULLVERSIONREGEX='([0-9\.]+)-([0-9\.]+)'
SEMVERREGEX='[^0-9]*\([0-9]*\)[.]\([0-9]*\)[.]\([0-9]*\)\([0-9A-Za-z-]*\)'
NEWTERRAVER="1.2.1"
if [ ! -z $1 ];
then
    NEWTERRAVER=$1
fi
BASECLIVER="0.0.1"
CHANGELEVEL="patch"
if [ ! -z $2 ];
then
    CHANGELEVEL=$2
fi
CURRENTVER=$((T=$(git describe --tags --abbrev=0 2> /dev/null) && echo "$T") || echo "")

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
