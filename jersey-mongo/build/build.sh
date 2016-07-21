#!/bin/bash

# builder 在调用 stack 的 build image 时会传入如下一些环境变量
# APP_NAME:  应用的名称
# CODEBASE:  应用代码的目录
# CACHE_DIR: build image 可以使用这个目录来缓存build过程中的文件,比如maven的jar包,用来加速整个build流程
# IMAGE:     build 成功之后image的名称

set -eo pipefail

on_exit() {
    last_status=$?
    if [ "$last_status" != "0" ]; then
        if [ -f "process.log" ]; then
          cat process.log
        fi

        if [ -n "$MYSQL_CONTAINER" ]; then
            echo
            echo "Cleaning ..."
            docker stop $MYSQL_CONTAINER &>process.log && docker rm $MYSQL_CONTAINER &>process.log
            echo "Cleaning complete"
            echo
        fi
        exit 1;
    else
        if [ -n "$MYSQL_CONTAINER" ]; then
            echo
            echo "Cleaning ..."
            docker stop $MYSQL_CONTAINER &>process.log && docker rm $MYSQL_CONTAINER &>process.log
            echo "Cleaning complete"
            echo
        fi
        exit 0;
    fi
}

trap on_exit HUP INT TERM QUIT ABRT EXIT

# 在将 java 打包为 jar 之前首先执行项目的单元测试，那么在执行测试之前需要安装单元测试所依赖的数据

HOST_IP=$(ip route|awk '/default/ { print $3 }')

echo
puts_step "Launching baking services ..."
MONGODB_CONTAINER=$(docker run -d -P -e MONGODB_PASS=$MONGODB_PASS -e MONGODB_USER=$MONGODB_USER -e MONGODB_DATABASE=$MONGODB_DATABASE tutum/mongodb)
MONGODB_PORT=$(docker inspect -f '{{(index (index .NetworkSettings.Ports "27017/tcp") 0).HostPort}}' ${MONGODB_CONTAINER})
until docker exec $MONGODB_CONTAINER mongo $MONGO_NAME --host 127.0.0.1 --port $MONGODB_PORT -u $MONGODB_USER -p $MONGODB_PASS --eval "ls()" &>/dev/null ; do
    echo "...."
    sleep 1
done

export MONGODB_HOST=$HOST_IP
export MONGODB_PORT=$MONGODB_PORT
echo "Complete Launching baking services"
echo

cd $CODEBASE

echo
echo "Start test ..."
GRADLE_USER_HOME="$CACHE_DIR" gradle clean test -i &> process.log
echo "Test complete"
echo

echo "Start generate standalone ..."
GRADLE_USER_HOME="$CACHE_DIR" gradle standaloneJar &>process.log
echo "Generate standalone Complete"

(cat  <<'EOF'
#!/bin/bash
set -eo pipefail

until nc -z -w 5 $MONGODB_HOST $MONGODB_PORT; do
    echo "...."
    sleep 1
done

java -jar app-standalone.jar
EOF
) > wrapper.sh

(cat << EOF
FROM hub.deepi.cn/jre-8.66:0.1

CMD ["./wrapper.sh"]

ADD build/libs/app-standalone.jar app-standalone.jar

ADD wrapper.sh wrapper.sh
RUN chmod +x wrapper.sh
ENV APP_NAME \$APP_NAME

ADD src/main/resources/db/migration dbmigration
COPY src/main/resources/db/init initmigration

EOF
) > Dockerfile

echo
echo "Building image $IMAGE ..."
docker build -q -t $IMAGE . &>process.log
echo "Building image $IMAGE complete "
echo
