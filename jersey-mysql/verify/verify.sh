#!/bin/bash

# builder 在调用 stack 的 verify image 时会传入如下一些环境变量
# APP_NAME:  应用的名称
# CODEBASE:  应用代码的目录
# CACHE_DIR: build image 可以使用这个目录来缓存build过程中的文件,比如maven的jar包,用来加速整个build流程
# ENDPOINT:  在执行 verify 之前，builder 会采用已经在 build 过程中构建的 docker image 创建一个临时的
#            lambda 环境，用于测试，ENDPOINT 就是这个 lambda 环境的入口，包含了 IP 和端口

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
