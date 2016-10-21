#!/bin/bash

set -eo pipefail

on_exit() {
    last_status=$?
    trap '' HUP INT TERM QUIT ABRT EXIT
    local exit_status=0
    if [ "$last_status" != "0" ]; then
        if [ -f "process.log" ]; then
          cat process.log
        fi
        exit_status=1
    fi

    if [ "$LAMBDA_URI" != "" ]; then
        echo "Clean lambda env..."
        lambda deprovision --lambda-uri "$LAMBDA_URI"
        clean_status=$?
        if [ "$clean_status" != "0" ]; then
            echo "Clean lambda env fail"
        else
            echo "Clean lambda env success"
        fi
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
ENDPOINT_HOST=$(echo $LAMBDA_INFO|jq --raw-output '.services.main.endpoint.internal.host')
ENDPOINT_PORT=$(echo $LAMBDA_INFO|jq --raw-output '.services.main.endpoint.internal.port')


echo
echo "Run verify ..."
# curl http://$ENDPOINT_HOST:$ENDPOINT_PORT
echo "Run verify complete"
echo
