# 🗺️ Resumen de Rutas - AsistApp

## Estado del Router
✅ **TODAS LAS RUTAS ESTÁN CONFIGURADAS CORRECTAMENTE**

## Problema Resuelto
El log de GoRouter solo mostraba 2 rutas (`/login` y `/users/create`) porque:
- **StatefulShellRoute no expande sus sub-rutas en el log inicial**
- Las rutas anidadas dentro de branches NO aparecen en el log de diagnóstico
- **Esto es comportamiento normal de GoRouter**

### ✅ Se agregó la ruta faltante:
- `/institution-selection` → Pantalla para seleccionar institución cuando el usuario tiene acceso a múltiples

---

## 📍 Estructura de Rutas Completa

### Rutas de Nivel Superior (sin autenticación)
```
/login                       → LoginScreen
/institution-selection       → InstitutionSelectionScreen (usuario autenticado con múltiples instituciones)
/users/create               → UserFormScreen (modal fullscreen)
/users/detail/:id           → UserDetailScreen
```

### Rutas con Shell Persistente (StatefulShellRoute)
El `StatefulShellRoute` crea 3 branches con navegación persistente:

#### Branch 0: Dashboard (navegación principal)
```
/dashboard                   → SuperAdminDashboard / AdminDashboard / TeacherDashboard / StudentDashboard
/academic                    → GestionAcademicaScreen
/academic/grupos             → GruposScreen
/academic/materias           → MateriasScreen
/academic/periodos           → PeriodosAcademicosScreen
/academic/horarios           → HorariosScreen
/academic/grupos/:id         → GrupoDetailScreen
/test-multi-hora             → TestMultiHoraScreen
/student/qr                  → MyQRCodeScreen
/student/schedule            → StudentScheduleScreen
/student/attendance          → StudentAttendanceScreen
/student/notifications       → StudentNotificationsScreen
/teacher/attendance          → AttendanceScreen
```

#### Branch 1: Instituciones
```
/institutions                → InstitutionsListScreen
/institutions/form           → InstitutionFormScreen (modal)
/institutions/create-admin   → CreateInstitutionAdminScreen (modal)
/institutions/:id/admins     → InstitutionAdminsScreen
```

#### Branch 2: Usuarios
```
/users                       → UsersListScreen
```

---

## 🔐 Lógica de Autenticación y Redirección

### Flujo de Login:
1. Usuario ingresa credenciales en `/login`
2. `AuthProvider.login()` se ejecuta
3. **Si es super_admin**: va directo a `/dashboard` (sin instituciones)
4. Si tiene 1 institución: auto-selecciona y va a `/dashboard`
5. Si tiene múltiples instituciones: va a `/institution-selection`
6. Usuario selecciona institución → redirige a `/dashboard`

### Función `_checkAuth()` (redirect del router):
```dart
1. Si NO está logueado → `/login`
2. Si está logueado pero en `/login` → `/dashboard`
3. Si necesita seleccionar institución y NO está en la pantalla → `/institution-selection`
   IMPORTANTE: super_admin NUNCA entra aquí (isSuperAdmin excluye de needsSelection)
4. Si ya seleccionó pero sigue en `/institution-selection` → `/dashboard`
5. En cualquier otro caso → continúa a la ruta solicitada
```

**Lógica needsSelection actualizada:**
```dart
final isSuperAdmin = userRole == 'super_admin';
final needsSelection = 
  !isSuperAdmin &&              // ← Super admin excluido
  institutions != null && 
  institutions.length > 1 && 
  selectedInstitutionId == null;
```

---

## 🎯 Dashboard según Rol

| Rol | Pantalla | Instituciones |
|-----|----------|---------------|
| `super_admin` | SuperAdminDashboard | **Ninguna** (acceso global) |
| `admin_institucion` | AdminDashboard | Una o más instituciones |
| `profesor` | TeacherDashboard | Una o más instituciones |
| `estudiante` | StudentDashboard | Una institución |

### ⚠️ Super Admin - Consideraciones Especiales:
- **NO tiene relación con instituciones** (sin vínculos en `usuario_instituciones`)
- **NO pasa por pantalla de selección** de instituciones
- Va **directo a dashboard** después del login
- Backend retorna `[]` en `/auth/institutions` para este rol
- Frontend salta lógica de instituciones en `AuthProvider.login()`
- Router excluye de `needsSelection` con verificación `isSuperAdmin`

---

## 📱 Navegación Persistente (AppShell)

Las 3 branches del `StatefulShellRoute` mantienen su estado:
- **Dashboard**: Acceso rápido a funciones principales según rol
- **Instituciones**: Gestión de instituciones (super_admin y admin_institucion)
- **Usuarios**: Gestión de usuarios

Cada branch tiene su propio `NavigatorState` independiente.

---

## 🐛 Debug del Router

Para ver el log completo de rutas:
```dart
debugLogDiagnostics: true  // Ya está activado en el router
```

**Nota**: El log solo muestra rutas de nivel superior. Las rutas dentro de `StatefulShellRoute` no se expanden en el diagnóstico inicial pero están completamente funcionales.

---

## ✅ Checklist de Verificación

- [x] Todas las pantallas existen
- [x] Todas las imports están correctos
- [x] Ruta `/institution-selection` agregada
- [x] Lógica de redirect funciona correctamente
- [x] Backend corriendo en http://localhost:3002
- [x] Base de datos con seed completo

---

## 🚀 Para Probar

1. Ejecutar `flutter run -d windows` desde la raíz
2. Usar credenciales de prueba del login:
   - **Super Admin**: `superadmin@asistapp.com` / `Admin123!`
   - **Admin San José**: `admin@sanjose.edu` / `SanJose123!`
   - **Multi-Sede** (para probar selección): `multiadmin@asistapp.com` / `Multi123!`

3. Verificar flujo completo:
   - Login → Dashboard (si 1 institución)
   - Login → Selección → Dashboard (si múltiples instituciones)
