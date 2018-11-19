FROM alpine:3.8
ARG BUILD_DATE=now
ARG VCS_REF=local
ARG BUILD_VERSION=dev

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.version=$BUILD_VERSION \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/dol-leodagan/aria2-ariang.git" \
      org.label-schema.name="aria2-ariang" \
      org.label-schema.description="Web backend for downloading files and torrents through Aria2 with AriaNG UI" \
      org.label-schema.usage="https://github.com/dol-leodagan/aria2-ariang/blob/master/README.md" \
      org.label-schema.schema-version="1.0.0-rc1" \
      maintainer="Leodagan <leodagan@freyad.net>"

RUN set -ex; \
    apk update; \
    apk add --no-cache --update \
        aria2 nginx unzip libressl ca-certificates; \
    update-ca-certificates; \
    nslookup github.com; \
    aria2c "https://github.com/mayswind/AriaNg-DailyBuild/archive/master.zip" -d /;  \
#    aria2c "https://github.com/mayswind/AriaNg/releases/download/0.2.0/aria-ng-0.2.0.zip" -d /; \
    unzip /*.zip -d /aria-ng; \
    mv -n "$(dirname "$(find /aria-ng -name "index.html")")"/* /aria-ng; \
    rm -f /*.zip; \
    apk del unzip; \
    echo "pid /nginx.pid;" >> /etc/nginx/nginx.conf; \
    rm -rf /var/cache/* /tmp/* /var/log/* ~/.cache; \
    mkdir -p /var/log/nginx

COPY files/ /

WORKDIR /

VOLUME ["/data", "/conf"]

EXPOSE 80 443

CMD ["/entrypoint.sh"]
