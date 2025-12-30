#!/bin/sh

# Define config paths
CERT_DIR="/etc/nginx/certs/live"
PRIVKEY="$CERT_DIR/privkey.pem"
FULLCHAIN="$CERT_DIR/fullchain.pem"
RELOAD_FLAG="$CERT_DIR/reload-flag"

mkdir -p "$CERT_DIR"

# 1. Check/Generate Dummy Certs
if [ ! -f "$PRIVKEY" ] || [ ! -f "$FULLCHAIN" ]; then
    echo "[Nginx] Certificates missing. Generating self-signed placeholder..."
    apk add --no-cache openssl
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$PRIVKEY" -out "$FULLCHAIN" \
        -subj "/C=CN/ST=State/L=City/O=Organization/CN=localhost"
    echo "[Nginx] Placeholder certificates generated."
fi

# 2. Process Templates (Manually run envsubst since we overrode entrypoint)
# We strictly filter which variables to replace so we don't break $host $remote_addr etc.
echo "[Nginx] Generating configuration..."
export DOLLAR='$'
envsubst '${CLIENT_DOMAIN} ${IMAGE_DOMAIN} ${RELAY_DOMAIN} ${CLIENT_RELAY_DOMAIN} ${GAME_DOMAIN} ${GO_DOMAIN} ${MEDIA_DOMAIN}' < /etc/nginx/templates/crisp.conf.template > /etc/nginx/conf.d/crisp.conf
# Remove default config to prevent "localhost" server block from catching requests
rm -f /etc/nginx/conf.d/default.conf

# 3. Start Nginx in background
echo "[Nginx] Starting Nginx..."
nginx -g "daemon off;" &
NGINX_PID=$!

# 3. Monitor for reload signal (run by Certbot container)
while kill -0 $NGINX_PID; do
    if [ -f "$RELOAD_FLAG" ]; then
        echo "[Nginx] Reload flag detected. Reloading configuration..."
        nginx -s reload
        rm -f "$RELOAD_FLAG"
        echo "[Nginx] Reloaded."
    fi
    sleep 5
done
