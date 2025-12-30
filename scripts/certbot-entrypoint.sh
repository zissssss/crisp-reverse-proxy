#!/bin/sh

# Define paths
CERT_DIR="/etc/nginx/certs/live"
RELOAD_FLAG="$CERT_DIR/reload-flag"
LIVE_CERT_PATH="/etc/letsencrypt/live/$CLIENT_DOMAIN"

# Setup trap
exit_handler() {
  echo "[Certbot] Stopping..."
  exit 0
}
trap exit_handler SIGTERM SIGINT

echo "[Certbot] Waiting for Nginx to start..."
sleep 10

# Main loop
while true; do
    echo "[Certbot] Checking certificates..."

    # Check if we have valid certs
    if [ -d "$LIVE_CERT_PATH" ]; then
        echo "[Certbot] Certificates exist. Attempting renewal..."
        certbot renew --webroot -w /var/www/certbot
    else
        echo "[Certbot] No certificates found. Requesting initial certificates..."
        echo "[Certbot] Domains: $CLIENT_DOMAIN $IMAGE_DOMAIN $RELAY_DOMAIN $CLIENT_RELAY_DOMAIN $GAME_DOMAIN $GO_DOMAIN $MEDIA_DOMAIN"
        
        certbot certonly --webroot -w /var/www/certbot \
            --email $CERT_EMAIL --agree-tos --no-eff-email \
            --expand --non-interactive \
            -d $CLIENT_DOMAIN \
            -d $IMAGE_DOMAIN \
            -d $RELAY_DOMAIN \
            -d $CLIENT_RELAY_DOMAIN \
            -d $GAME_DOMAIN \
            -d $GO_DOMAIN \
            -d $MEDIA_DOMAIN
    fi

    # Post-process: Copy to shared volume if successful
    if [ -d "$LIVE_CERT_PATH" ]; then
        echo "[Certbot] Syncing certificates to Nginx volume..."
        cp -L "$LIVE_CERT_PATH/privkey.pem" "$CERT_DIR/privkey.pem"
        cp -L "$LIVE_CERT_PATH/fullchain.pem" "$CERT_DIR/fullchain.pem"
        
        # Signal Nginx to reload
        touch "$RELOAD_FLAG"
        echo "[Certbot] Signal sent to Nginx."
    else
        echo "[Certbot] Certificate request failed (or skipped). Will retry later."
    fi

    # Sleep for 12 hours before next check
    echo "[Certbot] Sleeping for 12 hours..."
    # Sleep in loop to be responsive to signals
    for i in $(seq 1 43200); do
        sleep 1
    done
done
