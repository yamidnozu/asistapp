# HTTPS setup (nginx + certbot)

This file outlines a simple, reproducible setup to serve your `asistapp` backend via HTTPS using `nginx` as reverse proxy and `certbot` (Let's Encrypt) for certificates.

Prerequisites
- You must own a domain and point an A record to your VPS IP (e.g., 31.220.104.130)
- Docker and docker-compose already installed and your app listens on a private port (we bind to 127.0.0.1:3002)

Steps
1. Install nginx and certbot (script included):

```bash
sudo /opt/asistapp/scripts/install_nginx_certbot.sh
```

2. Create nginx config (example: `/etc/nginx/sites-available/asistapp`):

```nginx
server {
  listen 80;
  server_name mi-dominio.com www.mi-dominio.com;

  location / {
    proxy_pass http://127.0.0.1:3002;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}
```

3. Enable the site and test nginx:

```bash
sudo ln -s /etc/nginx/sites-available/asistapp /etc/nginx/sites-enabled/asistapp
sudo nginx -t && sudo systemctl reload nginx
```

4. Get certificates with certbot:

```bash
sudo certbot --nginx -d mi-dominio.com -d www.mi-dominio.com
```

5. (Optional) Force HTTPS redirection when prompted by certbot or add an nginx rule to redirect from http to https.

6. Confirm your app is reachable via HTTPS (e.g. `curl -I https://mi-dominio.com`).

Notes
- The `docker-compose.prod.yml` maps the backend to `127.0.0.1:${PORT}`, so only local requests from nginx will reach it.
- Make sure your `API_BASE_URL` secret uses `https://mi-dominio.com`.
- Ensure the app trusts the proxy if it uses `req.protocol`: in Express use `app.set('trust proxy', true)`.

Troubleshooting: Duplicate snippet / 404 on ACME challenge
------------------------------------------------------

If Certbot reports that the CA cannot download the challenge files (404), or if `nginx -t` reports `duplicate location` errors, run these checks:

- Search for duplicated includes/locations:
```bash
sudo grep -R "letsencrypt-challenge.conf" /etc/nginx -n || true
sudo grep -R "location \/.well-known\/acme-challenge" /etc/nginx -n || true
```

- If you accidentally inserted the include multiple times (e.g. via `sed`), remove duplicates from your site file and reinsert only once:
```bash
sudo sed -i '/include \/etc\/nginx\/snippets\/letsencrypt-challenge.conf;/d' /etc/nginx/sites-available/asistapp
sudo sed -i "/server_name /a \\    include /etc/nginx/snippets/letsencrypt-challenge.conf;" /etc/nginx/sites-available/asistapp
```

- If another configuration file contains a `location /.well-known/acme-challenge` block, either remove/disable it or ensure it does not clash with the snippet. Use the grep from above to locate and edit.

- After cleaning the config, test and reload nginx:
```bash
sudo nginx -t && sudo systemctl reload nginx
```

- Create a temporary challenge test file and confirm it’s served:
```bash
sudo mkdir -p /var/www/letsencrypt/.well-known/acme-challenge
echo "ok" | sudo tee /var/www/letsencrypt/.well-known/acme-challenge/test.txt
sudo chown -R www-data:www-data /var/www/letsencrypt
curl -I -H "Host: mi-dominio.com" http://127.0.0.1/.well-known/acme-challenge/test.txt
curl -I http://mi-dominio.com/.well-known/acme-challenge/test.txt
```

- If the public request fails but the localhost test with Host header works, check your DNS and firewall (IPv4 and IPv6). If the domain resolves to an IPv6, allow HTTP/HTTPS via ip6tables/ufw.

If these steps resolve, retry certbot. Consider running certbot with `--webroot` if you prefer to avoid the nginx plugin:
```bash
sudo certbot certonly --webroot -w /var/www/letsencrypt -d mi-dominio.com -d www.mi-dominio.com -m you@example.com --agree-tos --non-interactive --no-eff-email
```
