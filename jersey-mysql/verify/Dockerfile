FROM hub.deepi.cn/gradle:0.1

ENTRYPOINT ["./verify.sh"]

WORKDIR /home
ADD verify.sh verify.sh
RUN chmod a+x verify.sh
