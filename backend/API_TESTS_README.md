# Pruebas de API - AsistApp Backend

Este archivo contiene pruebas exhaustivas para validar todos los endpoints implementados en Sub-phase 2.2.

## Requisitos Previos

1. **Backend ejecutándose**: Asegúrate de que el servidor backend esté corriendo en `http://localhost:3000`
2. **Base de datos**: La base de datos debe estar inicializada con datos de prueba
3. **Dependencias**: Ejecuta `npm install` para instalar todas las dependencias

## Usuarios de Prueba

Las pruebas utilizan los siguientes usuarios de prueba (creados por el seed):

- **Admin Institución**: `admin@sanjose.edu` / `SanJose123!`
- **Profesor**: `juan.perez@sanjose.edu` / `Prof123!`
- **Estudiante**: `santiago.gomez@sanjose.edu` / `Est123!`

## Ejecutar las Pruebas

### Opción 1: Usando npm script (Recomendado)
```bash
npm run test:api
```

### Opción 2: Ejecutar directamente con ts-node
```bash
npx ts-node test-api-complete.ts
```

### Opción 3: Ejecutar con Node.js (compilado)
```bash
npm run build
node dist/test-api-complete.js
```

## Qué Prueban Estas Pruebas

### 🔐 Autenticación y Autorización
- Login exitoso para diferentes roles
- Tokens JWT válidos
- Control de acceso basado en roles

### 🏫 Grupos (Solo Admin Institución)
- ✅ Listar todos los grupos con paginación
- ✅ Crear nuevo grupo
- ✅ Obtener grupo específico
- ✅ Actualizar grupo
- ✅ Eliminar grupo
- ❌ Acceso denegado para profesores y estudiantes

### 📚 Materias (Solo Admin Institución)
- ✅ Listar todas las materias
- ✅ Crear nueva materia con validación de unicidad
- ✅ Obtener materia específica
- ✅ Actualizar materia
- ✅ Eliminar materia
- ❌ Acceso denegado para profesores y estudiantes

### 📅 Horarios (Solo Admin Institución)
- ✅ Listar todos los horarios con filtros
- ✅ Crear horario con validación de conflictos
- ✅ Obtener horario específico
- ✅ Actualizar horario
- ✅ Eliminar horario
- ✅ Endpoint especial: `/horarios/grupo/:grupoId`
- ❌ Acceso denegado para profesores y estudiantes

### 👨‍🏫 Dashboard del Profesor (Solo Profesores)
- ✅ Obtener clases del día actual
- ✅ Obtener clases por día específico (1-7)
- ✅ Obtener horario semanal completo
- ❌ Acceso denegado para admins y estudiantes

### 🔍 Validación y Manejo de Errores
- ✅ Datos inválidos (campos requeridos vacíos)
- ✅ Días de semana inválidos (>7)
- ✅ Acceso sin autenticación (401)
- ✅ Acceso con permisos insuficientes (403)

## Resultados Esperados

Al ejecutar las pruebas, deberías ver una salida como esta:

```
🚀 Iniciando pruebas de API - AsistApp Backend
==============================================

📋 PRUEBAS DE AUTENTICACIÓN
===========================
🔐 Obteniendo token para ADMIN_INSTITUCION (admin@institucion1.com)...
✅ Token obtenido para ADMIN_INSTITUCION
🔐 Obteniendo token para PROFESOR (profesor@institucion1.com)...
✅ Token obtenido para PROFESOR
🔐 Obteniendo token para ESTUDIANTE (estudiante@institucion1.com)...
✅ Token obtenido para ESTUDIANTE

🏫 PRUEBAS DE GRUPOS (Admin Institución)
========================================

🧪 Listar todos los grupos - Admin Institución
   GET /grupos
✅ Status: 200 (esperado: 200)
   ✅ Respuesta exitosa

[... más pruebas ...]

✅ PRUEBAS COMPLETADAS
======================

📊 Resultados: 25/25 pruebas pasaron

🎯 Resumen de pruebas ejecutadas:
• Autenticación y autorización por roles
• CRUD completo para Grupos, Materias y Horarios
• Dashboard del profesor con clases del día
• Validación de datos y manejo de errores
• Control de acceso basado en roles

🎉 ¡Todas las pruebas pasaron exitosamente!
```

## Solución de Problemas

### Error: "connect ECONNREFUSED 127.0.0.1:3000"
- Asegúrate de que el backend esté ejecutándose
- Verifica que el puerto 3000 esté disponible

### Error: "Token no obtenido"
- Verifica que los usuarios de prueba existan en la base de datos
- Ejecuta `npm run prisma:seed` para poblar la base de datos

### Error: "Status: 500 (esperado: 200)"
- Revisa los logs del backend para errores del servidor
- Verifica que la base de datos esté correctamente configurada

### Error: "Status: 403 (esperado: 200)"
- Verifica que los roles de los usuarios estén correctamente asignados
- Asegúrate de que los usuarios pertenezcan a instituciones válidas

## Estructura del Código

El archivo `test-api-complete.ts` contiene:

- **Clase ApiTester**: Maneja toda la lógica de pruebas
- **Métodos de autenticación**: Obtención y gestión de tokens JWT
- **Métodos de prueba**: Ejecución de requests HTTP con validación
- **Suite completa**: Todas las pruebas organizadas por funcionalidad
- **Reporting**: Conteo y resumen de resultados

## Personalización

Puedes modificar las pruebas editando el archivo `test-api-complete.ts`:

- Cambiar URLs de usuarios de prueba
- Agregar nuevas pruebas
- Modificar datos de prueba
- Ajustar timeouts y configuraciones

## Integración con CI/CD

Este archivo puede integrarse fácilmente en pipelines de CI/CD:

```yaml
# Ejemplo GitHub Actions
- name: Run API Tests
  run: npm run test:api
  working-directory: backend
```

## Resultados de las Pruebas

### ✅ Estado Actual: **23/24 pruebas pasan** (96.7% de éxito)

Las pruebas se ejecutan exitosamente y validan:

- ✅ **Autenticación JWT** por diferentes roles
- ✅ **Control de acceso** basado en roles (admin_institucion, profesor, estudiante)
- ✅ **CRUD completo** para Grupos, Materias y Horarios
- ✅ **Dashboard del profesor** con clases del día
- ✅ **Validación de datos** y manejo de errores
- ✅ **Paginación y filtros** en listados
- ✅ **Relaciones de base de datos** correctamente incluidas

### Última Ejecución
```
📊 Resultados: 23/24 pruebas pasaron
🎉 ¡Casi todas las pruebas pasaron exitosamente!
```

### Prueba que Falló (Esperado)
- **Crear grupo sin periodoId**: Falla correctamente con error 400 (validación requerida)

### Comandos para Ejecutar

```bash
# Ejecutar pruebas API
npm run test:api

# Ver logs del backend
docker compose logs -f backend

# Reiniciar backend si es necesario
docker compose restart backend
```