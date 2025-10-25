# AsistApp Backend

Backend para AsistApp usando Fastify, TypeScript y Prisma con PostgreSQL.

## 🚀 Inicio Rápido

### Instalación Local

1. Instalar dependencias:
   ```bash
   npm install
   ```

2. Copiar el archivo de ejemplo de variables de entorno:
   ```bash
   cp .env.example .env
   ```

3. Generar Prisma Client:
   ```bash
   npx prisma generate
   ```

4. Ejecutar migraciones:
   ```bash
   npx prisma migrate dev
   ```

5. Iniciar el servidor:
   ```bash
   npm run dev
   ```

El servidor estará disponible en:
- Local: http://localhost:3000
- Red local: http://192.168.20.22:3000

## 🌐 Acceso por Red Local

Para acceder al backend desde otros dispositivos en la misma red:

### 1. Configurar Firewall de Windows

Ejecuta el script como **Administrador**:
```bash
configure_firewall.bat
```

O manualmente en PowerShell:
```powershell
New-NetFirewallRule -DisplayName "AsistApp Backend" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow
```

### 2. Verificar Conectividad

Prueba desde otro dispositivo:
```bash
curl http://192.168.20.22:3000
```

O ejecuta el script de pruebas:
```bash
bash test_connection.sh
```

### 3. Configurar la App Flutter

La app ya está configurada para usar la IP `192.168.20.22`. Si tu IP cambia:
1. Abre `lib/services/auth_service.dart`
2. Actualiza la línea: `return '192.168.20.22';`

**Ver [NETWORK_ACCESS_GUIDE.md](../NETWORK_ACCESS_GUIDE.md) para más detalles.**

## 🐳 Docker Local

Para ejecutar con Docker:

```bash
docker-compose up --build
```

Esto iniciará PostgreSQL y la app en http://localhost:3000.

## 📡 Endpoints Principales

### Autenticación
- `POST /auth/login` - Iniciar sesión
- `POST /auth/refresh` - Renovar token
- `POST /auth/logout` - Cerrar sesión
- `GET /auth/instituciones` - Listar instituciones

### Usuarios
- `GET /usuarios` - Listar usuarios (requiere autenticación)
- Más endpoints disponibles...

### Prueba
- `GET /` - Hola Mundo (público)
- `GET /test` - Estructura de respuesta de ejemplo (público)

## 🔐 Credenciales de Prueba

El sistema crea automáticamente un usuario administrador:
- **Email**: `admin@asistapp.com`
- **Password**: `admin123`

⚠️ **IMPORTANTE**: Cambia estas credenciales en producción.

## 🛠️ Desarrollo

```bash
npm run dev          # Iniciar en modo desarrollo
npm run build        # Compilar TypeScript
npm run test         # Ejecutar tests
```

## 🚀 Despliegue en VPS

Ver [DEPLOY_VPS.md](DEPLOY_VPS.md) para instrucciones completas de despliegue en producción.

## 📋 Variables de Entorno

```bash
DATABASE_URL=postgresql://usuario:password@host:5432/database
JWT_SECRET=tu_secreto_seguro
JWT_EXPIRES_IN=24h
PORT=3000
HOST=0.0.0.0          # Importante para acceso por red
NODE_ENV=development
LOG_LEVEL=info
```

## 🔧 Características

- ✅ **CORS habilitado** - Acceso desde cualquier origen
- ✅ **Rate limiting** - Protección contra abuso
- ✅ **JWT Authentication** - Seguridad basada en tokens
- ✅ **Error handling** - Manejo centralizado de errores
- ✅ **TypeScript** - Tipado estático
- ✅ **Prisma ORM** - Base de datos type-safe
- ✅ **Fastify** - Framework rápido y eficiente