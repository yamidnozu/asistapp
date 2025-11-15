# 📱 GUÍA DE PRUEBA: SISTEMA DE HORARIOS

## ✅ ESTADO ACTUAL

| Componente | Status | Detalles |
|---|---|---|
| Backend | ✅ Funcional | API probada con test completo |
| Base de datos | ✅ Datos listos | 9 horarios de seed + 1 creado = 10 |
| Frontend | ✅ Corregido | Consumer agregado, listo para compilar |
| Validaciones | ✅ Funcionan | Período, grupo, materia, profesor |

## 🚀 PASOS PARA PROBAR

### Paso 1: Verificar Backend Funcionando
```bash
# El backend debe estar en puerto 3002
docker ps | grep backend

# Si no está corriendo:
docker-compose -f docker-compose.yml up -d app
```

**Expected Output:**
```
CONTAINER ID   IMAGE                COMMAND                  STATUS
c5f4ee0ec124   asistapp_backend     "docker-entrypoint.s…"   Up 12 minutes
```

### Paso 2: Verificar Base de Datos
```bash
# Conectarse a PostgreSQL
psql -h localhost -p 5433 -U postgres -d asistapp

# Ver horarios existentes
SELECT COUNT(*) FROM horarios;
# Expected: 10 (9 del seed + 1 de test)

SELECT g.nombre, m.nombre, h.dia_semana, h.hora_inicio, h.hora_fin
FROM horarios h
JOIN grupos g ON h.grupo_id = g.id
JOIN materias m ON h.materia_id = m.id
ORDER BY h.dia_semana, h.hora_inicio;
```

### Paso 3: Compilar Flutter

```bash
# Opción A: Android
flutter build apk --release

# Opción B: Solo desarrollo
flutter pub get
flutter analyze  # ✅ Ya verificado, pasa sin errores

# Opción C: Con hot reload (desarrollo)
flutter run
```

### Paso 4: Instalar en Dispositivo

```bash
# Si usaste --release
adb install build/app/outputs/flutter-apk/app-release.apk

# Si es desarrollo
flutter install
```

### Paso 5: Probar en la Aplicación

#### 5.1 - Login como Administrador
```
Email: admin@sanjose.edu
Contraseña: SanJose123!
```
✅ Debe ingresar y mostrar dashboard

#### 5.2 - Navegar a Gestión de Horarios
```
Menú → Gestion Académica → Horarios
```
✅ Debe cargar la pantalla de gestión

#### 5.3 - Seleccionar Período
```
Dropdown: "Seleccionar Período Académico"
Opción: "Año Lectivo 2025"
```
✅ Dropdown de grupos debe habilitarse

#### 5.4 - Seleccionar Grupo
```
Dropdown: "Seleccionar Grupo"
Opción: "Grupo 10-A - 10"
```
✅ **IMPORTANTE:** Debe mostrar el calendario con horarios

**Horarios esperados para Grupo 10-A:**
```
Lunes:    08:00-10:00 Cálculo (Juan Pérez)
Lunes:    10:30-11:30 Física (Laura Gómez)
Martes:   08:00-09:00 Español (Juan Pérez)
Martes:   09:00-10:00 Inglés (Laura Gómez)
Miércoles: 08:00-10:00 Física (Laura Gómez)
Jueves:   08:00-09:00 Cálculo (Juan Pérez)
Jueves:   09:00-10:00 Español (Juan Pérez)
Viernes:  08:00-09:00 Inglés (Laura Gómez)
```

#### 5.5 - Crear Nuevo Horario
```
1. Hacer clic en celda vacía (ej: Lunes 06:00)
2. Se abre diálogo "Crear Clase"
3. Completar:
   - Materia: "Cálculo"
   - Hora Fin: "07:00"
   - Profesor: "Juan Pérez" (o dejarlo vacío)
4. Clic en "Crear"
```

✅ **ESPERADO:**
- ✅ Diálogo cierra
- ✅ Aparece SnackBar: "Clase creada correctamente"
- ✅ Horario aparece inmediatamente en el calendario en Lunes 06:00-07:00

#### 5.6 - Editar Horario Existente
```
1. Hacer clic en una clase existente (ej: Lunes 08:00 Cálculo)
2. Se abre diálogo "Editar Clase"
3. Pueden cambiar materia, hora, profesor
4. Clic en "Actualizar"
```

✅ **ESPERADO:** Cambios reflejados inmediatamente en el calendario

#### 5.7 - Eliminar Horario
```
1. Hacer clic en una clase
2. Clic en botón "Eliminar"
3. Confirmar
```

✅ **ESPERADO:** 
- ✅ Horario desaparece del calendario
- ✅ Se elimina de la base de datos

### Paso 6: Prueba de Conflictos

```
1. Con Grupo 10-A seleccionado
2. Intentar crear horario en Lunes 08:00-09:00
   (ya existe Cálculo 08:00-10:00)
3. Resultado esperado: 
   ❌ Error: "El grupo ya tiene una clase programada en este horario"
```

### Paso 7: Cambiar de Grupo

```
1. Dropdown Grupo: seleccionar "Grupo 11-B"
2. Calendarios debe cambiar para mostrar los horarios de 11-B
3. Debería mostrar solo:
   - Lunes: 08:00-09:00 Cálculo (Juan Pérez)
```

✅ **ESPERADO:** Calendar se actualiza automáticamente

## 🧪 PRUEBA API DIRECTA (Curl)

Si quieres probar sin la UI:

### Login
```bash
curl -X POST http://localhost:3002/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@sanjose.edu",
    "password": "SanJose123!"
  }'
```

**Response:**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJ...",
    "usuario": {
      "id": "139158e1-8aca-4b21-99f8-a830646f7c0a"
    }
  }
}
```

### Obtener Horarios
```bash
curl -X GET http://localhost:3002/horarios \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Crear Horario
```bash
curl -X POST http://localhost:3002/horarios \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "periodoId": "88d2bea7-f0c9-40db-bc3c-001a332fde90",
    "grupoId": "62f3414a-d7da-4fe2-8ea8-46d59ef299b4",
    "materiaId": "8348bcca-faba-4a2a-bca3-f1569c9f2799",
    "profesorId": "bec716d0-ad67-441f-9853-ceb4263a2b71",
    "diaSemana": 1,
    "horaInicio": "05:00",
    "horaFin": "06:00"
  }'
```

## ⚠️ PROBLEMAS POSIBLES Y SOLUCIONES

### Problema: Calendario vacío después de seleccionar grupo
```
Causa: El _buildWeeklyCalendar() no está en Consumer
Solución: ✅ YA CORREGIDO en horarios_screen.dart
```

### Problema: No se puede crear horario
```
Causa: Error de validación (IDs inválidos, conflicto)
Solución: Verificar logs del backend:
  docker logs backend-app-v3 -f
```

### Problema: Profesor no encontrado
```
Causa: El profesor no pertenece a la institución del admin
Solución: Seleccionar profesor correcto:
  - San José: Juan Pérez, Laura Gómez
  - Santander: Carlos Díaz
```

### Problema: La app no se compila
```
Causa: Posible error en horarios_screen.dart
Solución: 
  flutter analyze  # Verificar errores
  flutter clean && flutter pub get  # Limpiar
  flutter run  # Reintentar
```

## 📊 CHECKLIST DE VALIDACIÓN

### Backend ✅
- [ ] Docker backend corriendo en puerto 3002
- [ ] Database con 10 horarios
- [ ] API responde con status 200 para GET /horarios
- [ ] POST /horarios crea nuevo horario (status 201)

### Frontend ✅
- [ ] Flutter analyze sin errores
- [ ] App se compila sin problemas
- [ ] Login funciona
- [ ] Calendario se muestra con horarios
- [ ] Puede crear nuevos horarios
- [ ] Puede editar horarios
- [ ] Puede eliminar horarios
- [ ] Cambio de grupo actualiza el calendario

### Datos ✅
- [ ] Base de datos con datos de seed
- [ ] Períodos académicos activos
- [ ] Grupos con estudiantes
- [ ] Materias en la institución
- [ ] Profesores asignados a institución
- [ ] Horarios sin conflictos

## 🎉 RESULTADO ESPERADO

Cuando todo esté funcionando correctamente:

```
┌────────────────────────────────────────────────┐
│     GESTIÓN DE HORARIOS - GRUPO 10-A           │
├────────────────────────────────────────────────┤
│        Lunes  Martes  Miérc  Jueves  Viernes  │
├────────────────────────────────────────────────┤
│ 06:00  [+]    [+]     [+]    [+]     [+]      │
│ 07:00  [Cálc] [+]     [+]    [+]     [Inglés]│
│ 08:00  [ulco] [Españ] [Físi] [Cálc] [+]      │
│ 09:00  [Juan] [+]     [ca]   [ulo]  [+]      │
│ 10:00  [+]    [Inglé] [+]    [Españ][+]      │
│ 10:30  [Física]       [+]    [+]     [+]      │
│ 11:00  [+]    [+]     [+]    [+]     [+]      │
│ 11:30  [+]    [+]     [+]    [+]     [+]      │
└────────────────────────────────────────────────┘

✅ Todos los horarios visibles
✅ Se puede crear, editar, eliminar
✅ Cambios se reflejan en tiempo real
```

---

**¡Listo para probar! 🚀**

Si encuentras cualquier problema, revisa los logs:
```bash
# Backend
docker logs backend-app-v3 -f

# Frontend (si usas hot reload)
flutter logs
```
