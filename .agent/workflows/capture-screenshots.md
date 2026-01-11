---
description: Capturar screenshots para documentación del manual de usuario
---

# Captura de Screenshots para Documentación

Este workflow genera automáticamente las imágenes para el manual de usuario ejecutando tests E2E en el emulador Android.

## Requisitos Previos

1. **Emulador Android** corriendo (ID: emulator-5554)
2. **Backend** iniciado en localhost:3000
3. **Base de datos** con el seed ejecutado (`npm run seed` en backend)

## Ejecutar Captura de Screenshots

// turbo
```bash
cd /c/Proyectos/DemoLife && flutter test integration_test/screenshot_docs_test.dart -d emulator-5554 -r expanded --no-pub
```

## Screenshots Generados

Las imágenes se guardan en `docs/images/` con los siguientes nombres:

### Pantallas Generales
- `login_screen.png` - Pantalla de inicio de sesión
- `settings_screen.png` - Pantalla de ajustes

### Super Administrador
- `super_admin_dashboard.png` - Dashboard principal
- `institutions_list.png` - Lista de instituciones
- `institution_form.png` - Formulario de crear institución
- `users_list_superadmin.png` - Lista de usuarios

### Administrador de Institución
- `admin_dashboard.png` - Dashboard principal
- `users_list_admin.png` - Lista de usuarios
- `grupos_list.png` - Lista de grupos
- `grupo_detail.png` - Detalle de un grupo
- `horarios_screen.png` - Gestión de horarios
- `materias_list.png` - Lista de materias

### Profesor
- `teacher_dashboard.png` - Dashboard con clases del día
- `attendance_screen.png` - Pantalla de toma de asistencia

### Estudiante
- `student_dashboard.png` - Dashboard del estudiante
- `my_qr_code.png` - Código QR personal
- `student_schedule.png` - Horario semanal
- `student_attendance.png` - Historial de asistencia

### Acudiente (Padre/Tutor)
- `acudiente_dashboard.png` - Dashboard con resumen de hijos
- `estudiante_detail.png` - Detalle del estudiante
- `notificaciones_screen.png` - Centro de notificaciones

## Credenciales de Prueba Usadas

| Rol | Email | Contraseña |
|-----|-------|------------|
| Super Admin | superadmin@asistapp.com | Admin123! |
| Admin Institución | admin@sanjose.edu | SanJose123! |
| Profesor | juan.perez@sanjose.edu | Prof123! |
| Estudiante | santiago.mendoza@sanjose.edu | Est123! |
| Acudiente | maria.mendoza@email.com | Acu123! |

## Después de Ejecutar

1. **Revisar las imágenes** en `docs/images/`
2. **Actualizar la GUIA_RAPIDA_USUARIO.md** reemplazando los comentarios de placeholder con las referencias a las imágenes reales:
   
   ```markdown
   <!-- Antes -->
   <!-- IMAGEN: login_screen.png ... -->
   
   <!-- Después -->
   ![Pantalla de Login](images/login_screen.png)
   ```

3. **Opcional**: Ejecutar el test E2E principal para más capturas específicas:
   ```bash
   flutter test integration_test/main_e2e_test.dart -d emulator-5554 -r expanded --no-pub
   ```

## Troubleshooting

### El emulador no responde
```bash
adb kill-server && adb start-server
```

### Las imágenes salen en negro
Asegúrese de que el emulador esté visible en pantalla y no minimizado.

### Error de conexión al backend
Verifique que el backend esté corriendo:
```bash
cd backend && npm run dev
```

### Los tests fallan en login
Verifique que el seed esté aplicado:
```bash
cd backend && npm run seed
```
