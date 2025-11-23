#!/usr/bin/env bash
set -euo pipefail

# install_nginx_certbot.sh
# Simple installer that prepares nginx + certbot on Debian/Ubuntu VPS.
# Run as root or with sudo.

if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root (or with sudo)" >&2
  exit 1
fi

apt update && apt upgrade -y
apt install -y nginx certbot python3-certbot-nginx

systemctl enable --now nginx

# Prepare webroot and snippet for Let's Encrypt ACME challenges in a safe, idempotent way
WEBROOT="/var/www/letsencrypt"
SNIPPET_PATH="/etc/nginx/snippets/letsencrypt-challenge.conf"
SITE_CONF="/etc/nginx/sites-available/asistapp"

mkdir -p "$WEBROOT/.well-known/acme-challenge"
chown -R www-data:www-data "$WEBROOT"
chmod -R 755 "$WEBROOT"

  if [ ! -f "$SNIPPET_PATH" ]; then
  cat > "$SNIPPET_PATH" <<'EOF'
location /.well-known/acme-challenge/ {
    alias /var/www/letsencrypt/.well-known/acme-challenge/;
    try_files $uri =404;
}
EOF
  echo "Created $SNIPPET_PATH"
else
  echo "Snippet $SNIPPET_PATH already exists; skipping creation"
fi

# Add the include to the server block only if not already present. The server block file may be different
if [ -f "$SITE_CONF" ]; then
  if ! grep -q "include /etc/nginx/snippets/letsencrypt-challenge.conf;" "$SITE_CONF"; then
    # Only insert include if there is no explicit acme location in the file
    if ! grep -q "location \/.well-known\/acme-challenge" "$SITE_CONF"; then
      sed -i "/server_name /a \    include /etc/nginx/snippets/letsencrypt-challenge.conf;" "$SITE_CONF"
      echo "Inserted include into $SITE_CONF"
    else
      echo "$SITE_CONF already contains explicit acme location; skipping include insertion"
    fi
  else
    echo "Include already present in $SITE_CONF; skipping"
  fi
else
  echo "Warning: $SITE_CONF not found. Create your server block for the domain and include $SNIPPET_PATH to serve ACME requests."
fi

# Ensure that the site config listens on IPv6 too; add explicit listen [::]:80 if missing
if [ -f "$SITE_CONF" ]; then
  if ! grep -q "listen \[::\]:80" "$SITE_CONF"; then
    sed -i "/listen 80;/a \    listen [::]:80 default_server;" "$SITE_CONF" || true
    sed -i "s/listen 80;/listen 80 default_server;/" "$SITE_CONF" || true
    echo "Added IPv6 listen in $SITE_CONF"
  else
    echo "IPv6 listen already present in $SITE_CONF"
  fi
fi

echo "Nginx and Certbot installed. The script prepared a webroot and a snippet to serve ACME challenges."
echo "Next steps: create or verify your nginx server block for your domain, ensure it contains the include of $SNIPPET_PATH and restart nginx: nginx -t && systemctl reload nginx"
echo "When site is reachable via HTTP, run certbot --webroot -w $WEBROOT -d example.com -d www.example.com -m you@example.com --agree-tos --no-eff-email"

exit 0
