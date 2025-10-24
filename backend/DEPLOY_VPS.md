# Guía de Despliegue en VPS Hostinguer

## Requisitos Previos
- VPS con Ubuntu (recomendado 20.04+)
- Acceso SSH
- Dominio apuntando a la IP de la VPS

## Paso 1: Conectar a la VPS
```bash
ssh usuario@tu-ip-vps
```

## Paso 2: Actualizar el Sistema
```bash
sudo apt update && sudo apt upgrade -y
```

## Paso 3: Instalar Docker y Docker Compose
```bash
# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Reiniciar sesión para aplicar grupo docker
logout
ssh usuario@tu-ip-vps
```

## Paso 4: Instalar Git y clonar el proyecto
```bash
sudo apt install git -y
git clone https://github.com/tu-usuario/asistapp.git
cd asistapp/backend
```

## Paso 5: Configurar Variables de Entorno
```bash
cp .env.example .env  # Si tienes example
# Editar .env con credenciales de producción
nano .env
```

Asegúrate de que DATABASE_URL use credenciales seguras.

## Paso 6: Ejecutar la Aplicación
```bash
docker-compose up -d --build
```

## Paso 7: Instalar Nginx
```bash
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
```

## Paso 8: Configurar Nginx como Reverse Proxy
Crear archivo de configuración:
```bash
sudo nano /etc/nginx/sites-available/asistapp
```

Contenido:
```
server {
    listen 80;
    server_name tu-dominio.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Habilitar sitio:
```bash
sudo ln -s /etc/nginx/sites-available/asistapp /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## Paso 9: Configurar SSL con Let's Encrypt
```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d tu-dominio.com
```

## Paso 10: Configurar Firewall
```bash
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw --force enable
```

## Paso 11: Probar
Visita `https://tu-dominio.com` y deberías ver "Hola Mundo desde AsistApp Backend!"

## Comandos Útiles
```bash
# Ver logs
docker-compose logs -f

# Reiniciar servicios
docker-compose restart

# Actualizar
git pull
docker-compose up -d --build
```

## Notas de Seguridad
- Cambia las contraseñas por defecto
- Usa variables de entorno para secrets
- Mantén el sistema actualizado
- Configura backups de la base de datos