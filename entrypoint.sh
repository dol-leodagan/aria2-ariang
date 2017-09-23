#!/usr/bin/env bash

### SSL Certificates
SERVER_CERT_FILE="/conf/.ariang_nginx_tls_server.crt"
SERVER_KEY_FILE="/conf/.ariang_nginx_tls_server.key"
CLIENT_PFX_FILE="/conf/.ariang_nginx_tls_client.pfx"

if [ ! -f "${SERVER_KEY_FILE}" ] || [ ! -f "${SERVER_CERT_FILE}" ] || [ ! -f "${CLIENT_PFX_FILE}" ]; then
    CLIENT_TMP_REQ_FILE="/tmp/.ariang_nginx_tls_client.req"
    CLIENT_TMP_KEY_FILE="/tmp/.ariang_nginx_tls_client.key"
    CLIENT_TMP_CERT_FILE="/tmp/.ariang_nginx_tls_client.crt"

    if ! (openssl req -x509 -days 3650 -subj '/C=WW/ST=World Wide/L=Terminal/CN=localhost' \
    -extensions SAN \
    -config <(cat /etc/ssl/openssl.cnf \
         <(printf "\n[SAN]\nsubjectAltName=DNS.1:localhost\nbasicConstraints=CA:true")) \
    -newkey rsa:2048 -keyout "${SERVER_KEY_FILE}" -out "${SERVER_CERT_FILE}" -nodes \
    && \
    openssl req -new -days 3650 -subj '/C=WW/ST=World Wide/L=Terminal/CN=ariang' \
    -out "${CLIENT_TMP_REQ_FILE}" -keyout "${CLIENT_TMP_KEY_FILE}" -nodes \
    && \
    openssl x509 -req -days 3650 \
    -CA "${SERVER_CERT_FILE}" -CAkey "${SERVER_KEY_FILE}" \
    -in "${CLIENT_TMP_REQ_FILE}" -out "${CLIENT_TMP_CERT_FILE}" -set_serial 01 \
    && \
    openssl pkcs12 -export -clcerts -in "${CLIENT_TMP_CERT_FILE}" -inkey "${CLIENT_TMP_KEY_FILE}" \
    -passout pass:"${ARIANG_CLIENT_CERT_PASSWORD:-ThisIsNoSecurePassword}" \
    -out "${CLIENT_PFX_FILE}" \
    && \
    rm -f "${CLIENT_TMP_REQ_FILE}" "${CLIENT_TMP_KEY_FILE}" "${CLIENT_TMP_CERT_FILE}"); then
        echo "Error while generating SSL certificates..."
	exit 1
    fi
fi

# Starting Nginx

if [ "${ARIA_ALLOW_UNSECURE}x" != "x" ] && [ "$ARIA_ALLOW_UNSECURE" -eq 1 ]; then
    if ! cp -f /default-unsecure.conf /etc/nginx/conf.d/default.conf; then
        echo "Error while copying Unsecure Nginx Configuration..."
	exit 1
    fi
fi

if ! nginx; then
    echo "Error while starting Nginx HTTP Server..."
    exit 1
fi

# Initializing Aria2 Session Files
if [ ! -f /conf/.aria2.conf ]; then
    if ! cp /root/.aria2/aria2.conf /conf/.aria2.conf; then
        echo "Error while copying aria2 configuration file..."
	exit 1
    fi
fi

if [ ! -f /conf/.aria2-session ]; then
    if ! touch /conf/.aria2-session; then
        echo "Error while initializing aria2 session file..."
	exit 1
    fi
fi

if [ ! -f /conf/.aria-dht.dat ]; then
    if ! touch /conf/.aria-dht.dat; then
        echo "Error while initializing aria2 DHT file..."
	exit 1
    fi
fi

if [ ! -f /conf/.aria-dht6.dat ]; then
    if ! touch /conf/.aria-dht6.dat; then
        echo "Error while initializing aria2 DHT6 file..."
	exit 1
    fi
fi

if ! sed -i -e 's/rpcPort:"6800",rpcInterface:"jsonrpc",protocol:"http"/rpcPort:"443",rpcInterface:"jsonrpc",protocol:"wss"/' /aria-ng/js/*; then
    echo "Error while setting AriaNg default RPC Config..."
    exit 1
fi

# Retrieving Aria2 Torrent / DHT Listen Ports

LISTEN_PORTS=${ARIA_TORRENT_LISTEN_PORTS:-44100}
DHT_LISTEN_PORTS=${ARIA_DHT_LISTEN_PORTS:-44110}

echo "Listening on Ports ${LISTEN_PORTS}, DHT ${DHT_LISTEN_PORTS}"

export ARIA2_DOWNLOAD_DIR="/data/pending"

aria2c --enable-rpc --listen-port="${LISTEN_PORTS}" --dht-listen-port="${DHT_LISTEN_PORTS}" \
       --save-session /conf/.aria2-session --input-file /conf/.aria2-session --force-save --save-session-interval=60 \
       -d "$ARIA2_DOWNLOAD_DIR" --netrc-path=/conf/.netrc --dht-file-path=/conf/.aria-dht.dat --dht-file-path6=/conf/.aria-dht6.dat \
       --conf-path=/conf/.aria2.conf --log-level=info
