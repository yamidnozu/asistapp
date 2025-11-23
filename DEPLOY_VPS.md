# Setup inicial en VPS
# Ejecutar estos comandos en tu VPS (con Docker instalado)

# 1. Instalar Docker si no está (en Ubuntu/Debian):
# sudo apt update && sudo apt install docker.io docker-compose

# 2. Clonar el repositorio
git clone https://github.com/TU_USUARIO/TU_REPO.git /path/to/project

# 3. Ir al directorio
cd /path/to/project

# 4. Login a GitHub Container Registry (opcional, si necesitas pull manual)
# echo $GITHUB_TOKEN | docker login ghcr.io -u TU_USUARIO --password-stdin

# 5. Copiar .env (crea uno con las variables de producción)
cp backend/.env.example backend/.env
# Edita backend/.env con tus valores de producción

# 6. Ejecutar docker-compose (la imagen se descargará automáticamente desde GitHub)
docker-compose up -d

# Para logs
docker-compose logs -f app