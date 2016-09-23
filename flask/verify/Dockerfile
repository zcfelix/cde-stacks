FROM alpine:3.3

ENTRYPOINT ["verify.sh"]

RUN apk update && apk upgrade && apk --update add \
    libstdc++ tzdata bash curl jq

RUN apk add --no-cache python && \
    python -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip install --upgrade pip setuptools && \
    rm -r /root/.cache

RUN curl -sjkSL "https://github.com/tw-cde/cde-client-binary/releases/download/0.1.4/lambda" -o /bin/lambda

COPY rootfs /

RUN chmod -R +x /bin/
