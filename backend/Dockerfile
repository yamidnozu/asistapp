# backend/Dockerfile

# 1. Etapa de construcción
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install --include=dev
COPY . .
# Compila el código de TypeScript a JavaScript
RUN npm run build

# 2. Etapa de producción
FROM node:18-alpine
WORKDIR /app
# Copia solo los archivos necesarios de la etapa anterior
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/dist/ ./dist/
COPY --from=builder /app/node_modules ./node_modules
# Copia el schema de Prisma para que esté disponible en producción
COPY --from=builder /app/prisma ./prisma

# Generar cliente Prisma en producción
RUN npx prisma generate

# Expone el puerto que usará el servidor
EXPOSE 3000

# Comando para iniciar el servidor
CMD [ "node", "dist/index.js" ]