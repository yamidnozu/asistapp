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
