#!/bin/bash

set -eo pipefail

puts_red() {
    echo $'\033[0;31m'"      $@" $'\033[0m'
}

puts_red_f() {
  while read data; do
    echo $'\033[0;31m'"      $data" $'\033[0m'
  done
}

puts_green() {
  echo $'\033[0;32m'"      $@" $'\033[0m'
}

puts_step() {
  echo $'\033[0;34m'" -----> $@" $'\033[0m'
}

on_exit() {
    last_status=$?
    if [ "$last_status" != "0" ]; then
        if [ -f "process.log" ]; then
          cat process.log|puts_red_f
        fi

        if [ -n "$MONGO_CONTAINER" ]; then
            echo
            puts_step "Cleaning ..."
            docker stop $MONGO_CONTAINER &>process.log && docker rm $MONGO_CONTAINER &>process.log
            puts_step "Cleaning complete"
            echo
        fi
        exit 1;
    else
        if [ -n "$MONGO_CONTAINER" ]; then
            echo
            puts_step "Cleaning ..."
            docker stop $MONGO_CONTAINER &>process.log && docker rm $MONGO_CONTAINER &>process.log
            puts_step "Cleaning complete"
            echo
        fi
        exit 0;
    fi
}

trap on_exit HUP INT TERM QUIT ABRT EXIT

cd $CODEBASE
ENDPOINT_HOST=$(echo $LAMBDA|jq --raw-output '.services.web.endpoint.internal.host')
ENDPOINT_PORT=$(echo $LAMBDA|jq --raw-output '.services.web.endpoint.internal.port')
export ENDPOINT="http://$ENDPOINT_HOST:$ENDPOINT_PORT" GRADLE_USER_HOME="$CACHE_DIR" gradle itest

bundle install

echo
puts_step "Run verify ..."
# bundle exec rake itest
# cd features && bundle exec rspec spec --require ./custom_formatter.rb --format CustomFormatter --format documentation
puts_step "Run verify complete"
echo
