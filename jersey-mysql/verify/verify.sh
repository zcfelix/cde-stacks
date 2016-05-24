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
        exit 0;
    fi
}

trap on_exit HUP INT TERM QUIT ABRT EXIT

cd $CODEBASE

echo
echo "Building verify jar..."
GRADLE_USER_HOME="$CACHE_DIR" gradle itestJar &>process.log
echo "Build verify finished"
echo

echo
echo "Start verify"
ENTRYPOINT=http://$ENDPOINT java -jar build/libs/verify-standalone.jar
echo "Verify finished"
echo
