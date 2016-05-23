FROM alpine:3.3

ENTRYPOINT ["./verify.sh"]

RUN apk update && apk upgrade && apk --update add \
    libstdc++ tzdata bash curl

RUN apk add --no-cache python && \
    python -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip install --upgrade pip setuptools && \
    rm -r /root/.cache

ADD verify.sh verify.sh
RUN chmod a+x verify.sh
