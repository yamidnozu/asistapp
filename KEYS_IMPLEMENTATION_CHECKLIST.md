# 📋 Checklist: Implementar Keys en Widgets (Paso 0)

## 🎯 Objetivo
Agregar Keys únicos a los widgets para que los tests E2E sean estables y no dependan de texto/iconos.

## 📁 Archivos a Modificar

### 1. `lib/screens/login_screen.dart`
- [ ] Email TextFormField: `key: const Key('login_email_field')`
- [ ] Password TextFormField: `key: const Key('login_password_field')`
- [ ] Login Button: `key: const Key('login_button')`

**Ejemplo:**
```dart
TextFormField(
  key: const Key('login_email_field'),
  decoration: InputDecoration(
    labelText: 'Email',
  ),
)

ElevatedButton(
  key: const Key('login_button'),
  onPressed: () => _handleLogin(),
  child: const Text('Iniciar Sesión'),
)
```

---

### 2. `lib/screens/dashboard_screens/super_admin_dashboard.dart` (o similar)
- [ ] Instituciones Tab/Button: `key: const Key('nav_institutions')`
- [ ] Usuarios Tab/Button: `key: const Key('nav_users')`

**Ejemplo:**
```dart
ListTile(
  key: const Key('nav_institutions'),
  title: const Text('Instituciones'),
  onTap: () => _navigateTo('instituciones'),
)
```

---

### 3. `lib/screens/dashboard_screens/admin_dashboard.dart` (si es diferente)
- [ ] Usuarios Tab/Button: `key: const Key('nav_users_admin')`

---

### 4. `lib/screens/dashboard_screens/teacher_dashboard.dart` (si aplica)
- [ ] Clases Tab/Button: `key: const Key('nav_classes')`
- [ ] Tomar Asistencia Button: `key: const Key('nav_attendance')`

---

### 5. `lib/screens/dashboard_screens/student_dashboard.dart` (si aplica)
- [ ] Mi Código QR Button: `key: const Key('nav_qr_code')`
- [ ] Mi Horario Button: `key: const Key('nav_schedule')`

---

### 6. `lib/screens/institutions/institutions_list_screen.dart`
- [ ] FloatingActionButton (agregar institución): `key: const Key('add_fab')`
- [ ] Menu Button (Icons.more_vert): `key: const Key('edit_menu_button')`

**Ejemplo:**
```dart
FloatingActionButton(
  key: const Key('add_fab'),
  onPressed: () => _showCreateDialog(),
  child: const Icon(Icons.add),
)
```

---

### 7. `lib/screens/users/users_list_screen.dart` (o similar)
- [ ] FloatingActionButton (agregar usuario): `key: const Key('add_fab')`
- [ ] SpeedDial/Menu para Profesor: `key: const Key('add_professor_button')`
- [ ] SpeedDial/Menu para Estudiante: `key: const Key('add_student_button')`
- [ ] SpeedDial/Menu para otra opción: `key: const Key('add_institution_button')`

**Ejemplo:**
```dart
SpeedDialChild(
  key: const Key('add_professor_button'),
  label: 'Agregar Profesor',
  child: const Icon(Icons.school),
  onTap: () => _showProfessorForm(),
)
```

---

### 8. `lib/screens/institutions/institution_form_screen.dart`
- [ ] Nombre/Razón Social Field: `key: const Key('form_name_field')`
- [ ] Código Field: `key: const Key('form_code_field')`
- [ ] Email Field: `key: const Key('form_email_field')`
- [ ] Teléfono Field: `key: const Key('form_phone_field')`
- [ ] Dirección Field: `key: const Key('form_address_field')`
- [ ] Guardar Button: `key: const Key('form_save_button')`
- [ ] Cancelar Button: `key: const Key('form_cancel_button')`

**Ejemplo:**
```dart
TextFormField(
  key: const Key('form_name_field'),
  decoration: InputDecoration(labelText: 'Nombre de Institución'),
)

ElevatedButton(
  key: const Key('form_save_button'),
  onPressed: () => _save(),
  child: const Text('Guardar'),
)
```

---

### 9. `lib/screens/users/user_form_screen.dart`
- [ ] Nombres Field: `key: const Key('form_name_field')`
- [ ] Apellidos Field: `key: const Key('form_lastname_field')`  ← **NOTA: Usar apellidos**
- [ ] Email Field: `key: const Key('form_email_field')`
- [ ] Teléfono Field: `key: const Key('form_phone_field')`
- [ ] Identificación Field: `key: const Key('form_identification_field')`
- [ ] Responsable Field (Estudiantes): `key: const Key('form_responsible_field')`
- [ ] Teléfono Responsable (Estudiantes): `key: const Key('form_responsible_phone_field')`
- [ ] Rol Dropdown (si aplica): `key: const Key('form_role_dropdown')`
- [ ] Guardar Button: `key: const Key('form_save_button')`
- [ ] Cancelar Button: `key: const Key('form_cancel_button')`

---

### 10. `lib/screens/institution_selection_screen.dart` (si aplica)
- [ ] Radio Button Institución 1: `key: const Key('institution_radio_button_0')`
- [ ] Radio Button Institución 2: `key: const Key('institution_radio_button_1')`
- [ ] Continuar Button: `key: const Key('institution_continue_button')`

**Ejemplo:**
```dart
RadioListTile<String>(
  key: const Key('institution_radio_button_0'),
  title: const Text('Primera Institución'),
  value: 'inst_1',
  groupValue: _selectedInstitution,
  onChanged: (value) => setState(() => _selectedInstitution = value),
)
```

---

### 11. `lib/screens/*/` (Alert Dialogs - Confirmación)
- [ ] Botón Confirmar en AlertDialog: `key: const Key('alert_confirm_button')`
- [ ] Botón Cancelar en AlertDialog: `key: const Key('alert_cancel_button')`

**Ejemplo:**
```dart
AlertDialog(
  title: const Text('¿Eliminar?'),
  actions: [
    TextButton(
      key: const Key('alert_cancel_button'),
      onPressed: () => Navigator.pop(context),
      child: const Text('Cancelar'),
    ),
    TextButton(
      key: const Key('alert_confirm_button'),
      onPressed: () => _deleteItem(),
      child: const Text('Eliminar'),
    ),
  ],
)
```

---

### 12. `lib/screens/*/` (App Bar - Logout)
- [ ] Logout Button (Icons.logout): `key: const Key('logout_button')`

**Ejemplo:**
```dart
AppBar(
  actions: [
    IconButton(
      key: const Key('logout_button'),
      icon: const Icon(Icons.logout),
      onPressed: () => _handleLogout(),
    ),
  ],
)
```

---

## 📊 Resumen de Keys Necesarias

| Pantalla | Widget | Key | Prioridad |
|----------|--------|-----|-----------|
| Login | Email Field | `login_email_field` | 🔴 Alta |
| Login | Password Field | `login_password_field` | 🔴 Alta |
| Login | Login Button | `login_button` | 🔴 Alta |
| Dashboard | Nav Institutions | `nav_institutions` | 🔴 Alta |
| Dashboard | Nav Users | `nav_users` | 🔴 Alta |
| Lists | Add FAB | `add_fab` | 🔴 Alta |
| Forms | Name Field | `form_name_field` | 🔴 Alta |
| Forms | Code Field | `form_code_field` | 🟡 Media |
| Forms | Email Field | `form_email_field` | 🔴 Alta |
| Forms | Save Button | `form_save_button` | 🔴 Alta |
| Alerts | Confirm Button | `alert_confirm_button` | 🔴 Alta |
| App Bar | Logout Button | `logout_button` | 🟡 Media |
| Selection | Radio Buttons | `institution_radio_button_*` | 🟡 Media |

**Total:** ~35 Keys

**Prioridad 🔴 Alta:** 15 Keys (Implementar primero)  
**Prioridad 🟡 Media:** 10 Keys (Después)  
**Prioridad 🟢 Baja:** 10 Keys (Opcional)

---

## ✅ Checklist de Implementación

### Fase 1: Keys Críticas (15 minutos)
- [ ] Login Screen - Email Field
- [ ] Login Screen - Password Field
- [ ] Login Screen - Login Button
- [ ] Dashboard - Nav Institutions
- [ ] Dashboard - Nav Users
- [ ] Lists - Add FAB
- [ ] Forms - Name Field
- [ ] Forms - Email Field
- [ ] Forms - Save Button
- [ ] Alerts - Confirm Button

### Fase 2: Keys Complementarias (10 minutos)
- [ ] Forms - Code Field
- [ ] Forms - Other Fields
- [ ] Dashboard - Other Buttons
- [ ] Institution Selection - Radio Buttons
- [ ] App Bar - Logout Button

### Fase 3: Keys Opcionales (5 minutos)
- [ ] Cancel Buttons
- [ ] Additional Buttons
- [ ] Other Components

---

## 🔍 Validación

### Después de agregar cada Key, verifica:

1. **Compilación**
   ```bash
   flutter analyze
   ```

2. **No hay conflictos**
   ```bash
   # Buscar duplicados
   grep -r "Key('.*')" lib/
   ```

3. **El widget se encuentra en tests**
   ```dart
   // En test
   expect(find.byKey(const Key('login_email_field')), findsOneWidget);
   ```

---

## 📝 Notas

- **Convención:** `Key('context_component')` ej: `login_email_field`, `form_name_field`
- **Ubicación:** El Key va en el constructor del widget
- **Tipado:** Usar `const Key()` siempre
- **Duplicados:** Verificar que no haya keys duplicados

---

## 🎯 Próximo Paso

Una vez hayas agregado todos los Keys:

```bash
# 1. Compilar y verificar
flutter pub get
flutter analyze

# 2. Ejecutar tests de aceptación
flutter test integration_test/acceptance_flows_test.dart -d windows
```

---

**Documento:** Checklist Keys para E2E  
**Estado:** 📋 Usar como guía de implementación  
**Última actualización:** 2024
