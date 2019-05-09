#!/bin/bash
## brief: wrapper script which calls trigger-travis
## If the branch name of the upstream and downstream project are equal and
## we have a valid travis configuration in the downstream project then
## try to trigger a travis build with the given github/travis user and
## the given github/travis access token and log a certain message in the
## travis downstream project build for tracing back the dependent builds

# arguments
USER=$1
DOWNSTREAM_REPO=$2
BRANCH=$3
TRAVIS_ACCESS_TOKEN=$4
MESSAGE=$5

# trigger build if above conditions hold
     if [ $# -eq 5 ] ; then
         MESSAGE=",\"message\": \"$5\""
     elif [ -n "$TRAVIS_REPO_SLUG" ] ; then
         MESSAGE=",\"message\": \"Triggered from upstream build of $TRAVIS_REPO_SLUG by commit "`git rev-parse --short HEAD`"\""
     fi
     # for debugging
     echo "USER=$USER"
     echo "REPO=$DOWNSTREAM_REPO"
     echo "BRANCH=$BRANCH"
     echo "MESSAGE=$MESSAGE"

     # curl POST request content body
     BODY="{
       \"request\": {
       \"branch\":\"$BRANCH\"
       $MESSAGE
     }}"
     # make a POST request with curl (note %2F could be replaced with
     # / and additional curl arguments, however this works too!)
     curl -s -X POST \
       -H "Content-Type: application/json" \
       -H "Accept: application/json" \
       -H "Travis-API-Version: 3" \
       -H "Authorization: token ${TRAVIS_ACCESS_TOKEN}" \
       -d "$BODY" \
       "https://api.travis-ci.com/repo/${USER}%2F${DOWNSTREAM_REPO}/requests" \
       | tee /tmp/travis-request-output.$$.txt

     if grep -q '"@type": "error"' /tmp/travis-request-output.$$.txt; then
        cat /tmp/travis-request-output.$$.txt
        exit 1
     elif grep -q 'access denied' /tmp/travis-request-output.$$.txt; then
        cat /tmp/travis-request-output.$$.txt
        exit 1
     fi


# usage function
function usage {
   echo "$(basename $0): USER DOWNSTREAM_REPOSITORY BRANCH TRAVIS_ACCESS_TOKEN"
}
