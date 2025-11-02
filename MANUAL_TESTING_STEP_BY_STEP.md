# 🧪 GUÍA PASO A PASO: PRUEBAS MANUALES COMPLETAS

## 📋 PREPARACIÓN INICIAL
✅ **Backend corriendo**: Puerto 3000 (192.168.20.22:3000)
✅ **Aplicación Flutter ejecutándose**: Windows Desktop
✅ **Base de datos poblada**: Usuarios del seed.ts activos

---

## 🎯 FLUJO 1: SUPER ADMINISTRADOR
**Usuario**: `superadmin@asistapp.com` / `Admin123!`
**Tiempo estimado**: 8-10 minutos

### **PASO 1.1: Login como Super Admin**
1. **Abrir la aplicación** → Deberías ver la pantalla de login
2. **Ingresar credenciales**:
   - Email: `superadmin@asistapp.com`
   - Password: `Admin123!`
3. **Presionar "Iniciar Sesión"**
4. **Validar**: Deberías ver el dashboard del Super Admin
5. **Verificar**: En la parte superior debería aparecer "Super Admin"

### **PASO 1.2: Explorar Dashboard**
1. **Observar elementos principales**:
   - Título "Dashboard"
   - Estadísticas generales
   - Menú de navegación lateral
2. **Verificar navegación**: Deberían estar disponibles las secciones principales
3. **Validar**: No debería haber errores de carga

### **PASO 1.3: Navegar a Instituciones**
1. **Hacer clic en "Instituciones"** en el menú lateral
2. **Validar**: Deberías ver la lista de instituciones existentes
3. **Verificar**: Deberían aparecer "Colegio San José" y "IE Francisco de Paula Santander"
4. **Contar instituciones**: Deberían ser exactamente 2

### **PASO 1.4: Crear Nueva Institución**
1. **Presionar el botón flotante (+)** en la esquina inferior derecha
2. **Llenar el formulario**:
   - Nombre: `Instituto Test Manual ${timestamp_actual}`
   - Código: `test-manual-${timestamp_actual}`
   - Email: `test.manual.${timestamp_actual}@test.edu`
   - Dirección: `Calle Test 123`
   - Teléfono: `555-0123`
3. **Presionar "Guardar"**
4. **Validar**: Deberías regresar a la lista de instituciones
5. **Verificar**: La nueva institución debería aparecer en la lista
6. **Contar instituciones**: Ahora deberían ser 3

### **PASO 1.5: Editar Institución**
1. **Seleccionar la institución recién creada**
2. **Presionar el botón de editar (lápiz)**
3. **Modificar datos**:
   - Nombre: `Instituto Test Manual Editado ${timestamp_actual}`
   - Dirección: `Calle Test Editada 456`
4. **Presionar "Guardar"**
5. **Validar**: Los cambios deberían guardarse correctamente
6. **Verificar**: El nombre actualizado debería aparecer en la lista

### **PASO 1.6: Eliminar Institución**
1. **Seleccionar la institución editada**
2. **Presionar el botón de eliminar (basura)**
3. **Confirmar eliminación** en el diálogo que aparece
4. **Validar**: La institución debería desaparecer de la lista
5. **Contar instituciones**: Deberían quedar 2 nuevamente

### **PASO 1.7: Logout**
1. **Presionar el botón de logout** (icono de salida en la barra superior)
2. **Validar**: Deberías regresar a la pantalla de login
3. **Verificar**: No debería haber datos residuales de la sesión anterior

---

## 🏫 FLUJO 2: ADMINISTRADOR MULTI-INSTITUCIÓN
**Usuario**: `multi@asistapp.com` / `Multi123!`
**Tiempo estimado**: 6-8 minutos

### **PASO 2.1: Login como Admin Multi**
1. **Desde pantalla de login**, ingresar:
   - Email: `multi@asistapp.com`
   - Password: `Multi123!`
2. **Presionar "Iniciar Sesión"**
3. **Validar**: Deberías ver un selector de institución
4. **Verificar**: Deberían aparecer las 2 instituciones asignadas

### **PASO 2.2: Seleccionar Institución**
1. **Elegir "Colegio San José"** del selector
2. **Presionar "Continuar"**
3. **Validar**: Deberías acceder al dashboard de esa institución
4. **Verificar**: El título debería mostrar "Admin - Colegio San José"

### **PASO 2.3: Explorar Dashboard**
1. **Observar métricas** de la institución seleccionada
2. **Verificar navegación**: Solo secciones permitidas para esta institución
3. **Validar**: No debería poder acceder a funciones de Super Admin

### **PASO 2.4: Cambiar de Institución**
1. **Presionar el botón de cambio de institución** (si está disponible)
2. **Seleccionar "IE Francisco de Paula Santander"**
3. **Validar**: Dashboard debería actualizarse con datos de la nueva institución
4. **Verificar**: Título debería cambiar a "Admin - IE Francisco de Paula Santander"

### **PASO 2.5: Verificar Permisos**
1. **Intentar acceder a "Instituciones"** (debería estar bloqueado)
2. **Validar**: Debería mostrar mensaje de permisos insuficientes o no mostrar la opción
3. **Verificar**: Solo funciones de gestión de la institución actual deberían estar disponibles

### **PASO 2.6: Logout**
1. **Presionar logout**
2. **Validar**: Regreso a pantalla de login

---

## 👨‍💼 FLUJO 3: ADMIN DE INSTITUCIÓN ESPECÍFICA (SAN JOSÉ)
**Usuario**: `admin@sanjose.edu` / `SanJose123!`
**Tiempo estimado**: 10-12 minutos

### **PASO 3.1: Login como Admin Institución**
1. **Ingresar credenciales**:
   - Email: `admin@sanjose.edu`
   - Password: `SanJose123!`
2. **Presionar "Iniciar Sesión"**
3. **Validar**: Acceso directo al dashboard de San José (sin selector)

### **PASO 3.2: Explorar Dashboard**
1. **Verificar datos específicos** de Colegio San José
2. **Observar métricas** y estadísticas de la institución

### **PASO 3.3: Gestionar Usuarios - Ver Lista**
1. **Navegar a "Usuarios"** en el menú lateral
2. **Validar**: Deberías ver la lista de usuarios de San José
3. **Verificar**: Deberían aparecer profesores y estudiantes existentes

### **PASO 3.4: Crear Nuevo Profesor**
1. **Presionar botón flotante (+)** para agregar usuario
2. **Seleccionar tipo "Profesor"**
3. **Llenar formulario**:
   - Nombres: `María José`
   - Apellidos: `González Rodríguez`
   - Email: `maria.jose.gonzalez.${timestamp}@sanjose.edu`
   - Teléfono: `300-123-4567`
   - Especialidad: `Matemáticas`
4. **Presionar "Guardar"**
5. **Validar**: El profesor debería aparecer en la lista
6. **Verificar**: Email único generado correctamente

### **PASO 3.5: Crear Nuevo Estudiante**
1. **Presionar botón flotante (+)** nuevamente
2. **Seleccionar tipo "Estudiante"**
3. **Llenar formulario**:
   - Nombres: `Carlos Andrés`
   - Apellidos: `López Martínez`
   - Email: `carlos.andres.lopez.${timestamp}@sanjose.edu`
   - Identificación: `123456789`
   - Nombre del responsable: `Ana López`
   - Teléfono responsable: `301-987-6543`
4. **Presionar "Guardar"**
5. **Validar**: El estudiante debería aparecer en la lista

### **PASO 3.6: Editar Usuario**
1. **Seleccionar el profesor recién creado**
2. **Presionar editar**
3. **Modificar**:
   - Especialidad: `Matemáticas y Física`
   - Teléfono: `300-123-4568`
4. **Guardar cambios**
5. **Validar**: Los cambios deberían reflejarse en la lista

### **PASO 3.7: Ver Detalles de Usuario**
1. **Seleccionar un estudiante existente**
2. **Presionar "Ver detalles"**
3. **Validar**: Deberías ver información completa del estudiante
4. **Verificar**: Código QR, datos del responsable, etc.

### **PASO 3.8: Eliminar Usuario**
1. **Seleccionar el estudiante recién creado**
2. **Presionar eliminar**
3. **Confirmar eliminación**
4. **Validar**: El estudiante debería desaparecer de la lista

### **PASO 3.9: Verificar Integridad de Datos**
1. **Contar usuarios** antes y después de las operaciones
2. **Validar**: Los números deberían ser consistentes
3. **Verificar**: No deberían quedar usuarios huérfanos

### **PASO 3.10: Logout**
1. **Presionar logout**
2. **Validar**: Regreso a pantalla de login

---

## 👨‍🏫 FLUJO 4: PROFESOR
**Usuario**: `pedro.garcia@sanjose.edu` / `Prof123!`
**Tiempo estimado**: 5-7 minutos

### **PASO 4.1: Login como Profesor**
1. **Ingresar credenciales**:
   - Email: `pedro.garcia@sanjose.edu`
   - Password: `Prof123!`
2. **Presionar "Iniciar Sesión"**
3. **Validar**: Acceso al dashboard del profesor

### **PASO 4.2: Explorar Dashboard del Profesor**
1. **Verificar asignaturas** que imparte
2. **Observar horarios** de clases
3. **Validar**: Solo información relevante para profesor

### **PASO 4.3: Ver Lista de Estudiantes**
1. **Navegar a "Estudiantes"** (si está disponible)
2. **Validar**: Debería mostrar solo estudiantes de sus clases
3. **Verificar**: Información básica de estudiantes

### **PASO 4.4: Registrar Asistencia** (si funcionalidad disponible)
1. **Seleccionar una clase/horario**
2. **Marcar asistencia** para estudiantes
3. **Validar**: Los registros se guardan correctamente

### **PASO 4.5: Ver Reportes** (si disponible)
1. **Navegar a reportes**
2. **Verificar estadísticas** de asistencia por clase

### **PASO 4.6: Logout**
1. **Presionar logout**

---

## 👨‍🎓 FLUJO 5: ESTUDIANTE
**Usuario**: `juan.perez@sanjose.edu` / `Est123!`
**Tiempo estimado**: 4-6 minutos

### **PASO 5.1: Login como Estudiante**
1. **Ingresar credenciales**:
   - Email: `juan.perez@sanjose.edu`
   - Password: `Est123!`
2. **Presionar "Iniciar Sesión"**
3. **Validar**: Acceso al dashboard del estudiante

### **PASO 5.2: Explorar Dashboard del Estudiante**
1. **Ver horarios** de clases
2. **Ver estado de asistencia**
3. **Validar**: Información personalizada para el estudiante

### **PASO 5.3: Ver Código QR**
1. **Navegar a "Mi Código QR"**
2. **Validar**: Se genera y muestra correctamente
3. **Verificar**: Código único del estudiante

### **PASO 5.4: Ver Historial de Asistencia**
1. **Navegar a "Asistencia"**
2. **Validar**: Muestra registros históricos
3. **Verificar**: Fechas y estados correctos

### **PASO 5.5: Logout**
1. **Presionar logout**

---

## 🔄 FLUJOS DE REGRESIÓN Y VALIDACIÓN CRUZADA

### **REGRESIÓN 1: Cambio Rápido Entre Usuarios**
1. **Login como Super Admin** → Crear institución
2. **Logout** → Login como Admin Multi → Verificar nueva institución
3. **Logout** → Login como Admin San José → Gestionar usuarios
4. **Validar**: Cambios se propagan correctamente entre roles

### **REGRESIÓN 2: Validación de Permisos**
1. **Intentar login con credenciales incorrectas** → Validar mensaje de error
2. **Login como estudiante** → Intentar acceder a funciones de admin → Validar bloqueo
3. **Login como profesor** → Intentar crear instituciones → Validar permisos insuficientes

### **REGRESIÓN 3: Integridad de Datos**
1. **Crear usuario con datos incompletos** → Validar validaciones del formulario
2. **Eliminar usuario con asistencias registradas** → Validar manejo de dependencias
3. **Editar institución con usuarios activos** → Validar impacto en cascada

---

## 📊 CHECKLIST DE VALIDACIÓN FINAL

### **Funcionalidades Críticas Verificadas:**
- ✅ Login/logout para todos los roles
- ✅ Gestión completa de instituciones (Super Admin)
- ✅ Gestión de usuarios por institución (Admin Institución)
- ✅ Navegación y permisos por rol
- ✅ Validaciones de formularios
- ✅ Integridad de datos en operaciones CRUD

### **Aspectos de UX/UI Verificados:**
- ✅ Navegación intuitiva
- ✅ Mensajes de error claros
- ✅ Feedback visual en operaciones
- ✅ Responsive design en desktop

### **Aspectos Técnicos Verificados:**
- ✅ Conexión backend-frontend
- ✅ Persistencia de datos
- ✅ Manejo de errores
- ✅ Limpieza de sesiones

---

## 🏁 CONCLUSIÓN DE PRUEBAS

**Tiempo total estimado**: 35-45 minutos
**Cobertura**: 100% de flujos principales + regresión
**Resultado esperado**: Todos los flujos completados sin errores críticos

**Comandos para ejecutar después de pruebas:**
```bash
# Ver logs del backend durante pruebas
# Verificar base de datos después de operaciones CRUD
# Ejecutar tests E2E para comparación: flutter test integration_test/acceptance_flows_test.dart -d windows
```