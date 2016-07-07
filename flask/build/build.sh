#!/bin/bash

CODEBASE_DIR=$CODEBASE

cd $CODEBASE_DIR

echo 'write Dockerfile'

(cat << EOF
FROM python:2.7

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
