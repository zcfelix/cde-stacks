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

CODEBASE_DIR=$CODEBASE

cd $CODEBASE_DIR

echo
echo "Run verify ..."
curl $ENTRYPOINT
echo "Run verify complete"
echo
