#!/bin/bash

CODEBASE_DIR=$CODEBASE

cd $CODEBASE_DIR

echo 'write Dockerfile'

(cat << EOF
FROM hub.deepi.cn/synapse:0.1

RUN apk add --no-cache python && \
    python -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip install --upgrade pip setuptools && \
    rm -r /root/.cache


ENV APP_HOME /myapp
RUN mkdir \$APP_HOME
WORKDIR \$APP_HOME

ADD requirements.txt \$APP_HOME/requirements.txt
RUN pip install -r \$APP_HOME/requirements.txt
ADD . \$APP_HOME
CMD ["python", "main.py"]
EOF
) > Dockerfile

echo "Building image $IMAGE ..."
docker build -t $IMAGE . &>process.log
echo "Building image $IMAGE complete"
