# 📋 Keys Requeridas para Pruebas E2E de Aceptación

## Login Screen (`lib/screens/login_screen.dart`)
```dart
Key('login_email_field')          // Campo de email
Key('login_password_field')       // Campo de contraseña
Key('login_button')               // Botón Iniciar Sesión
```

## Navigation/Dashboard (`lib/screens/dashboard_screens/`)
```dart
Key('nav_institutions')            // Botón/Tab para Instituciones
Key('nav_users')                   // Botón/Tab para Usuarios (Super Admin)
Key('nav_users_admin')             // Botón/Tab para Usuarios (Admin Institución)
Key('nav_classes')                 // Botón/Tab para Clases (Profesor)
Key('nav_attendance')              // Botón para Tomar Asistencia (Profesor)
Key('nav_qr_code')                 // Mi Código QR (Estudiante)
Key('nav_schedule')                // Mi Horario (Estudiante)
Key('logout_button')               // Botón de logout
```

## Lists Screens (`lib/screens/institutions/`, `lib/screens/users/`)
```dart
Key('add_fab')                     // FloatingActionButton para agregar
Key('add_professor_button')        // Opción para agregar Profesor
Key('add_student_button')          // Opción para agregar Estudiante
Key('add_institution_button')      // Opción para agregar Institución
Key('edit_menu_button')            // Botón del menú más opciones (Icons.more_vert)
Key('alert_confirm_button')        // Botón Confirmar en AlertDialog
Key('alert_cancel_button')         // Botón Cancelar en AlertDialog
```

## Form Screens (`lib/screens/institutions/institution_form_screen.dart`, `lib/screens/users/user_form_screen.dart`)
```dart
Key('form_name_field')             // Campo Nombre/Razón Social
Key('form_code_field')             // Campo Código
Key('form_email_field')            // Campo Email
Key('form_phone_field')            // Campo Teléfono
Key('form_address_field')          // Campo Dirección
Key('form_identification_field')   // Campo Identificación (Estudiantes)
Key('form_responsible_field')      // Campo Responsable (Estudiantes)
Key('form_responsible_phone_field')// Campo Teléfono Responsable (Estudiantes)
Key('form_save_button')            // Botón Guardar/Actualizar
Key('form_cancel_button')          // Botón Cancelar
Key('form_role_dropdown')          // Dropdown para seleccionar Rol
```

## Institution Selection Screen (si aplica)
```dart
Key('institution_selection_screen')  // Pantalla de selección
Key('institution_radio_button_0')    // Radio button primera institución
Key('institution_radio_button_1')    // Radio button segunda institución
Key('institution_continue_button')   // Botón Continuar
```

## Messages/Alerts
```dart
Key('snackbar_message')            // SnackBar/Toast de confirmación
Key('error_message')               // SnackBar/Toast de error
```

---

**Total de Keys Necesarias:** ~35

**Implementar estas Keys de forma incremental según sea necesario durante las pruebas.**
