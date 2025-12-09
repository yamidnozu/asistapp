# 📋 Plan de Implementación: Gestión de Acudientes y Contraseñas

## 🎯 Objetivo
Implementar un flujo completo para vincular acudientes a estudiantes con facilidad de uso, incluyendo la capacidad de crear nuevos acudientes inline y gestionar contraseñas.

---

## ✅ ESTADO FINAL: IMPLEMENTACIÓN COMPLETADA

| Componente | Estado | Notas |
|------------|--------|-------|
| Backend crear usuario ACUDIENTE | ✅ **Corregido** | `user.service.ts` línea 175 |
| Widget `GestionarAcudientesSheet` | ✅ **Creado** | Nuevo widget Bottom Sheet |
| Botón "Gestionar Acudientes" | ✅ **Creado** | En `UserDetailScreen` para estudiantes |
| Botón "Regenerar Contraseña" | ✅ **Creado** | En `UserDetailScreen` para todos |
| Test E2E FASE 7 | ✅ **Agregado** | Test de acudientes en `main_e2e_test.dart` |
| Seed con acudientes | ✅ **Ya existía** | 4 acudientes, 5 vínculos, 6 notificaciones |
| Integración notificaciones | ✅ **Ya existía** | Notificaciones in-app automáticas |

---

## 🏗️ Archivos Modificados/Creados

```
📁 backend/src/
├── services/
│   └── user.service.ts          # ✅ Agregar ACUDIENTE a roles válidos
├── prisma/
│   └── seed.ts                  # ✅ Ya tenía acudientes completos

📁 lib/
├── models/
│   └── user.dart                # ✅ Agregar getter esAcudiente
├── screens/users/
│   └── user_detail_screen.dart  # ✅ Botones Gestionar Acudientes + Regenerar Contraseña
├── widgets/
│   └── gestionar_acudientes_sheet.dart  # ✅ NUEVO widget completo
├── services/
│   └── acudiente_service.dart   # ✅ Campos email/telefono en AcudienteVinculadoResponse

📁 integration_test/
└── main_e2e_test.dart           # ✅ FASE 7 agregada
```

---

## 🔐 Credenciales de Acudientes en Seed

| Acudiente | Email | Contraseña | Hijos |
|-----------|-------|------------|-------|
| María Mendoza | maria.mendoza@email.com | Acu123! | Santiago, Valentina |
| Patricia Castro | patricia.castro@email.com | Acu123! | Mateo |
| Carmen López | carmen.lopez@email.com | Acu123! | Andrés |
| Carlos Núñez | carlos.nunez@email.com | Acu123! | Sofía |

---

## 🔔 Integración con Notificaciones

El sistema ya tiene integración completa:

1. **Automático**: Cuando se registra ausencia/tardanza → Se crea notificación in-app para cada acudiente vinculado
2. **Endpoints del acudiente**:
   - `GET /acudiente/notificaciones` - Ver notificaciones
   - `GET /acudiente/notificaciones/no-leidas/count` - Contador no leídas
   - `PUT /acudiente/notificaciones/:id/leer` - Marcar como leída
   - `PUT /acudiente/notificaciones/leer-todas` - Marcar todas como leídas

---

## 📱 Funcionalidades del Widget GestionarAcudientesSheet

1. ✅ Ver acudientes vinculados al estudiante
2. ✅ Buscar acudiente existente por email
3. ✅ Crear nuevo acudiente con formulario inline
4. ✅ Generar contraseña temporal automática
5. ✅ Mostrar credenciales con opción copiar
6. ✅ Selector de parentesco (padre, madre, tutor, etc.)
7. ✅ Desvincular acudientes existentes

---

## 🔐 Funcionalidades de Regeneración de Contraseña

1. ✅ Botón "Regenerar Contraseña" en detalle de usuario
2. ✅ Diálogo de confirmación antes de regenerar
3. ✅ Generación de contraseña segura (10 caracteres, mayúsculas, minúsculas, números, especiales)
4. ✅ Mostrar nueva contraseña con opción copiar
5. ✅ Advertencia de uso único (no se volverá a mostrar)

---

## 🧪 Test E2E - FASE 7: Gestión de Acudientes

```
📍 FASE 7: GESTIÓN DE ACUDIENTES
  7.1 Crear usuario acudiente vía API
  7.2 Vincular acudiente a estudiante  
  7.3 Login del acudiente
  7.4 Acudiente ve estudiante vinculado
  7.5 Regenerar contraseña acudiente
  7.6 Login con nueva contraseña
```

### Comando para ejecutar:
```bash
flutter test integration_test/main_e2e_test.dart -d windows --no-pub
```

---

## ✅ Verificación Final

| Check | Resultado |
|-------|-----------|
| `flutter analyze` (archivos modificados) | ✅ No issues found! |
| `tsc --noEmit` (backend) | ✅ Exit code: 0 |
| Seed con acudientes | ✅ Completo |
| Notificaciones integradas | ✅ Funcionando |

---

## 📅 Fecha de Actualización
2025-12-08 22:55

## 👤 Autor
Claude (Antigravity Assistant)

## ✅ Estado
**IMPLEMENTACIÓN COMPLETADA AL 100%**
