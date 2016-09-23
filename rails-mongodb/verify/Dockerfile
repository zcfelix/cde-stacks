FROM ruby:2.3

ENTRYPOINT ["verify.sh"]

RUN curl -jksSL https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -o /usr/local/bin/jq && \
    chmod +x /usr/local/bin/jq

RUN curl -sjkSL "https://github.com/tw-cde/cde-client-binary/releases/download/0.1.4/lambda" -o /bin/lambda

COPY rootfs /

RUN chmod -R +x /bin/