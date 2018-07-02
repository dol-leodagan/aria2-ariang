FROM alpine:edge

ARG BUILD_DATE=now
ARG VCS_REF=local

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/dol-leodagan/aria2-ariang.git" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.schema-version="1.0.0-rc1" \
      maintainer="Leodagan <leodagan@freyad.net>"

RUN apk update && \
    apk add --no-cache --update \
        bash aria2 nginx unzip openssl && \
    aria2c "https://github.com/mayswind/AriaNg-DailyBuild/archive/master.zip" -d / && \
#    aria2c "https://github.com/mayswind/AriaNg/releases/download/0.2.0/aria-ng-0.2.0.zip" -d / && \
    unzip /*.zip -d /aria-ng && \
    mv -n "$(dirname "$(find /aria-ng -name "index.html")")"/* /aria-ng && \
    rm -f /*.zip && \
    apk del unzip && \
    echo "pid /nginx.pid;" >> /etc/nginx/nginx.conf && \
    rm -rf /var/cache/* /tmp/* /var/log/* ~/.cache && \
    mkdir -p /var/log/nginx

COPY files/ /

WORKDIR /

VOLUME ["/data", "/conf"]

EXPOSE 80 443

CMD ["/entrypoint.sh"]
