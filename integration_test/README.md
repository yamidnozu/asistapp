# Tests E2E - AsistApp

## 📊 Estado: ✅ TEST MAESTRO UNIFICADO

Esta suite de pruebas E2E verifica las operaciones **CRUD reales** y flujos de negocio de AsistApp.

## 🚀 Ejecución

```bash
# TEST MAESTRO - FLUJO COMPLETO (USAR ESTE)
flutter test integration_test/main_e2e_test.dart -d windows
```

## 🎯 Archivos Disponibles

### 1. `main_e2e_test.dart` - 🎯 TEST MAESTRO UNIFICADO
**Estado:** ✅ Flujo secuencial completo  
**Descripción:** El ÚNICO test que necesitas ejecutar. Cubre el ciclo de vida completo.

**Fases del Test:**
| Fase | Rol | Operaciones |
|------|-----|-------------|
| **A** | Super Admin | Login → Crear Institución → Logout |
| **B** | Admin | Login → Crear Profesor → Crear Estudiante → Crear Grupo → Logout |
| **C** | Estudiante | Login → Verificar restricciones → Acceder QR → Logout |
| **D** | Profesor | Login → Ver clases → Tomar asistencia → Logout |
| **E** | Admin | Login → Auditar datos → Verificar integridad → Logout |

**Características:**
- ✅ ID único por sesión para rastreo
- ✅ Flujo secuencial sin reinicio de app
- ✅ CRUD real (Create, Read, verificación de Delete protection)
- ✅ Verificación cruzada entre roles (Pasamanos)
- ✅ Resumen detallado de resultados

**Ejecución:**
```bash
flutter test integration_test/main_e2e_test.dart -d windows
```

---

### 2. `complete_e2e_flows_test.dart` - Test de Referencia
**Estado:** ✅ 100% Pasando (8/8 grupos)  
**Descripción:** Test de referencia con estructura semántica por grupos.

**Grupos:**
- Grupo A: Flujo de Login y Navegación
- Grupo B: Super Admin - Instituciones
- Grupo C: Admin - Usuarios
- Grupo D: Admin - Grupos
- Grupo E: Seguridad - Roles
- Grupo F: Estudiante - Mi QR
- Grupo G: Profesor - Asistencia
- Grupo H: Auditoría y Logout

**Ejecución:**
```bash
flutter test integration_test/complete_e2e_flows_test.dart -d windows
```

---

## 📋 Credenciales de Prueba

| Rol | Email | Password |
|-----|-------|----------|
| Super Admin | superadmin@asistapp.com | Admin123! |
| Admin Institución | admin@sanjose.edu | SanJose123! |
| Profesor | juan.perez@sanjose.edu | Prof123! |
| Estudiante | santiago.mendoza@sanjose.edu | Est123! |

---

## 🔧 Requisitos Previos

1. **Backend corriendo:**
   ```bash
   docker compose up -d
   ```

2. **Dispositivo conectado:**
   ```bash
   flutter devices
   ```

3. **App compilada:**
   ```bash
   flutter build -d windows
   ```

---

## 📂 Estructura

```
integration_test/
├── main_e2e_test.dart         # 🎯 TEST MAESTRO (usar este)
├── complete_e2e_flows_test.dart  # Test de referencia
├── run_all_e2e_tests.dart     # Ejecutor (obsoleto)
├── README.md                  # Esta documentación
└── TEST_RESULTS.md           # Resultados históricos
```

---

## 💡 Tips

1. **Primer test del día:** Asegúrate que el backend tenga datos de seed
2. **Si falla login:** Verifica que las credenciales estén en la BD
3. **Si falla navegación:** La app puede haber cambiado rutas
4. **Si tarda mucho:** Los pumpAndSettle tienen timeouts largos por seguridad

---

## 📈 Output Esperado

```
═══════════════════════════════════════════════════════════════════════════════
🎯 MASTER E2E TEST - FLUJO COMPLETO
═══════════════════════════════════════════════════════════════════════════════
📋 ID de sesión: 1234567
───────────────────────────────────────────────────────────────────────────────
1️⃣ FASE A: SUPER ADMIN - INFRAESTRUCTURA
───────────────────────────────────────────────────────────────────────────────
  ✅ [A] A.1 Login Super Admin
  ✅ [A] A.2 Acceso global verificado
  ...
═══════════════════════════════════════════════════════════════════════════════
📊 RESUMEN FINAL
═══════════════════════════════════════════════════════════════════════════════
✅ Pasos exitosos: 25
❌ Pasos fallidos: 2
📈 Tasa de éxito: 92.6% (25/27)
═══════════════════════════════════════════════════════════════════════════════
🎉 TEST MASTER E2E COMPLETADO
═══════════════════════════════════════════════════════════════════════════════
```
