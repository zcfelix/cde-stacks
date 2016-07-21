FROM hub.deepi.cn/gradle:0.1

RUN apk --update add gcc jq

ENTRYPOINT ["./verify.sh"]

WORKDIR /home
ADD verify.sh verify.sh
RUN chmod a+x verify.sh
