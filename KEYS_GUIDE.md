# Instrucciones para Agregar Keys a Widgets

## ¿Por qué usar Keys?

Las `Key` permiten identificar widgets de forma única y consistente en las pruebas. Esto es más robusto que buscar por texto, ya que el texto puede cambiar pero la Key permanece constante.

## Dónde Agregar Keys

### 1. Campos de Entrada (TextFormField, TextField)

**Ubicación**: `lib/screens/` y `lib/widgets/`

```dart
// Antes
TextFormField(
  controller: _emailController,
  decoration: const InputDecoration(labelText: 'Email'),
),

// Después
TextFormField(
  key: const Key('emailField'),
  controller: _emailController,
  decoration: const InputDecoration(labelText: 'Email'),
),
```

### 2. Botones (ElevatedButton, OutlinedButton, IconButton)

```dart
// Antes
ElevatedButton(
  onPressed: _saveData,
  child: const Text('Guardar'),
),

// Después
ElevatedButton(
  key: const Key('saveButton'),
  onPressed: _saveData,
  child: const Text('Guardar'),
),
```

### 3. FloatingActionButton y SpeedDial

```dart
// Antes
FloatingActionButton(
  onPressed: () => openForm(),
  child: const Icon(Icons.add),
),

// Después
FloatingActionButton(
  key: const Key('addButton'),
  onPressed: () => openForm(),
  child: const Icon(Icons.add),
),
```

### 4. Widgets Interactivos (Checkbox, Switch, DropdownButton)

```dart
// Antes
Switch(
  value: _isActive,
  onChanged: (value) => setState(() => _isActive = value),
),

// Después
Switch(
  key: const Key('activeSwitch'),
  value: _isActive,
  onChanged: (value) => setState(() => _isActive = value),
),
```

### 5. Componentes Principales (Scaffold, AppBar, NavigationBar)

```dart
// Antes
Scaffold(
  appBar: AppBar(title: const Text('Mi Página')),
  body: ...,
),

// Después
Scaffold(
  key: const Key('myPageScaffold'),
  appBar: AppBar(
    key: const Key('myPageAppBar'),
    title: const Text('Mi Página'),
  ),
  body: ...,
),
```

## Convenciones de Nombrado para Keys

Para mantener consistencia, usa estas convenciones:

| Tipo de Widget | Convención | Ejemplo |
|---|---|---|
| TextFormField/TextField | `[screen]_[field]_field` | `login_email_field`, `form_name_field` |
| ElevatedButton | `[action]_button` | `save_button`, `delete_button` |
| OutlinedButton | `[action]_outlined_button` | `cancel_outlined_button` |
| FloatingActionButton | `[action]_fab` | `add_fab`, `create_fab` |
| IconButton | `[action]_icon_button` | `logout_icon_button` |
| Switch/Checkbox | `[field]_switch`, `[field]_checkbox` | `active_switch`, `confirm_checkbox` |
| Dialog/AlertDialog | `[name]_dialog` | `confirm_dialog`, `error_dialog` |
| ListView/GridView | `[name]_list` | `users_list`, `institutions_grid` |
| Container/Card | `[name]_container` | `profile_card`, `stats_container` |

## Dónde Agregar las Keys - Checklist

### Pantalla de Login (`lib/screens/login_screen.dart`)
- [ ] Campo de email: `emailField`
- [ ] Campo de contraseña: `passwordField`
- [ ] Botón de login: `loginButton`

### Pantalla de Dashboard (`lib/screens/super_admin_dashboard.dart`)
- [ ] Botón/Card de Instituciones
- [ ] Botón/Card de Usuarios Globales
- [ ] Botón de logout

### Gestión de Instituciones (`lib/screens/institutions/`)
- [ ] Search field: `searchInstitutionField`
- [ ] FAB de agregar: `addInstitutionButton`
- [ ] Campos del formulario:
  - [ ] `nombreInstitucionField`
  - [ ] `codigoInstitucionField`
  - [ ] `emailInstitucionField`
- [ ] Botón guardar: `formSaveButton`
- [ ] Botón cancelar: `cancelButton`

### Gestión de Usuarios (`lib/screens/users/`)
- [ ] Search field: `searchUserField`
- [ ] FAB de agregar: `addUserFab`
- [ ] Botón crear profesor: `addProfessorButton`
- [ ] Botón crear estudiante: `addStudentButton`
- [ ] Campos del formulario:
  - [ ] `user_form_nombres`
  - [ ] `user_form_apellidos`
  - [ ] `emailUsuarioField`
  - [ ] `user_form_telefono`
  - [ ] `user_form_identificacion`
- [ ] Botón guardar: `formSaveButton`
- [ ] Botón cancelar: `cancelButton`

### Diálogos de Confirmación
- [ ] Botón confirmar eliminar: Usar el approach de `find.byWidgetPredicate()`

## Ejemplo Completo: Agregar Keys a un Formulario

### Antes
```dart
class MyForm extends StatefulWidget {
  @override
  State<MyForm> createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Guardar'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  void _save() {
    // Guardar lógica
  }
}
```

### Después
```dart
class MyForm extends StatefulWidget {
  @override
  State<MyForm> createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          key: const Key('myForm_name_field'),
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        TextFormField(
          key: const Key('myForm_email_field'),
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        ElevatedButton(
          key: const Key('saveButton'),
          onPressed: _save,
          child: const Text('Guardar'),
        ),
        OutlinedButton(
          key: const Key('cancelButton'),
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  void _save() {
    // Guardar lógica
  }
}
```

## Cómo Verificar que las Keys Están Agregadas

1. Ejecuta el análisis de Flutter:
```bash
flutter analyze lib/
```

2. Busca por Key en los archivos:
```bash
grep -r "key: const Key" lib/screens/
```

3. Ejecuta las pruebas para verificar que funcionan:
```bash
flutter test integration_test/app_test.dart
```

## Debugging de Keys en Pruebas

Si una prueba falla porque no encuentra un widget:

```dart
// Esto te mostrará todos los widgets disponibles
find.byType(TextFormField).evaluate().forEach((element) {
  print(element.widget);
});

// O usa debugPrint
debugPrintStack();
```

## Recomendaciones Finales

1. **Consistencia**: Mantén un patrón de nombres consistente
2. **Documentación**: Comenta dónde usarás cada Key
3. **Testing**: Después de agregar una Key, crea una prueba para verificarla
4. **Actualizaciones**: Si cambias el nombre de una Key, actualiza todas las pruebas

---

Siguiendo estas instrucciones, tus pruebas E2E serán mucho más robustas y mantenibles. 🚀
