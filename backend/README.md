# AsistApp Backend

Backend para AsistApp usando Fastify, TypeScript y Prisma con PostgreSQL.

## Instalación Local

1. Instalar dependencias:
   ```bash
   npm install
   ```

2. Configurar la base de datos en `.env` (ya configurado para Docker).

3. Generar Prisma Client:
   ```bash
   npx prisma generate
   ```

4. Ejecutar migraciones:
   ```bash
   npx prisma migrate dev
   ```

## Docker Local

Para ejecutar con Docker:

```bash
docker-compose up --build
```

Esto iniciará PostgreSQL y la app en http://localhost:3000.

## Despliegue en VPS

Ver [DEPLOY_VPS.md](DEPLOY_VPS.md) para instrucciones completas de despliegue en producción.

## Endpoints

- `GET /` - Hola Mundo
- `GET /users` - Lista de usuarios

## Desarrollo

```bash
npm run dev
```