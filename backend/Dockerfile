FROM node:18

WORKDIR /app

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y libssl1.1 openssl ca-certificates && rm -rf /var/lib/apt/lists/*

# Copiar archivos de dependencias
COPY package*.json ./
RUN npm ci --only=production

# Copiar todos los archivos
COPY . .

# Generar cliente Prisma
RUN npx prisma generate

# Compilar TypeScript
RUN npm run build

EXPOSE 3000

CMD ["node", "dist/index.js"]