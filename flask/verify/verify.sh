#!/bin/bash

set -eo pipefail

on_exit() {
    last_status=$?
    if [ "$last_status" != "0" ]; then
        if [ -f "process.log" ]; then
          cat process.log
        fi

        exit 1;
    else
        echo "Cleaning ..."
        echo "Cleaning complete"
        exit 0;
    fi
}

trap on_exit HUP INT TERM QUIT ABRT EXIT

export ENTRYPOINT=http://$ENDPOINT

cd $CODEBASE

ENDPOINT_HOST=$(echo $LAMBDA|jq --raw-output '.services.main.endpoint.internal.host')
ENDPOINT_PORT=$(echo $LAMBDA|jq --raw-output '.services.main.endpoint.internal.port')

echo
echo "Run verify ..."
curl http://${ENDPOINT_HOST}:${ENDPOINT_PORT}
echo "Run verify complete"
echo
