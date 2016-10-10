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

CODEBASE_DIR=$CODEBASE

export MONGO_MONGODB_USER=admin
export MONGO_MONGODB_PASS=mongo
export MONGO_MONGODB_DATABASE=testdb

echo
puts_step "Launching baking services ..."
MONGO_CONTAINER=$(docker run -d -P -e MONGODB_PASS=$MONGO_MONGODB_PASS -e MONGODB_USER=$MONGO_MONGODB_USER -e MONGODB_DATABASE=$MONGO_MONGODB_DATABASE tutum/mongodb)
MONGO_PORT=$(docker inspect -f '{{(index (index .NetworkSettings.Ports "27017/tcp") 0).HostPort}}' ${MONGO_CONTAINER})
until docker exec $MONGO_CONTAINER mongo $MONGO_MONGODB_DATABASE --host 127.0.0.1 --port 27017 -u $MONGO_MONGODB_USER -p $MONGO_MONGODB_PASS --eval "ls()" &>/dev/null ; do
    echo "...."
    sleep 1
done

export MONGO_HOST=$HOST
export MONGO_PORT=$MONGO_PORT

puts_step "Complete Launching baking services"
echo

cd $CODEBASE_DIR

echo
puts_step "Install dependencies ..."
gem install -N nokogiri -- --use-system-libraries
# cleanup and settings
bundle config --global build.nokogiri  "--use-system-libraries" && \
bundle config --global build.nokogumbo "--use-system-libraries" && \
  find / -type f -iname \*.apk-new -delete && \
  rm -rf /var/cache/apk/* && \
  rm -rf /usr/lib/lib/ruby/gems/*/cache/* && \
  rm -rf ~/.gem
bundle install --without development production
echo

echo
puts_step "Start test ..."
bundle exec rspec
puts_step "Test complete"
echo

(cat << EOF
FROM ruby:2.3-onbuild

ADD . /app

RUN cd /app && bundle install --without development test

ENV RAILS_ENV production
WORKDIR /app

CMD ["bundle", "exec", "unicorn", "-p", "8088", "-c", "./config/unicorn.rb"]

EOF
) > Dockerfile

echo
puts_step "Building image $IMAGE ..."
docker build -q -t $IMAGE . &>process.log
puts_step "Building image $IMAGE complete "
echo
