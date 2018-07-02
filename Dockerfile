FROM alpine:edge

MAINTAINER Leodagan <leodagan@freyad.net>

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
