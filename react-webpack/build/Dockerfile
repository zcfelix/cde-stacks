FROM node

RUN apk add --no-cache --update git

ENTRYPOINT ["./build.sh"]


ENV DOCKER_BUCKET get.docker.com
ENV DOCKER_VERSION 1.9.1
RUN curl -sjkSL "https://${DOCKER_BUCKET}/builds/Linux/x86_64/docker-$DOCKER_VERSION" -o /usr/bin/docker \
	&& chmod +x /usr/bin/docker

ADD build.sh build.sh
ADD nginx.conf nginx.conf
RUN chmod +x build.sh
