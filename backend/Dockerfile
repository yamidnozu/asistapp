FROM node:18

WORKDIR /app

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y openssl ca-certificates && rm -rf /var/lib/apt/lists/*

# Copiar archivos de dependencias
COPY package*.json ./
RUN npm ci

# Copiar todos los archivos
COPY . .

# Generar cliente Prisma
RUN npx prisma generate

# Compilar TypeScript
RUN npm run build

EXPOSE 3000

CMD ["node", "dist/index.js"]