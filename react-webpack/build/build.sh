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

on_exit() {
    last_status=$?
    if [ "$last_status" != "0" ]; then
        if [ -f "process.log" ]; then
          cat process.log|puts_red_f
        fi

        exit 1;
    else
        if [ -n "$MYSQL_CONTAINER" ]; then
            echo
            puts_step "Cleaning ..."
            puts_step "Cleaning complete"
            echo
        fi
        puts_green "build success"
        exit 0;
    fi
}

trap on_exit HUP INT TERM QUIT ABRT EXIT

CODEBASE_DIR=$CODEBASE

cd $CODEBASE_DIR

puts_step "Staring install depends ..."
npm install -g cnpm
cnpm install
if [ "$?" != "0" ]; then
  puts_red "install depends failed"
  exit 1
fi
npm install -g webpack
if [ "$?" != "0" ]; then
  puts_red "install webpack failed"
  exit 1
fi
puts_step "Install depends complete"

puts_step "Start packing ..."
export NODE_ENV=production
webpack
puts_step "Packing complete"

mkdir /dist
cp -rf dist/* /dist

cp /nginx.conf nginx.conf

cat > run.sh << EOF
#!/bin/sh
mkdir -p /etc/nginx/html
cp -rf /dist/* /etc/nginx/html
sed -i -e "s#{{API_PREFIX}}#\$API_PREFIX#g" /etc/nginx/html/bundle.js
exec "\$@"
EOF

cat > Dockerfile << EOF
FROM nginx
EXPOSE 80
ADD run.sh run.sh
ADD nginx.conf /etc/nginx/nginx.conf
RUN chmod +x run.sh
ADD /dist /dist
ENTRYPOINT ["./run.sh"]
CMD ["nginx", "-g", "daemon off;"]
EOF

puts_step "Start building app image ..."
docker build -t $IMAGE .
puts_step "Building image $IMAGE complete"
