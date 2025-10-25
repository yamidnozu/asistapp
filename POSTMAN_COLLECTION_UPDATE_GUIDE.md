# Guía de Actualización - Colección Postman AsistApp

**Fecha:** 24 de octubre de 2025

## 📋 Cambios Realizados

### 1. Rutas de Usuarios Corregidas

Todas las rutas de la sección "Users Management" han sido actualizadas para reflejar las correcciones del backend:

#### Antes (Causaban NOT_FOUND_ERROR):
```
GET {{protocol}}://{{host}}:{{port}}/usuarios/usuarios
GET {{protocol}}://{{host}}:{{port}}/usuarios/usuarios/:id
GET {{protocol}}://{{host}}:{{port}}/usuarios/usuarios/rol/:role
GET {{protocol}}://{{host}}:{{port}}/usuarios/usuarios/institucion/:institucionId
```

#### Después (Funcionan Correctamente):
```
GET {{protocol}}://{{host}}:{{port}}/usuarios
GET {{protocol}}://{{host}}:{{port}}/usuarios/:id
GET {{protocol}}://{{host}}:{{port}}/usuarios/rol/:role
GET {{protocol}}://{{host}}:{{port}}/usuarios/institucion/:institucionId
POST {{protocol}}://{{host}}:{{port}}/usuarios/admin/cleanup-tokens
```

### 2. Credenciales Actualizadas

#### Environment Variables (Asistapp.postman_environment.json)

**Antes:**
```json
{
  "adminUser": "superadmin@asistapp.com",
  "adminPassword": "Admin123!"
}
```

**Después:**
```json
{
  "adminUser": "admin@asistapp.com",
  "adminPassword": "pollo",
  "testStudentEmail": "student@test.com",
  "testStudentPassword": "studentpass"
}
```

### 3. Descripción de la Colección Mejorada

Se agregó información sobre:
- Credenciales por defecto
- Instrucciones de uso
- Lista de rutas corregidas

### 4. Nombres de Endpoints Clarificados

**Antes:**
- "Login - Super Admin"
- "Login Test - Sin Rate Limit"

**Después:**
- "Login - Super Admin (admin@asistapp.com)"
- "Login Test - Sin Rate Limit (admin@asistapp.com)"

Esto hace más claro qué credenciales usar en cada endpoint.

## 🧪 Cómo Probar la Colección Actualizada

### Paso 1: Importar Archivos

1. Abre Postman
2. Importa `Asistapp.postman_collection.json`
3. Importa `Asistapp.postman_environment.json`

### Paso 2: Configurar Environment

1. Selecciona "AsistApp Environment" en el dropdown de environments
2. Verifica las variables:
   - `protocol`: `http`
   - `host`: `localhost`
   - `port`: `3000`
   - `adminUser`: `admin@asistapp.com`
   - `adminPassword`: `pollo`

### Paso 3: Asegurarse de que el Backend Esté Corriendo

```bash
cd backend
npm run dev
```

Deberías ver:
```
✅ Servidor corriendo en http://localhost:3000
```

### Paso 4: Ejecutar Tests

#### 4.1 Health Check
1. Abre "Health Check" → "API Health Check"
2. Clic en "Send"
3. Deberías ver: `200 OK` con `success: true`

#### 4.2 Login
1. Abre "Authentication" → "Login - Super Admin (admin@asistapp.com)"
2. Clic en "Send"
3. Verifica:
   - Status: `200 OK`
   - Response contiene `accessToken` y `refreshToken`
   - Variables de entorno se actualizan automáticamente

#### 4.3 Obtener Usuarios
1. Abre "Users Management" → "Get All Users"
2. Clic en "Send"
3. Verifica:
   - Status: `200 OK` ✅ (antes era 404)
   - Response contiene array de usuarios

#### 4.4 Obtener Usuario por ID
1. Verifica que `userId` esté definido en las variables de entorno
2. Abre "Users Management" → "Get User by ID"
3. Clic en "Send"
4. Verifica:
   - Status: `200 OK` ✅ (antes era 404)
   - Response contiene el usuario

#### 4.5 Obtener Usuarios por Rol
1. Abre "Users Management" → "Get Users by Role"
2. La variable `role` por defecto es "estudiante"
3. Clic en "Send"
4. Verifica:
   - Status: `200 OK` ✅ (antes era 404)
   - Response contiene array de usuarios con ese rol

#### 4.6 Obtener Usuarios por Institución
1. Primero ejecuta "Authentication" → "Get User Institutions" para obtener una institución
2. La variable `institucionId` se guardará automáticamente
3. Abre "Users Management" → "Get Users by Institution"
4. Clic en "Send"
5. Verifica:
   - Status: `200 OK` ✅ (antes era 404)
   - Response contiene array de usuarios de esa institución

#### 4.7 Limpiar Tokens Expirados (Super Admin)
1. Abre "Users Management" → "Cleanup Tokens"
2. Clic en "Send"
3. Verifica:
   - Status: `200 OK` ✅ (antes era 404)
   - Response: `{ success: true, data: { message: "..." } }`

### Paso 5: Tests Automáticos

Cada endpoint incluye tests automáticos en JavaScript que verifican:

✅ **Status Code Correcto**
```javascript
pm.test("Respuesta del servidor", function () {
    pm.response.to.have.status(200);
});
```

✅ **Estructura de Respuesta**
```javascript
pm.test("Usuarios obtenidos", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property('success');
    pm.expect(jsonData.data).to.be.an('array');
});
```

✅ **Actualización Automática de Variables**
```javascript
if (jsonData.success && jsonData.data) {
    pm.environment.set('accessToken', jsonData.data.accessToken);
    pm.environment.set('userId', jsonData.data.usuario.id);
}
```

## 📊 Resultados Esperados

### Antes de las Correcciones
```
❌ GET /usuarios → 404 NOT_FOUND_ERROR
❌ GET /usuarios/:id → 404 NOT_FOUND_ERROR
❌ GET /usuarios/rol/:role → 404 NOT_FOUND_ERROR
❌ GET /usuarios/institucion/:institucionId → 404 NOT_FOUND_ERROR
```

### Después de las Correcciones
```
✅ GET /usuarios → 200 OK
✅ GET /usuarios/:id → 200 OK
✅ GET /usuarios/rol/:role → 200 OK
✅ GET /usuarios/institucion/:institucionId → 200 OK
✅ POST /usuarios/admin/cleanup-tokens → 200 OK
```

## 🔍 Troubleshooting

### Error: "Ruta no encontrada"

**Problema:** Todavía obtienes 404 NOT_FOUND_ERROR

**Solución:**
1. Verifica que el backend esté actualizado con las correcciones
2. Reinicia el servidor backend:
   ```bash
   cd backend
   # Ctrl+C para detener
   npm run dev
   ```
3. Verifica que las rutas en Postman no tengan `/usuarios/usuarios`

### Error: "Token inválido"

**Problema:** 401 AUTHENTICATION_ERROR

**Solución:**
1. Ejecuta "Login - Super Admin" de nuevo
2. Verifica que la variable `accessToken` se haya guardado
3. Los tokens expiran en 24 horas

### Error: "Permisos insuficientes"

**Problema:** 403 AUTHORIZATION_ERROR

**Solución:**
1. Algunos endpoints requieren rol `super_admin` o `admin_institucion`
2. Verifica que estés usando el token correcto
3. El usuario debe tener los permisos necesarios

## 📚 Recursos Adicionales

- **Resumen de correcciones:** `BACKEND_FIXES_SUMMARY.md`
- **README de Postman:** `POSTMAN_README.md`
- **Tests de integración:** `backend/tests/user.integration.test.ts`
- **Código de rutas:** `backend/src/routes/user.routes.ts`

## ✅ Checklist de Verificación

Marca cada item después de verificarlo:

- [ ] Backend corriendo en http://localhost:3000
- [ ] Health Check funciona (200 OK)
- [ ] Login funciona y guarda token
- [ ] GET /usuarios funciona (200 OK)
- [ ] GET /usuarios/:id funciona (200 OK)
- [ ] GET /usuarios/rol/:role funciona (200 OK)
- [ ] GET /usuarios/institucion/:institucionId funciona (200 OK)
- [ ] POST /usuarios/admin/cleanup-tokens funciona (200 OK)
- [ ] Tests automáticos pasan en todos los endpoints
- [ ] Variables de entorno se actualizan correctamente

## 🎉 ¡Listo!

Tu colección de Postman ahora está completamente actualizada y todas las rutas de usuarios funcionan correctamente.

---

**Última actualización:** 24 de octubre de 2025
**Versión de la colección:** 2.0
**Compatibilidad:** AsistApp Backend v2.0
