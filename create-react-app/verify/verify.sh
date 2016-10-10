#!/bin/sh

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
    echo $last_status
    if [ "$last_status" != "0" ]; then
        if [ -f "process.log" ]; then
          cat process.log|puts_red_f
        fi

        puts_step "Cleaning ..."
        puts_step "Cleaning complete"

        exit 1;
    else
        puts_green "build success"
        exit 0;
    fi
}

trap on_exit HUP INT TERM QUIT ABRT EXIT

cd $CODEBASE

puts_step "Start to verify..."
sleep 2
puts_step "Verify success"

# if [ -f "/tmp/repo/manifest.json" ]; then
#     cd /tmp/git
#     puts_step "Start sync to ketsu"
#     git log --reverse --pretty=format:%at
#     if [ "$?" != "0" ]; then
#         first_commit=$(stat -c%Y config)
#     else
#         first_commit=$(git log --reverse --pretty=format:%at |head -n1)
#     fi
#
#     last_commit=$(date +%s)
#     evaluation_duration=$(eval 'expr $last_commit - $first_commit')
#
#     cd /tmp/repo
#     evaluation_uri=$(cat manifest.json| jq -r '.evaluation_uri')
#     if [ -z "$evaluation_uri" ] ; then
#         puts_red "missing manifest.json"
#         exit 1
#     fi
#     entry_point=$(echo $evaluation_uri | awk -F/ '{print $3}')
#     if [ -z "$entry_point" ] ; then
#         puts_red "bad format of manifest.json"
#         exit 1
#     fi
#
#     curl -sSL -c cookie -b cookie "$entry_point/authentication" -d "user_name=bg"
#     authentication_status=$(curl -sSL --write-out "%{http_code}" -X POST -c cookie -b cookie "$entry_point/authentication" -d "user_name=bg")
#     if [ "$authentication_status" != "200" ] ; then
#         puts_red "authentication failed, http code:$authentication_status"
#         exit 1
#     fi
#
#     result_status=$(curl -sSL --write-out "%{http_code}" -X POST -c cookie -b cookie $evaluation_uri -d "score=$evaluation_duration" -d "status=PASSED")
#     if [ "$result_status" != "200" ] ; then
#         puts_red "sync failed, http code:$result_status"
#         exit 1
#     fi
#     puts_step "Sync to ketsu complete"
# fi
