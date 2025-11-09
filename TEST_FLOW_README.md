# 🚀 Flujo Completo de Pruebas - Sistema de Asistencia Estudiantil

Este documento describe el flujo completo de pruebas implementado para validar todas las funcionalidades del sistema de asistencia estudiantil con QR codes.

## 📋 Descripción General

El flujo de pruebas permite ejecutar un proceso completo que simula el uso real de la aplicación, desde la creación de instituciones hasta el marcado de asistencias. Está diseñado para probar todas las funcionalidades críticas del sistema.

## 🎯 Funcionalidades Probadas

### ✅ Autenticación y Roles
- Login como Super Admin
- Gestión de roles (super_admin, admin_institucion, profesor, estudiante)

### ✅ Gestión de Instituciones
- Creación de instituciones
- Asignación de administradores de institución

### ✅ Gestión de Usuarios
- Creación de administradores de institución
- Creación de profesores
- Creación de estudiantes con códigos QR únicos

### ✅ Gestión Académica
- Creación de materias
- Creación de grupos
- Asignación de estudiantes a grupos
- Creación de horarios de clases

### ✅ Sistema de Asistencias
- Marcado de asistencias con QR
- Verificación de asistencias por profesor
- Dashboard de asistencias

### ✅ Dashboards por Rol
- Dashboard de Super Admin
- Dashboard de Admin de Institución
- Dashboard de Profesor
- Dashboard de Estudiante

## 🛠️ Cómo Usar el Flujo de Pruebas

### Opción 1: Ejecutar desde la Aplicación

1. **Iniciar la aplicación** en modo desarrollo
2. **Navegar a la pantalla de pruebas**: `/test-runner`
3. **Elegir el tipo de prueba**:
   - **Flujo Completo**: Ejecuta todos los pasos automáticamente
   - **Pruebas de UI**: Solo prueba navegación y componentes visuales
   - **Pasos Individuales**: Ejecuta pasos específicos

### Opción 2: Ejecutar Programáticamente

```dart
import '../utils/test_flow_manager.dart';

// Ejecutar flujo completo
await TestFlowManager.ejecutarFlujoCompleto(context);

// Ejecutar solo pruebas de UI
await TestFlowManager.ejecutarPruebasUI(context);

// Ejecutar pasos individuales
await TestFlowManager.step1LoginSuperAdmin(context);
await TestFlowManager.step2CrearInstitucion(context);
// ... etc
```

## 📝 Detalle del Flujo Completo

### PASO 1: Login como Super Admin
- **Usuario**: `superadmin@test.com`
- **Contraseña**: `Super123!`
- **Verificación**: Confirma acceso al dashboard de super admin

### PASO 2: Crear Institución
- **Nombre**: "Colegio Nacional de Pruebas"
- **Dirección**: Calle de las Pruebas 123
- **Teléfono**: +57 300 123 4567
- **Email**: info@colegiopruebas.edu.co
- **Tipo**: colegio

### PASO 3: Crear Administrador de Institución
- **Email**: admin.pruebas@colegiopruebas.edu.co
- **Contraseña**: Admin123!
- **Nombre**: María José Rodríguez Pérez
- **Rol**: admin_institucion
- **Teléfono**: +57 301 987 6543

### PASO 4: Crear Profesores
Se crean 3 profesores con especialidades diferentes:
1. **Juan Carlos Pérez López** - Matemáticas
2. **Ana María García Rodríguez** - Español
3. **Carlos Alberto Martínez Gómez** - Ciencias Naturales

### PASO 5: Crear Estudiantes
Se crean 4 estudiantes con datos completos:
1. **Pedro Antonio González Silva** (ID: 1234567890)
2. **María Fernanda López Hernández** (ID: 1234567891)
3. **Javier Andrés Ramírez Torres** (ID: 1234567892)
4. **Sofía Valentina Mendoza Castro** (ID: 1234567893)

### PASO 6: Crear Materias
1. **Matemáticas Avanzadas** (MAT101)
2. **Español y Literatura** (ESP201)
3. **Ciencias Naturales** (CIE301)

### PASO 7: Crear Grupos
1. **10A - Matemáticas** (Profesor: Juan Carlos)
2. **10B - Español** (Profesor: Ana María)
3. **11A - Ciencias** (Profesor: Carlos Alberto)

### PASO 8: Asignar Estudiantes a Grupos
- **Grupo 10A**: Estudiantes 1 y 2
- **Grupo 10B**: Estudiante 3
- **Grupo 11A**: Estudiante 4

### PASO 9: Crear Horarios
- **Lunes 08:00-09:30**: Matemáticas (Aula 101)
- **Miércoles 08:00-09:30**: Matemáticas (Aula 101)
- **Martes 09:45-11:15**: Español (Aula 202)
- **Jueves 14:00-15:30**: Ciencias (Aula 301)

### PASO 10: Simular Asistencias
- **Clase Matemáticas**: Todos presentes
- **Clase Español**: 1 presente
- **Clase Ciencias**: 1 presente

### PASO 11-14: Verificar Dashboards y Funcionalidades
- Dashboard de profesor con clases del día
- Dashboard de estudiante con código QR
- Escáner QR funcional
- Navegación completa

## 🔧 Configuración Previa

### Backend
Asegúrate de que el backend esté ejecutándose con:
```bash
cd backend
npm run dev
```

### Base de Datos
- El backend debe tener una base de datos PostgreSQL configurada
- Las migraciones deben estar aplicadas
- Los seeds deben estar disponibles (usuario super admin)

### Flutter
```bash
flutter pub get
flutter run
```

## 📊 Datos de Prueba

### Credenciales de Acceso
- **Super Admin**:
  - Email: `superadmin@test.com`
  - Password: `Super123!`

- **Admin Institución** (creado en pruebas):
  - Email: `admin.pruebas@colegiopruebas.edu.co`
  - Password: `Admin123!`

- **Profesores** (creados en pruebas):
  - `juan.perez@colegiopruebas.edu.co` / `Prof123!`
  - `ana.garcia@colegiopruebas.edu.co` / `Prof123!`
  - `carlos.martinez@colegiopruebas.edu.co` / `Prof123!`

- **Estudiantes** (creados en pruebas):
  - `pedro.gonzalez@colegiopruebas.edu.co` / `Est123!`
  - `maria.lopez@colegiopruebas.edu.co` / `Est123!`
  - `javier.ramirez@colegiopruebas.edu.co` / `Est123!`
  - `sofia.mendoza@colegiopruebas.edu.co` / `Est123!`

## 🎮 Uso Interactivo

### Pantalla de Test Runner
1. Ve a `/test-runner` en la aplicación
2. Elige entre:
   - **Flujo Completo**: Crea todos los datos y prueba todas las funcionalidades
   - **Pruebas UI**: Solo navegación y componentes visuales
   - **Pasos Individuales**: Ejecuta pasos específicos

### Logs en Tiempo Real
- La pantalla muestra logs detallados de cada paso
- Estados de éxito/error claramente marcados
- Progreso visual durante la ejecución

## 🐛 Manejo de Errores

### Errores Comunes
1. **Backend no ejecutándose**: Verificar que el servidor esté corriendo en el puerto correcto
2. **Base de datos no disponible**: Verificar conexión PostgreSQL
3. **Usuario ya existe**: Los datos de prueba pueden entrar en conflicto con datos existentes
4. **Permisos insuficientes**: Verificar que el usuario tenga los permisos correctos

### Recuperación
- **Limpiar datos**: Ejecutar seeds del backend para resetear la base de datos
- **Reiniciar app**: Cerrar y abrir la aplicación Flutter
- **Verificar logs**: Revisar los logs de la consola para detalles específicos

## 📈 Métricas de Prueba

El flujo mide automáticamente:
- ✅ Tiempo de ejecución por paso
- ✅ Tasa de éxito de operaciones
- ✅ Cobertura de funcionalidades probadas
- ✅ Rendimiento de navegación

## 🔄 Personalización

### Modificar Datos de Prueba
Editar `TestFlowManager` en `lib/utils/test_flow_manager.dart`:
```dart
// Cambiar credenciales
static const String testSuperAdminEmail = 'tu@email.com';
static const String testSuperAdminPassword = 'TuPassword123!';

// Modificar datos de institución
final institutionData = {
  'nombre': 'Tu Institución',
  // ... otros campos
};
```

### Agregar Nuevos Pasos
```dart
static Future<void> stepN_NuevoPaso(BuildContext context) async {
  print('🧪 PASO N: Descripción del paso');

  // Lógica del paso
  // ...

  print('✅ Paso N completado');
}
```

## 🎯 Casos de Uso Recomendados

1. **Desarrollo**: Ejecutar después de cambios importantes
2. **QA**: Validación completa antes de releases
3. **Demo**: Mostrar funcionalidades a stakeholders
4. **Debugging**: Identificar problemas específicos en flujos

## 📞 Soporte

Si encuentras problemas:
1. Verificar logs detallados en la pantalla de pruebas
2. Revisar configuración del backend
3. Verificar estado de la base de datos
4. Consultar documentación de la API

---

**Nota**: Este flujo de pruebas está diseñado para entornos de desarrollo. No ejecutar en producción sin modificaciones apropiadas.