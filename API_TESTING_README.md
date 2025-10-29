# 🧪 AsistApp API Testing Suite

Archivo auxiliar para probar la API de administración de usuarios de AsistApp.

## 🚀 Uso Rápido

```bash
# Ejecutar todos los tests automatizados
node test-api.js

# Generar comandos cURL para pruebas manuales
node curl-generator.js

# O desde el directorio backend
cd backend && node ../test-api.js
cd backend && node ../curl-generator.js
```

## 📋 Prerrequisitos

1. **Servidor corriendo**: Asegúrate de que el backend esté ejecutándose en `http://localhost:3000`
2. **Base de datos**: Debe tener usuarios de prueba creados
3. **Node.js**: Versión 18 o superior
4. **jq (opcional)**: Para formatear respuestas JSON en comandos cURL
   ```bash
   # Ubuntu/Debian
   sudo apt-get install jq

   # macOS
   brew install jq

   # Windows (usando Chocolatey)
   choco install jq
   ```

## ⚙️ Configuración

Edita las constantes en `test-api.js`:

```javascript
const CONFIG = {
  BASE_URL: 'http://localhost:3000', // Cambiar según tu entorno
  API_PREFIX: '/api',

  TEST_USERS: {
    super_admin: {
      email: 'admin@asistapp.com',
      password: 'Admin123!'
    },
    admin_institucion: {
      email: 'admin@colegio.edu',
      password: 'Admin123!'
    },
    profesor: {
      email: 'profesor@colegio.edu',
      password: 'Profesor123!'
    }
  },

  TEST_DATA: {
    institucionId: 'uuid-institucion-real', // ⚠️ CAMBIAR por ID real
    grupoId: 'uuid-grupo-real', // ⚠️ CAMBIAR por ID real
  }
};
```

## 🧪 Tests Incluidos

### ✅ Autenticación
- Login de diferentes roles (super_admin, admin_institucion, profesor)
- Validación de tokens JWT

### ✅ Permisos y Autorización
- Acceso denegado sin token (401)
- Acceso denegado con rol incorrecto (403)
- Acceso permitido con rol correcto (200)

### ✅ CRUD Profesores (Admin Institución)
- **Crear**: POST con validaciones
- **Listar**: GET con paginación y filtros
- **Detalle**: GET individual
- **Actualizar**: PUT con campos opcionales
- **Toggle Status**: PATCH activar/desactivar
- **Eliminar**: DELETE (desactivación lógica)

### ✅ Validaciones
- Email único
- Campos requeridos
- Formatos válidos

### ✅ Paginación y Filtros
- Páginas y límites
- Búsqueda por texto
- Filtros por estado (activo/inactivo)

## 📊 Resultados

El script muestra un resumen detallado:

```
📊 RESUMEN DE TESTS
==================================================
Total de tests: 9
✅ Pasaron: 8
❌ Fallaron: 1
🔥 Errores: 0

❌ Tests que fallaron:
  - Crear profesor: Error al crear profesor: Institución no encontrada
```

## 🛠️ Comandos cURL Manuales

### Autenticación

```bash
# Login Super Admin
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@asistapp.com","password":"Admin123!"}'

# Login Admin Institución
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@colegio.edu","password":"Admin123!"}'
```

### Gestión de Profesores

```bash
# Obtener token primero
TOKEN="tu_token_aqui"

# Listar profesores (con paginación)
curl -X GET "http://localhost:3000/api/institution-admin/profesores?page=1&limit=10" \
  -H "Authorization: Bearer $TOKEN"

# Listar con filtros
curl -X GET "http://localhost:3000/api/institution-admin/profesores?page=1&limit=5&search=juan&activo=true" \
  -H "Authorization: Bearer $TOKEN"

# Crear profesor
curl -X POST http://localhost:3000/api/institution-admin/profesores \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "María",
    "apellido": "González",
    "email": "maria.gonzalez@test.com",
    "password": "Profesor123!",
    "telefono": "3001234567"
  }'

# Obtener detalle
curl -X GET http://localhost:3000/api/institution-admin/profesores/{id} \
  -H "Authorization: Bearer $TOKEN"

# Actualizar profesor
curl -X PUT http://localhost:3000/api/institution-admin/profesores/{id} \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "nombres": "María José",
    "telefono": "3009876543"
  }'

# Cambiar estado (activar/desactivar)
curl -X PATCH http://localhost:3000/api/institution-admin/profesores/{id}/toggle-status \
  -H "Authorization: Bearer $TOKEN"

# Eliminar profesor
curl -X DELETE http://localhost:3000/api/institution-admin/profesores/{id} \
  -H "Authorization: Bearer $TOKEN"
```

## 🔍 Depuración

### Ver respuestas detalladas

```javascript
// Agrega console.log en test-api.js
console.log('Response:', JSON.stringify(response, null, 2));
```

### Tests individuales

```javascript
// Ejecutar solo un test
await tester.runTest('Autenticación de usuarios', testAuthentication);
```

### Verificar endpoints manualmente

```bash
# Verificar que el servidor responde
curl http://localhost:3000/api/

# Verificar rutas disponibles
curl http://localhost:3000/api/institution-admin/profesores \
  -H "Authorization: Bearer TU_TOKEN"
```

## 🐛 Solución de Problemas

### ❌ "No se pudo autenticar ningún usuario"
- Verifica que los usuarios existen en la base de datos
- Revisa las credenciales en `CONFIG.TEST_USERS`
- Asegúrate de que el servidor esté corriendo

### ❌ "Institución no encontrada"
- Actualiza `CONFIG.TEST_DATA.institucionId` con un ID real de institución
- Verifica que la institución existe en la tabla `instituciones`

### ❌ "Grupo no encontrado"
- Actualiza `CONFIG.TEST_DATA.grupoId` con un ID real de grupo
- O elimina `grupoId` del test de creación

### ❌ Error 403 Forbidden
- Verifica que el usuario tenga el rol correcto (`admin_institucion`)
- Revisa que esté asignado a una institución

### ❌ Error de conexión
- Verifica que el servidor esté corriendo en el puerto correcto
- Cambia `BASE_URL` si es necesario

## 📝 Notas Importantes

1. **Datos de prueba**: El script crea y elimina automáticamente datos de prueba
2. **IDs dinámicos**: Los IDs de profesores se asignan automáticamente durante los tests
3. **Limpieza**: Los datos de prueba se eliminan al final (o puedes hacerlo manualmente)
4. **Seguridad**: No uses credenciales reales en el código

## 🎯 Próximos Tests

Cuando implementes estudiantes, agrega:

```javascript
// Tests para estudiantes
await tester.runTest('Crear estudiante', testCreateEstudiante);
await tester.runTest('Listar estudiantes', testListEstudiantes);
await tester.runTest('Generar QR estudiante', testGenerateQR);
```

## 📞 Soporte

Si encuentras errores, revisa:
1. Logs del servidor backend
2. Respuestas detalladas del script
3. Base de datos para verificar datos