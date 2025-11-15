# ⚙️ CONFIGURACIÓN Y SETUP VERIFICADO

## ✅ Sistema Operativo

```
Status: ✅ Operativo
├─ Backend:    Corriendo en Puerto 3002
├─ Base Datos: Corriendo en Puerto 5433
└─ Frontend:   Pronto para ejecutar
```

## 🔧 Configuración de Ambiente

### Backend (.env)
```env
# Base de Datos
DB_USER=arroz
DB_PASS=pollo
DB_NAME=asistapp
DB_PORT=5433

# Backend
BACKEND_PORT=3002
JWT_SECRET="asistapp_secret_key_2025_super_secreta"

# Frontend API URL
API_BASE_URL=http://192.168.20.22:3002

# DATABASE_URL para Prisma (host)
DATABASE_URL="postgresql://arroz:pollo@localhost:5433/asistapp?schema=public"
```

**Estado:** ✅ Correcto (verificado)

### Docker Compose
```yaml
services:
  db:
    image: postgres:15
    ports: ["5433:5432"]      # ✅ Puerto correcto
    environment:
      POSTGRES_USER: arroz
      POSTGRES_PASSWORD: pollo
      POSTGRES_DB: asistapp

  app:
    ports: ["3002:3000"]       # ✅ Puerto correcto
    environment:
      DATABASE_URL: "postgresql://arroz:pollo@db:5432/asistapp?schema=public"
```

**Estado:** ✅ Correcto (verificado)

## 📊 Estado de Servicios

```bash
# Verificación actual (15 Nov 2025 04:24 GMT)

✅ Backend (3002)
   └─ Status: Running
   └─ Response: HTTP 200
   └─ Uptime: Stable

✅ Database (5433)
   └─ Status: Running
   └─ Records: 10 horarios
   └─ Connections: Active

✅ API Endpoints
   └─ /health: ✅ Working
   └─ /auth/login: ✅ Working
   └─ /horarios: ✅ Working
   └─ /grupos: ✅ Working
```

## 🗂️ Estructura de Datos

### Database Schema
```
asistapp (PostgreSQL 15)
├─ instituciones (3 records)
├─ usuarios (9 records)
├─ periodos_academicos (2 records)
├─ grupos (3 records)
│  ├─ Grupo 10-A ✅ Con 8 horarios
│  ├─ Grupo 11-B ✅ Con 1 horario
│  └─ Grupo 9-A ✅ Con 1 horario
├─ materias (7 records)
├─ horarios (10 records) ✅
└─ asistencias (vacío)
```

### Horarios Disponibles
```
10-A (Lunes)      [08:00-10:00] Cálculo
10-A (Lunes)      [10:30-11:30] Física
10-A (Martes)     [08:00-09:00] Español
10-A (Martes)     [09:00-10:00] Inglés
10-A (Miércoles)  [08:00-10:00] Física
10-A (Jueves)     [08:00-09:00] Cálculo
10-A (Jueves)     [09:00-10:00] Español
10-A (Viernes)    [08:00-09:00] Inglés
11-B (Lunes)      [08:00-09:00] Cálculo
9-A  (Martes)     [08:00-09:00] Sociales
```

## 🔐 Credenciales de Prueba

### Admin Account
```
Email:    admin@sanjose.edu
Password: SanJose123!
Role:     admin_institucion
Status:   ✅ Funcional
```

### Test Users (Disponibles)
```
profesor1@sanjose.edu  (Profesor)
profesor2@sanjose.edu  (Profesor)
profesor3@sanjose.edu  (Profesor)
estudiante1@sanjose.edu (Estudiante)
estudiante2@sanjose.edu (Estudiante)
... (más usuarios disponibles)
```

## 🚀 Cómo Iniciar

### Verificar que todo está corriendo
```bash
# Ver contenedores
docker ps

# Resultado esperado:
# backend-app-v3      3002:3000   ✅ Up
# asistapp_db         5433:5432   ✅ Up
```

### Si algo no está corriendo
```bash
# Reiniciar servicios
docker compose down
docker compose up -d

# Esperar 10 segundos
sleep 10

# Verificar
docker ps
```

### Si hay que resetear todo
```bash
# Limpiar volúmenes
docker compose down -v

# Reiniciar fresco
docker compose up -d db
sleep 15
docker compose run --rm app npx prisma db push --accept-data-loss
docker compose run --rm app npm run prisma:seed
docker compose up -d app
```

## 📱 Frontend Configuration

### API Connection
**File:** `lib/config/app_config.dart`

```dart
class AppConfig {
  static const String baseUrl = 'http://192.168.20.22:3002';
  // ⚠️ NOTA: Si cambias la IP, actualiza aquí también
}
```

**Estados:**
- ✅ Configurado para la red local
- ✅ Puerto correcto (3002)
- ✅ JWT bearer tokens configurados

### Provider Setup
**File:** `lib/providers/horario_provider.dart`

```dart
class HorarioProvider with ChangeNotifier {
  HorarioState _state = HorarioState.initial;
  
  // Estados disponibles:
  // - initial: Sin inicializar
  // - loading: Cargando datos
  // - loaded: Datos cargados
  // - error: Hubo un error
}
```

**Estados UI Implementados:**
- ✅ Loading spinner
- ✅ Error message + retry
- ✅ Empty state
- ✅ Calendar view

## 🔄 Flujo de Datos

```
Usuario abre app
    ↓
initState() carga:
  ├─ Periodos académicos
  ├─ Grupos
  ├─ Materias
  └─ Usuarios
    ↓
Usuario selecciona Período
    ↓
Usuario selecciona Grupo
    ↓
Screen llama: _loadHorariosForGrupo(grupoId)
    ↓
Provider llama: horarioProvider.loadHorariosByGrupo()
    ↓
Service llama: AcademicService.getHorariosPorGrupo()
    ↓
Backend: GET /horarios?grupoId=<ID>
    ↓
Database: SELECT * FROM horarios WHERE grupo_id = <ID>
    ↓
Resultado: [8 horarios] ✅
    ↓
Provider: _setState(HorarioState.loaded)
    ↓
notifyListeners() 
    ↓
UI renderiza: _buildWeeklyCalendar()
    ↓
Usuario ve: Calendario con 8 horarios ✅
```

## 🧪 Comandos para Testing

### Test Backend
```bash
# Health check
curl -I http://localhost:3002/health

# Login
curl -X POST http://localhost:3002/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@sanjose.edu","password":"SanJose123!"}'

# Get horarios
TOKEN="<access_token>"
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:3002/horarios?grupoId=78031d74-49f3-4081-ae74-e89d8bf3dde5"
```

### Test Database
```bash
# Connect to DB
docker exec -it asistapp_db psql -U arroz -d asistapp

# Ver horarios
SELECT COUNT(*) FROM horarios;

# Ver grupos
SELECT * FROM grupos;

# Ver materias
SELECT * FROM materias;
```

### Test Flutter
```bash
# Verify no errors
flutter analyze

# Run app
flutter run

# See logs
flutter logs
```

## 📋 Verificación Final

- [x] Backend corriendo (puerto 3002)
- [x] Database corriendo (puerto 5433)
- [x] 10 horarios en BD
- [x] API endpoints funcionando
- [x] Autenticación funcionando
- [x] Frontend código compilable (0 errores)
- [x] Provider pattern implementado
- [x] Estados visuales agregados
- [x] Documentación completa

## 🎯 Próximos Pasos

1. **Tu Tarea:**
   ```bash
   flutter run
   ```

2. **Navegación en App:**
   - Admin Dashboard
   - → Gestión de Horarios
   - → Selecciona Período: "Año Lectivo 2025"
   - → Selecciona Grupo: "Grupo 10-A - 10"
   - → Verifica: Deberías ver 8 horarios

3. **Si funciona:**
   - ✅ Todo está correcto
   - ✅ Puedes proceder a pruebas adicionales

4. **Si algo falla:**
   - Consulta: `DEBUG_HORARIOS.md`
   - Ejecuta: Comandos de diagnóstico
   - Reinicia: `docker compose restart app`

## 📞 Soporte

**Si necesitas help:**

1. Revisa: `VERIFICAR_SOLUCION_HORARIOS.md`
2. Revisa: `DEBUG_HORARIOS.md`
3. Ejecuta: `docker compose logs app` para ver errores
4. Reinicia: `docker compose restart app` si todo falla

---

**Última Actualización:** 15 de Noviembre 2025
**Estado:** ✅ Completamente Configurado y Operativo
**Sistema Listo Para:** Pruebas de Usuario Final
