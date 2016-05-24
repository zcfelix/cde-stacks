#!/bin/bash

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

HOST_IP=$(ip route|awk '/default/ { print $3 }')

export DB_USERNAME=mysql
export DB_PASSWORD=mysql
export DB_NAME=testdb

echo
echo "Launching baking services ..."
MYSQL_CONTAINER=$(docker run -d -P -e MYSQL_USER=$DB_USERNAME -e MYSQL_PASS=$DB_PASSWORD -e ON_CREATE_DB=$DB_NAME -e MYSQL_ROOT_PASSWORD=$DB_PASSWORD tutum/mysql)
MYSQL_PORT=$(docker inspect -f '{{(index (index .NetworkSettings.Ports "3306/tcp") 0).HostPort}}' ${MYSQL_CONTAINER})
until docker exec $MYSQL_CONTAINER mysql -h127.0.0.1 -P3306 -umysql -pmysql -e "select 1" &>/dev/null ; do
    echo "...."
    sleep 1
done

export DB_HOST=$HOST_IP
export DB_PORT=$MYSQL_PORT

echo "Complete Launching baking services"
echo

cd $CODEBASE

echo
echo "Start migratioin ..."
GRADLE_USER_HOME="$CACHE_DIR" gradle fC fM &> process.log
echo "Migration complete"
echo

echo
echo "Start test ..."
GRADLE_USER_HOME="$CACHE_DIR" gradle clean test -i &> process.log
echo "Test complete"
echo

echo "Start generate standalone ..."
GRADLE_USER_HOME="$CACHE_DIR" gradle standaloneJar &>process.log
echo "Generate standalone Complete"

(cat  <<'EOF'
#!/bin/sh

export DATABASE="jdbc:mysql://127.0.0.1:$DB_PORT/$DB_NAME?user=$DB_USERNAME&password=$DB_PASSWORD&allowMultiQueries=true&zeroDateTimeBehavior=convertToNull&createDatabaseIfNotExist=true"
flyway migrate -url="$DATABASE" -locations=filesystem:`pwd`/dbmigration -baselineOnMigrate=true -baselineVersion=0
[ -d `pwd`/initmigration  ] && flyway migrate -url="$DATABASE" -locations=filesystem:`pwd`/initmigration -table="init_version" -baselineOnMigrate=true -baselineVersion=0
java -jar app-standalone.jar
EOF
) > wrapper.sh

(cat << EOF
FROM hub.deepi.cn/jre-8.66:0.1

CMD ["./wrapper.sh"]

RUN apk --update add tar
RUN mkdir /usr/local/bin/flyway && \
    curl -jksSL https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/4.0/flyway-commandline-4.0.tar.gz \
    | tar -xzf - -C /usr/local/bin/flyway --strip-components=1
ENV PATH /usr/local/bin/flyway/:\$PATH

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
