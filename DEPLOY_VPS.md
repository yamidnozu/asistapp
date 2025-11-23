# Setup inicial en VPS
# Ejecutar estos comandos en tu VPS (con Docker instalado)

# 1. Clonar el repositorio
git clone https://github.com/TU_USUARIO/TU_REPO.git /path/to/project

# 2. Ir al directorio
cd /path/to/project

# 3. Copiar .env (crea uno con las variables de producción)
cp backend/.env.example backend/.env
# Edita backend/.env con tus valores de producción

# 4. Ejecutar docker-compose
docker-compose up -d

# Para logs
docker-compose logs -f app