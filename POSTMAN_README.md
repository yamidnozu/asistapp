# AsistApp API v2.0 - Colección Postman

Esta colección contiene todas las pruebas necesarias para la API de AsistApp Backend v2.0 con autenticación JWT, refresh tokens y rate limiting.

## ⚠️ IMPORTANTE - Correcciones Recientes

**Fecha:** 24 de octubre de 2025

Las rutas de usuarios han sido **corregidas** y ahora funcionan correctamente. El problema era que las rutas tenían el prefijo duplicado.

### Rutas Corregidas:
- ✅ `GET /usuarios` - Lista todos los usuarios
- ✅ `GET /usuarios/:id` - Obtiene usuario por ID
- ✅ `GET /usuarios/rol/:role` - Filtra usuarios por rol
- ✅ `GET /usuarios/institucion/:institucionId` - Filtra usuarios por institución
- ✅ `POST /usuarios/admin/cleanup-tokens` - Limpia tokens expirados

Ver `BACKEND_FIXES_SUMMARY.md` para más detalles.

## 🚀 Inicio Rápido

1. **Importar la colección**: Importa `Asistapp.postman_collection.json` en Postman
2. **Importar el environment**: Importa `Asistapp.postman_environment.json` en Postman
3. **Seleccionar environment**: Elige "AsistApp Environment" en el dropdown de environments
4. **Configurar variables** (opcional, ya vienen pre-configuradas):
   - `baseUrl`: `http://localhost:3000` (ya configurado)
   - `protocol`: `http`
   - `host`: `localhost`
   - `port`: `3000`
   - `accessToken`: Se establece automáticamente al hacer login
   - `userId`: ID de usuario para pruebas específicas
   - `role`: Rol para filtrar usuarios (default: "estudiante")
   - `adminUser`/`adminPassword`: Credenciales de admin
   - `testUser`/`testPassword`: Credenciales de usuario de prueba

## � Variables de Environment

La colección incluye un archivo de environment (`Asistapp.postman_environment.json`) con las siguientes variables configurables:

### Variables de Conexión
- **`baseUrl`**: URL completa de la API (construida automáticamente)
- **`protocol`**: Protocolo HTTP/HTTPS (default: `http`)
- **`host`**: Host del servidor (default: `localhost`)
- **`port`**: Puerto del servidor (default: `3000`)

### Variables de Autenticación
- **`accessToken`**: Token JWT (se actualiza automáticamente en login)
- **`refreshToken`**: Token de refresh (opcional, manejado por cookies)

### Variables de Prueba
- **`userId`**: ID de usuario para endpoints específicos
- **`institucionId`**: ID de institución para filtrado
- **`role`**: Rol para filtrar usuarios (default: `estudiante`)
- **`currentUserEmail`**: Email del usuario autenticado
- **`currentUserRole`**: Rol del usuario autenticado

### Credenciales Pre-configuradas
- **`adminUser`**: `admin@asistapp.com`
- **`adminPassword`**: `pollo`
- **`testStudentEmail`**: `student@test.com` (se crea en los tests)
- **`testStudentPassword`**: `studentpass` (se crea en los tests)

## 🌍 Configuración de Entornos

Puedes crear diferentes environments para probar en varios entornos:

### Desarrollo (ya configurado)
```json
{
  "protocol": "http",
  "host": "localhost",
  "port": "3000"
}
```

### Staging
```json
{
  "protocol": "https",
  "host": "api-staging.asistapp.com",
  "port": ""
}
```

### Producción
```json
{
  "protocol": "https",
  "host": "api.asistapp.com",
  "port": ""
}
```

## � Endpoints Disponibles

### Health Check
- **GET** `/` - Verificar estado de la API

### Authentication
- **POST** `/login` - Iniciar sesión
- **GET** `/verify` - Verificar token de acceso
- **POST** `/refresh` - Refrescar access token
- **POST** `/logout` - Cerrar sesión

### Users Management
- **GET** `/usuarios` - Obtener todos los usuarios (admin only)
- **GET** `/usuarios/:id` - Obtener usuario por ID
- **GET** `/usuarios/rol/:role` - Filtrar usuarios por rol
- **GET** `/usuarios/institucion/:institucionId` - Filtrar por institución
- **POST** `/admin/cleanup-tokens` - Limpiar tokens expirados (super_admin only)

## 👥 Usuarios de Prueba

### Credenciales Disponibles

| Rol | Email | Password | Descripción |
|-----|-------|----------|-------------|
| super_admin | admin@asistapp.com | pollo | Administrador global (creado automáticamente) |

**Nota:** Para crear más usuarios de prueba, ejecuta el seed del backend:

```bash
cd backend
npm run prisma:seed
```

O ejecuta los tests de integración que crean usuarios temporales:

```bash
cd backend
npm test
```
| estudiante | carlos.lópez@sanjose.edu | Est123! | Estudiante Carlos López |
| estudiante | laura.martínez@sanjose.edu | Est123! | Estudiante Laura Martínez |
| estudiante | miguel.rodríguez@sanjose.edu | Est123! | Estudiante Miguel Rodríguez |

## 🔐 Autenticación

### Flujo de Autenticación
1. **Login**: Envía email/password → Recibe accessToken + refreshToken (cookie)
2. **Usar API**: Incluye `Authorization: Bearer {{accessToken}}` en headers
3. **Refresh**: POST a `/refresh` (usa cookie automáticamente) → Nuevo accessToken
4. **Logout**: POST a `/logout` → Invalida refresh token

### Rate Limiting
- **Login**: 5 intentos por 15 minutos
- **Refresh**: 10 intentos por 15 minutos
- **Global**: 100 requests por 15 minutos

## 🧪 Casos de Prueba

### Flujo Completo de Autenticación
1. Login como Super Admin
2. Verificar token
3. Obtener lista de usuarios
4. Refrescar token
5. Logout

### Pruebas de Rate Limiting
- Intentar login múltiples veces con credenciales incorrectas

### Pruebas de Autorización
- Acceder a endpoints sin token
- Acceder con token inválido
- Acceder con permisos insuficientes

## 📝 Notas Importantes

- Los refresh tokens se manejan automáticamente via cookies HttpOnly
- Los access tokens expiran en 24 horas
- Los refresh tokens expiran en 7 días
- La API incluye validación de `tokenVersion` para revocación inmediata
- Todos los endpoints protegidos requieren autenticación JWT

## 🔧 Configuración Adicional

Para usar la colección correctamente:

1. **Importar ambos archivos**:
   - `Asistapp.postman_collection.json`
   - `Asistapp.postman_environment.json`

2. **Seleccionar el environment** "AsistApp Environment" en Postman

3. **Asegúrate de que el backend esté corriendo** en la URL configurada

4. **Ejecuta el seed** de la base de datos para crear los usuarios de prueba:
   ```bash
   cd backend
   npm run seed
   ```

5. **Las variables se actualizan automáticamente** en cada login exitoso

## 📚 Documentación API

La API incluye respuestas estructuradas con el formato:
```json
{
  "success": true,
  "data": { ... },
  "message": "Operación exitosa"
}
```

Para errores:
```json
{
  "success": false,
  "error": "Mensaje de error"
}
```