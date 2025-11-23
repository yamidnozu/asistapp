#!/usr/bin/env bash
set -euo pipefail

# nginx_cleanup_letsencrypt.sh
# Idempotent helper to clean duplicate includes and ensure the Let's Encrypt
# snippet is included only once in a server block (safe to call multiple times).

SITE_CONF="/etc/nginx/sites-available/asistapp"
SNIPPET_PATH="/etc/nginx/snippets/letsencrypt-challenge.conf"

if [ "$EUID" -ne 0 ]; then
  echo "Run as root or with sudo" >&2
  exit 1
fi

if [ ! -f "$SNIPPET_PATH" ]; then
  echo "$SNIPPET_PATH not found; creating standard snippet and webroot"
  mkdir -p /var/www/letsencrypt/.well-known/acme-challenge
  chown -R www-data:www-data /var/www/letsencrypt
  chmod -R 755 /var/www/letsencrypt
  cat > "$SNIPPET_PATH" <<'EOF'
location /.well-known/acme-challenge/ {
    alias /var/www/letsencrypt/.well-known/acme-challenge/;
    try_files $uri =404;
}
EOF
fi

if [ -f "$SITE_CONF" ]; then
  # Remove duplicate include lines of this snippet
  sed -i 's/\s*include \/etc\/nginx\/snippets\/letsencrypt-challenge.conf;//g' "$SITE_CONF"

  # If file already contains explicit location for the ACME challenge, do not insert include
  if grep -q "location \/.well-known\/acme-challenge" "$SITE_CONF"; then
    echo "$SITE_CONF contains explicit location; not inserting include to avoid duplicates"
  else
    # Re-insert a single include after server_name line
    if ! grep -q "include /etc/nginx/snippets/letsencrypt-challenge.conf;" "$SITE_CONF"; then
      sed -i "/server_name /a \\    include /etc/nginx/snippets/letsencrypt-challenge.conf;" "$SITE_CONF"
      echo "Inserted include into $SITE_CONF"
    else
      echo "Include already present in $SITE_CONF"
    fi
  fi
else
  echo "$SITE_CONF not found; create your server block and include $SNIPPET_PATH"
fi

# Report any other files that define the same location block (to help the admin decide)
echo "Scanning /etc/nginx for other 'location /.well-known/acme-challenge' definitions (non-critical):"
grep -R "location \/.well-known\/acme-challenge" /etc/nginx -n || true

echo "Run 'nginx -t' and 'systemctl reload nginx' after verifying the configuration"
exit 0
