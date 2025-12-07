# backend/Dockerfile

# 1. Etapa de construcción
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install --include=dev
COPY . .
# Genera el cliente Prisma con los tipos
RUN npx prisma generate
# Compila el código de TypeScript a JavaScript
RUN npm run build
# Compila el archivo seed.ts a JavaScript
RUN npx tsc prisma/seed.ts --outDir dist --module commonjs --target es2020 --esModuleInterop --skipLibCheck

# 2. Etapa de producción
FROM node:18-alpine
WORKDIR /app
# Copia solo los archivos necesarios de la etapa anterior
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/dist/ ./dist/
COPY --from=builder /app/node_modules ./node_modules
# Copia el schema de Prisma para que esté disponible en producción
COPY --from=builder /app/prisma ./prisma
# Copia el archivo seed compilado
COPY --from=builder /app/dist/seed.js ./dist/seed.js

# Copia el script de inicialización
COPY init.sh ./init.sh
RUN sed -i 's/\r$//' init.sh || true
RUN chmod +x init.sh

# Generar cliente Prisma en producción
RUN npx prisma generate

# Expone el puerto que usará el servidor
EXPOSE 3000

# Comando para iniciar el servidor con inicialización
ENTRYPOINT ["./init.sh"]
CMD ["node", "dist/index.js"]