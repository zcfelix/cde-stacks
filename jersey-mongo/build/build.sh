#!/bin/bash

# builder 在调用 stack 的 build image 时会传入如下一些环境变量
# APP_NAME:  应用的名称
# CODEBASE:  应用代码的目录
# CACHE_DIR: build image 可以使用这个目录来缓存build过程中的文件,比如maven的jar包,用来加速整个build流程
# IMAGE:     build 成功之后image的名称

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
    result=0
    if [ "$last_status" != "0" ]; then
        if [ -f "process.log" ]; then
          cat process.log
        fi
        result=1
    else
        result=0
    fi

    if [ -n "$MONGODB_CONTAINER" ]; then
            echo
            echo "Cleaning ..."
            echo > process.log
            docker stop $MONGODB_CONTAINER 2>&1 &>process.log
            docker rm $MONGODB_CONTAINER  2>&1 &>process.log
            echo "Cleaning complete"
            echo
    fi
    exit $result
}

trap on_exit HUP INT TERM QUIT ABRT EXIT

# 在将 java 打包为 jar 之前首先执行项目的单元测试，那么在执行测试之前需要安装单元测试所依赖的数据

HOST_IP=$(ip route|awk '/default/ { print $3 }')

echo
export MONGODB_MONGODB_USER=admin
export MONGODB_MONGODB_PASS=mongo
export MONGODB_MONGODB_DATABASE=testdb
puts_step "Launching baking services ..."
MONGODB_CONTAINER=$(docker run -d -P -e MONGODB_USER=$MONGODB_MONGODB_USER -e MONGODB_PASS=$MONGODB_MONGODB_PASS -e MONGODB_DATABASE=$MONGODB_MONGODB_DATABASE tutum/mongodb)
MONGODB_PORT=$(docker inspect -f '{{(index (index .NetworkSettings.Ports "27017/tcp") 0).HostPort}}' ${MONGODB_CONTAINER})
until docker exec $MONGODB_CONTAINER mongo $MONGODB_MONGODB_DATABASE --host 127.0.0.1 --port 27017 -u $MONGODB_MONGODB_USER -p $MONGODB_MONGODB_PASS --eval "ls()" &>/dev/null ; do
    echo "...."
    sleep 1
done

export MONGODB_HOST=$HOST_IP
export MONGODB_PORT=$MONGODB_PORT
puts_step "Complete Launching baking services"
echo

cd $CODEBASE

echo
echo "Start test ..."
echo > process.log
GRADLE_USER_HOME="$CACHE_DIR" gradle clean test -i &> process.log
echo "Test complete"
echo

echo "Start generate standalone ..."
echo > process.log
GRADLE_USER_HOME="$CACHE_DIR" gradle standaloneJar &>process.log
echo "Generate standalone Complete"

(cat  <<'EOF'
#!/bin/bash
set -eo pipefail

until nc -z -w 5 $MONGODB_HOST $MONGODB_PORT; do
    echo "...."
    sleep 1
done

java -Xmx450m -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -jar app-standalone.jar
EOF
) > wrapper.sh

(cat << EOF
FROM hub.deepi.cn/jre-8.66:0.1

CMD ["./wrapper.sh"]

ADD build/libs/app-standalone.jar app-standalone.jar

ADD wrapper.sh wrapper.sh
RUN chmod +x wrapper.sh
ENV APP_NAME \$APP_NAME
EOF
) > Dockerfile

echo
echo "Building image $IMAGE ..."
echo > process.log
docker build -t $IMAGE . 2>&1 &>process.log
echo "Building image $IMAGE complete "
echo
