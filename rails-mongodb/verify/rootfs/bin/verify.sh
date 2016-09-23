#!/bin/bash

set -eo pipefail

on_exit() {
    last_status=$?
    trap '' HUP INT TERM QUIT ABRT EXIT
    local exit_status
    if [ "$last_status" != "0" ]; then
        if [ -f "process.log" ]; then
          cat process.log
        fi
        exit_status=1
    fi

    if [ "$LAMBDA_URI" != "" ]; then
        lambda deprovision --lambda-uri "$LAMBDA_URI"
    fi

    trap - HUP INT TERM QUIT ABRT EXIT
    exit ${exit_status}
}

trap on_exit HUP INT TERM QUIT ABRT EXIT

echo "Launch lambda env..."
LAMBDA_URI=$(lambda provision --build-uri "$BUILD_URI")
echo "Launch lambda success"
cd $CODEBASE
LAMBDA_INFO=$(lambda info --lambda-uri $LAMBDA_URI)
ENDPOINT_HOST=$(echo $LAMBDA_INFO|jq --raw-output '.services.web.endpoint.internal.host')
ENDPOINT_PORT=$(echo $LAMBDA_INFO|jq --raw-output '.services.web.endpoint.internal.port')

export ENDPOINT="http://$ENDPOINT_HOST:$ENDPOINT_PORT"

bundle install

echo
puts_step "Run verify ..."
bundle exec rake itest
# cd features && bundle exec rspec spec --require ./custom_formatter.rb --format CustomFormatter --format documentation
puts_step "Run verify complete"
echo
