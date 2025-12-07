# 📋 Plan de Implementación: Rol ACUDIENTE con Notificaciones Push

## Resumen Ejecutivo
Implementar el rol ACUDIENTE que permita a padres/tutores:
- Iniciar sesión en la aplicación
- Ver el historial de asistencias de sus hijos
- Recibir notificaciones push gratuitas (Firebase) cuando sus hijos falten
- Dashboard con estadísticas de asistencia

---

## FASE 1: Base de Datos 📊

### 1.1 Actualizar Prisma Schema

**Archivo:** `backend/prisma/schema.prisma`

```prisma
// Agregar relación en modelo Usuario
model Usuario {
  // ... campos existentes ...
  
  // Nuevas relaciones para acudiente
  hijosComoAcudiente    AcudienteEstudiante[] @relation("AcudienteRelation")
  notificacionesInApp   NotificacionInApp[]
  dispositivosFCM       DispositivoFCM[]
}

// Nueva tabla: Relación Acudiente-Estudiante
model AcudienteEstudiante {
  id           String   @id @default(uuid()) @db.Uuid
  acudienteId  String   @map("acudiente_id") @db.Uuid
  estudianteId String   @map("estudiante_id") @db.Uuid
  parentesco   String   @db.VarChar(50) // "padre", "madre", "tutor", "otro"
  esPrincipal  Boolean  @default(false) @map("es_principal")
  activo       Boolean  @default(true)
  createdAt    DateTime @default(now()) @map("created_at")
  updatedAt    DateTime @default(now()) @updatedAt @map("updated_at")

  acudiente  Usuario    @relation("AcudienteRelation", fields: [acudienteId], references: [id], onDelete: Cascade)
  estudiante Estudiante @relation(fields: [estudianteId], references: [id], onDelete: Cascade)

  @@unique([acudienteId, estudianteId])
  @@index([acudienteId])
  @@index([estudianteId])
  @@map("acudientes_estudiantes")
}

// Nueva tabla: Notificaciones In-App
model NotificacionInApp {
  id           String   @id @default(uuid()) @db.Uuid
  usuarioId    String   @map("usuario_id") @db.Uuid
  titulo       String   @db.VarChar(255)
  mensaje      String   @db.Text
  tipo         String   @db.VarChar(50) // "ausencia", "tardanza", "justificado", "general"
  leida        Boolean  @default(false)
  estudianteId String?  @map("estudiante_id") @db.Uuid // Referencia al estudiante (opcional)
  materiaId    String?  @map("materia_id") @db.Uuid    // Referencia a la materia (opcional)
  datos        Json?    // Datos adicionales
  createdAt    DateTime @default(now()) @map("created_at")

  usuario Usuario @relation(fields: [usuarioId], references: [id], onDelete: Cascade)

  @@index([usuarioId])
  @@index([leida])
  @@map("notificaciones_in_app")
}

// Nueva tabla: Dispositivos FCM (para push notifications)
model DispositivoFCM {
  id          String   @id @default(uuid()) @db.Uuid
  usuarioId   String   @map("usuario_id") @db.Uuid
  token       String   @db.Text // Token FCM del dispositivo
  plataforma  String   @db.VarChar(20) // "android", "ios", "web"
  activo      Boolean  @default(true)
  createdAt   DateTime @default(now()) @map("created_at")
  updatedAt   DateTime @default(now()) @updatedAt @map("updated_at")

  usuario Usuario @relation(fields: [usuarioId], references: [id], onDelete: Cascade)

  @@unique([usuarioId, token])
  @@index([usuarioId])
  @@map("dispositivos_fcm")
}

// Actualizar Estudiante para la relación
model Estudiante {
  // ... campos existentes ...
  
  acudientes AcudienteEstudiante[]
}
```

### 1.2 Actualizar Constantes de Roles

**Archivo:** `backend/src/constants/roles.ts`

```typescript
export enum UserRole {
    SUPER_ADMIN = 'super_admin',
    ADMIN_INSTITUCION = 'admin_institucion',
    PROFESOR = 'profesor',
    ESTUDIANTE = 'estudiante',
    ACUDIENTE = 'acudiente',  // NUEVO
}

export function getRoleName(role: UserRole): string {
    const roleNames: Record<UserRole, string> = {
        [UserRole.SUPER_ADMIN]: 'Super Administrador',
        [UserRole.ADMIN_INSTITUCION]: 'Administrador de Institución',
        [UserRole.PROFESOR]: 'Profesor',
        [UserRole.ESTUDIANTE]: 'Estudiante',
        [UserRole.ACUDIENTE]: 'Acudiente',  // NUEVO
    };
    return roleNames[role];
}
```

---

## FASE 2: Backend - Servicios 🔧

### 2.1 Servicio de Acudiente

**Archivo nuevo:** `backend/src/services/acudiente.service.ts`

```typescript
// Funciones principales:
// - getHijos(acudienteId): Lista de estudiantes vinculados
// - getHistorialAsistencias(estudianteId, fechaInicio, fechaFin): Historial
// - getEstadisticas(estudianteId): Estadísticas de asistencia
// - vincularEstudiante(acudienteId, estudianteId, parentesco): Vincular hijo
```

### 2.2 Servicio de Notificaciones Push

**Archivo nuevo:** `backend/src/services/push-notification.service.ts`

```typescript
// Funciones principales:
// - registrarDispositivo(usuarioId, token, plataforma): Guardar token FCM
// - enviarNotificacion(usuarioId, titulo, mensaje, datos): Enviar push
// - enviarNotificacionAcudientes(estudianteId, tipo, datos): Notificar a todos los acudientes
// - crearNotificacionInApp(usuarioId, notificacion): Guardar en BD
```

### 2.3 Integración con Asistencia

**Modificar:** `backend/src/services/asistencia.service.ts`

```typescript
// Al registrar una AUSENCIA o TARDANZA:
// 1. Buscar acudientes del estudiante
// 2. Crear NotificacionInApp para cada uno
// 3. Enviar push notification via Firebase
```

---

## FASE 3: Backend - Endpoints 🛣️

### 3.1 Rutas del Acudiente

**Archivo nuevo:** `backend/src/routes/acudiente.routes.ts`

```typescript
// GET  /acudiente/hijos                         - Lista de hijos
// GET  /acudiente/hijos/:id                     - Detalle de un hijo
// GET  /acudiente/hijos/:id/asistencias         - Historial de asistencias
// GET  /acudiente/hijos/:id/estadisticas        - Estadísticas
// GET  /acudiente/notificaciones                - Lista de notificaciones
// PUT  /acudiente/notificaciones/:id/leer       - Marcar como leída
// PUT  /acudiente/notificaciones/leer-todas     - Marcar todas como leídas
// POST /acudiente/dispositivo                   - Registrar dispositivo FCM
// DELETE /acudiente/dispositivo/:token          - Eliminar dispositivo
```

### 3.2 Rutas de Administración

**Modificar rutas existentes para permitir:**

```typescript
// POST /usuarios - Crear acudiente (admin_institucion)
// POST /acudiente/vincular - Vincular estudiante a acudiente
// GET  /estudiantes/:id/acudientes - Ver acudientes de un estudiante
```

---

## FASE 4: Frontend - Configuración Firebase 🔥

### 4.1 Dependencias

**Archivo:** `pubspec.yaml`

```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.10
```

### 4.2 Configuración

1. Crear proyecto en Firebase Console
2. Registrar app Android: descargar `google-services.json`
3. Registrar app iOS: descargar `GoogleService-Info.plist`
4. Configurar en `android/app/build.gradle` y `ios/`

---

## FASE 5: Frontend - Servicios y Providers 📱

### 5.1 Servicio de Push Notifications

**Archivo nuevo:** `lib/services/push_notification_service.dart`

```dart
class PushNotificationService {
  // - initialize(): Configurar Firebase Messaging
  // - requestPermission(): Solicitar permisos
  // - getToken(): Obtener token FCM
  // - onMessage(): Escuchar notificaciones en foreground
  // - onBackgroundMessage(): Notificaciones en background
  // - registerDevice(token): Enviar token al backend
}
```

### 5.2 Provider del Acudiente

**Archivo nuevo:** `lib/providers/acudiente_provider.dart`

```dart
class AcudienteProvider extends ChangeNotifier {
  List<Estudiante> _hijos = [];
  List<NotificacionInApp> _notificaciones = [];
  int _notificacionesSinLeer = 0;
  
  // - loadHijos(): Cargar lista de hijos
  // - loadHistorialAsistencias(estudianteId): Historial
  // - loadEstadisticas(estudianteId): Estadísticas
  // - loadNotificaciones(): Lista de notificaciones
  // - marcarComoLeida(notificacionId): Marcar leída
}
```

---

## FASE 6: Frontend - Pantallas 📺

### 6.1 Dashboard del Acudiente

**Archivo nuevo:** `lib/screens/acudiente/acudiente_dashboard_screen.dart`

- Resumen de todos los hijos
- Contadores: faltas hoy, semana, mes
- Últimas notificaciones
- Acceso rápido a cada hijo

### 6.2 Detalle del Estudiante

**Archivo nuevo:** `lib/screens/acudiente/estudiante_detail_screen.dart`

- Información del estudiante
- Estadísticas visuales (gráficos)
- Historial de asistencias
- Filtros por fecha/materia

### 6.3 Estadísticas

**Archivo nuevo:** `lib/screens/acudiente/estadisticas_screen.dart`

- Gráfico de torta: Presente vs Ausente vs Tardanza
- Gráfico de barras: Faltas por materia
- Tendencia semanal/mensual
- Comparativa entre hijos (si tiene varios)

### 6.4 Centro de Notificaciones

**Archivo nuevo:** `lib/screens/acudiente/notificaciones_screen.dart`

- Lista de notificaciones
- Marcar como leída
- Filtros por tipo
- Badge de no leídas

---

## FASE 7: Navegación y Autorización 🧭

### 7.1 Actualizar Router

**Modificar:** `lib/router/app_router.dart`

```dart
// Nuevas rutas:
// /acudiente/dashboard
// /acudiente/hijos/:id
// /acudiente/hijos/:id/estadisticas
// /acudiente/notificaciones
```

### 7.2 Actualizar Shell

- Menú lateral específico para acudiente
- Badge de notificaciones sin leer
- Navegación entre hijos

---

## FASE 8: Flujo de Notificaciones 🔔

### Flujo Completo:

```
[Profesor registra AUSENCIA]
         │
         ▼
[AsistenciaService.registrarAsistencia()]
         │
         ▼
[Si estado == 'AUSENTE' o 'TARDANZA']
         │
         ▼
[Buscar acudientes del estudiante]
         │
         ▼
[Para cada acudiente:]
    ├── Crear NotificacionInApp en BD
    └── Enviar Push vía Firebase
         │
         ▼
[Acudiente recibe notificación]
    ├── Si app abierta: Muestra in-app
    └── Si app cerrada: Push notification del sistema
```

---

## 📅 Cronograma de Implementación

| Día | Tareas |
|-----|--------|
| **Día 1** | Fase 1: Schema Prisma + Migración + Constantes |
| **Día 2** | Fase 2: Servicios backend (acudiente + notificaciones) |
| **Día 3** | Fase 3: Endpoints + Integración asistencia |
| **Día 4** | Fase 4-5: Firebase config + Servicios Flutter |
| **Día 5** | Fase 6: Pantallas (Dashboard + Detalle) |
| **Día 6** | Fase 6: Pantallas (Estadísticas + Notificaciones) |
| **Día 7** | Fase 7-8: Navegación + Testing + Ajustes |

---

## 📦 Archivos a Crear/Modificar

### Backend (Nuevos):
- `src/services/acudiente.service.ts`
- `src/services/push-notification.service.ts`
- `src/routes/acudiente.routes.ts`
- `src/controllers/acudiente.controller.ts`

### Backend (Modificar):
- `prisma/schema.prisma`
- `src/constants/roles.ts`
- `src/services/asistencia.service.ts`
- `src/services/user.service.ts`
- `src/routes/index.ts`

### Frontend (Nuevos):
- `lib/services/push_notification_service.dart`
- `lib/services/acudiente_service.dart`
- `lib/providers/acudiente_provider.dart`
- `lib/providers/notification_provider.dart`
- `lib/models/notificacion_in_app.dart`
- `lib/screens/acudiente/acudiente_dashboard_screen.dart`
- `lib/screens/acudiente/estudiante_detail_screen.dart`
- `lib/screens/acudiente/estadisticas_screen.dart`
- `lib/screens/acudiente/notificaciones_screen.dart`

### Frontend (Modificar):
- `pubspec.yaml`
- `lib/router/app_router.dart`
- `lib/constants/user_roles.dart`
- `lib/main.dart`
- `android/app/build.gradle`
- `android/app/google-services.json` (nuevo)

---

## ✅ Checklist de Implementación

- [ ] **Fase 1: Base de Datos**
  - [ ] Actualizar schema.prisma
  - [ ] Generar migración
  - [ ] Aplicar migración
  - [ ] Actualizar constants/roles.ts

- [ ] **Fase 2: Backend Servicios**
  - [ ] Crear acudiente.service.ts
  - [ ] Crear push-notification.service.ts
  - [ ] Modificar asistencia.service.ts

- [ ] **Fase 3: Backend Endpoints**
  - [ ] Crear acudiente.routes.ts
  - [ ] Crear acudiente.controller.ts
  - [ ] Registrar rutas

- [ ] **Fase 4: Firebase Config**
  - [ ] Crear proyecto Firebase
  - [ ] Configurar Android
  - [ ] Configurar iOS (opcional)
  - [ ] Agregar dependencias Flutter

- [ ] **Fase 5: Frontend Servicios**
  - [ ] Crear push_notification_service.dart
  - [ ] Crear acudiente_service.dart
  - [ ] Crear providers

- [ ] **Fase 6: Frontend Pantallas**
  - [ ] Dashboard acudiente
  - [ ] Detalle estudiante
  - [ ] Estadísticas
  - [ ] Notificaciones

- [ ] **Fase 7: Navegación**
  - [ ] Actualizar router
  - [ ] Actualizar shell/menú
  - [ ] Badge notificaciones

- [ ] **Fase 8: Testing**
  - [ ] Pruebas de flujo completo
  - [ ] Ajustes finales
