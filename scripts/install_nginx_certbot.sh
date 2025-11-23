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

echo "Nginx and Certbot installed. Next steps: create an nginx server block for your domain and run certbot --nginx to obtain a certificate."
echo "Example for domain 'mi-dominio.com':"
echo "1) Create /etc/nginx/sites-available/asistapp with proper proxy_pass to http://127.0.0.1:${PORT:-3002}"
echo "2) ln -s /etc/nginx/sites-available/asistapp /etc/nginx/sites-enabled/"
echo "3) nginx -t && systemctl reload nginx"
echo "4) certbot --nginx -d mi-dominio.com -d www.mi-dominio.com"

exit 0
