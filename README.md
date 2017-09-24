# leodagan/aria2-ariang
Standalone Alpine-based Docker Image that comes with *aria2*, *AriaNg* Web UI served by *nginx* reverse-proxying JSON-RPC with automated SSL Client Authentication.

The provided *docker-compose* file is meant for local building and testing.

## Resources
* https://github.com/aria2/aria2 (Doc: https://aria2.github.io/manual/en/html/index.html)
* https://github.com/mayswind/AriaNg (Latest Daily Build: http://ariang.mayswind.net/)
* https://github.com/nginx/nginx

### Optional for Let's Encrypt Support
* https://github.com/Neilpang/acme.sh
* https://github.com/Neilpang/nginx-proxy

## Environment Variables

```ARIA_ALLOW_UNSECURE {1|0}``` Default: 0, Remove HTTPS Redirect and Client Verify, useful for reverse-proxy.

```ARIANG_CLIENT_CERT_PASSWORD {passphrase_string}``` Customize Client Certificate Passphrase. (Recommended)

```ARIA_TORRENT_LISTEN_PORTS {port|ports-range}``` Default: 44100, Bittorrent Listening Port(s).

```ARIA_DHT_LISTEN_PORTS {port|ports-range}``` Default: 44110, Bittorent DHT Listening Port(s).

## Volumes

```/conf``` holds all configuration data and generated certificates.

```/data``` stores all downloaded files, incomplete files are stored in ```/data/pending```.

Generated Client Certificate will be stored as ```/conf/.ariang_nginx_tls_client.pfx```

## Default Configuration

The default aria2 configuration is optimized for 1Gbps Connections.

You can override them by adding your own settings in ```/conf/.aria2.conf```

```
continue=true
max-connection-per-server=5
http-accept-gzip=true
enable-http-pipelining=true
bt-detach-seed-only=true
bt-max-open-files=8192
bt-max-peers=750
bt-save-metadata=true
seed-ratio=0
file-allocation=falloc
on-download-complete=/on_download_complete.sh
on-bt-download-complete=/on_download_complete.sh
max-concurrent-downloads=500
bt-request-peer-speed-limit=80M
max-upload-limit=90M
max-overall-download-limit=90M
max-overall-upload-limit=90M
```

AriaNg default RPC-JSON parameters target ```wss://host:443```

## Standalone docker-compose example

This configuration is meant for Standalone settings with available *http/80* and *https/443* binds.

```
version: '2'
services:
  aria2-ariang:
    image: leodagan/aria2-ariang
    restart: always
    environment:
     ARIA_ALLOW_UNSECURE: 0
     ARIA_TORRENT_LISTEN_PORTS: 44120-44129
     ARIA_DHT_LISTEN_PORTS: 44130
     ARIANG_CLIENT_CERT_PASSWORD: SomethingThatShouldBeMoreSecure
    ports:
     - "80:80"
     - "443:443"
     - "44120-44129:44120-44129/tcp"
     - "44130:44130/tcp"
     - "44120-44129:44120-44129/udp"
     - "44130:44130/udp"
    volumes:
     - "./data:/data"
     - "./conf:/conf"
```

Create volume mappings using
```mkdir conf data```

## Reverse-Proxied docker-compose example

This configuration use the container as backend for a *nginx* Reverse-Proxy with Let's Encrypt Certificate Authority

Replace ```{Your Fully Qualified Domain Name here}``` with your registered domain name.

```
version: '2'
services:
  aria2-ariang:
    image: leodagan/aria2-ariang
    restart: always
    environment:
     ARIA_ALLOW_UNSECURE: 1
     ARIA_TORRENT_LISTEN_PORTS: 44120-44129
     ARIA_DHT_LISTEN_PORTS: 44130
     ARIANG_CLIENT_CERT_PASSWORD: SomethingThatShouldBeMoreSecure
     VIRTUAL_HOST: {Your Fully Qualified Domain Name here}
     ENABLE_ACME: "true"
    expose:
     - "80:80"
    ports
     - "44120-44129:44120-44129/tcp"
     - "44130:44130/tcp"
     - "44120-44129:44120-44129/udp"
     - "44130:44130/udp"
    volumes:
     - "./data:/data"
     - "./conf:/conf"

reverse-proxy:
    image: neilpang/nginx-proxy
    ports:
     - "80:80"
     - "443:443"
    restart: always
    volumes:
     - /var/run/docker.sock:/tmp/docker.sock:ro
     - ./vhost.d:/etc/nginx/vhost.d:ro
     - ./conf.d:/etc/nginx/conf.d
     - ./certs:/etc/nginx/certs
     - ./acme:/acmecerts
    network_mode: "host"
```

```mkdir vhost.d conf.d certs acme conf data``` to create needed volume directories.

To enable SSL Client Verify with generated Client Certificate add the following configuration in ```vhost.d/{Your Fully Qualified Domain Name}```

```
ssl_client_certificate /etc/nginx/certs/aria2-client.cert;
# only authorized client
ssl_verify_client on;
```

Then copy the generated server certificate to ```certs/aria2-client.cert```

```cp conf/.ariang_nginx_tls_server.crt certs/aria2-client.cert```

You will probably need to restart the *reverse-proxy* container...
