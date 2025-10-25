# 🚀 Guía de Ejecución - Backend Docker + App Flutter en Celular

## ✅ Estado Actual del Sistema

```
✅ Docker Desktop iniciado
✅ Backend corriendo en contenedores Docker
✅ PostgreSQL funcionando (puerto 5432)
✅ Backend API funcionando (puerto 3000)
✅ CORS habilitado
✅ Dispositivo Android conectado: 2201116PG

URLs disponibles:
  - Local:   http://localhost:3000
  - Red:     http://192.168.20.22:3000
```

## 📱 Pasos para Ejecutar en el Celular

### 1. Verificar que todo esté listo

✅ **Backend con Docker:**
```bash
cd backend
docker-compose ps
```

Deberías ver 2 contenedores corriendo:
- `backend-app-1` (puerto 3000)
- `backend-db-1` (puerto 5432)

✅ **Probar conexión por red:**
```bash
curl http://192.168.20.22:3000
```

O abre en el navegador: `http://192.168.20.22:3000`

### 2. Configurar el Firewall (SI NO LO HICISTE)

**Ejecuta como Administrador:**
```bash
backend/configure_firewall.bat
```

O manualmente:
```powershell
New-NetFirewallRule -DisplayName "AsistApp Backend" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow
```

### 3. Verificar la WiFi del Celular

⚠️ **IMPORTANTE:** Tu celular DEBE estar conectado a la misma WiFi que este PC.

- PC está en: `192.168.20.22`
- Red WiFi: `192.168.20.x`
- El celular debe tener una IP como: `192.168.20.xxx`

### 4. Ejecutar la App en el Celular

**Opción A - Script Automático:**
```bash
run_on_device.bat
```

**Opción B - Manual:**
```bash
# Instalar dependencias
flutter pub get

# Ejecutar en modo release en el dispositivo
flutter run -d 2201116PG --release
```

**Opción C - Modo Debug (más rápido para desarrollo):**
```bash
flutter run -d 2201116PG
```

### 5. Probar el Login

Una vez que la app esté instalada en el celular:

1. Abre la aplicación
2. Ingresa las credenciales:
   - **Email:** `admin@asistapp.com`
   - **Password:** `admin123`
3. Presiona "Iniciar Sesión"

## 🔧 Comandos Útiles

### Backend (Docker)

```bash
# Ver estado de contenedores
docker-compose ps

# Ver logs en tiempo real
docker-compose logs -f

# Ver solo logs de la app
docker-compose logs -f app

# Detener todo
docker-compose down

# Reiniciar todo
docker-compose restart

# Reconstruir e iniciar
docker-compose up --build -d
```

### Flutter

```bash
# Ver dispositivos conectados
flutter devices

# Instalar dependencias
flutter pub get

# Limpiar caché
flutter clean

# Compilar para Android (Release)
flutter build apk --release

# Ejecutar en dispositivo específico
flutter run -d 2201116PG

# Ejecutar en modo release
flutter run -d 2201116PG --release

# Ver logs de la app
flutter logs -d 2201116PG
```

### Conexión y Red

```bash
# Ver tu IP actual
ipconfig

# Probar conexión local
curl http://localhost:3000

# Probar conexión por red
curl http://192.168.20.22:3000

# Probar login
curl -X POST http://192.168.20.22:3000/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"admin@asistapp.com\",\"password\":\"admin123\"}"

# Ver procesos usando el puerto 3000
netstat -ano | grep :3000

# Verificar firewall
netsh advfirewall firewall show rule name="AsistApp Backend"
```

## 🐛 Solución de Problemas

### ❌ Error: "Connection refused" en la app

**Causa:** El celular no puede conectarse al backend

**Soluciones:**
1. Verifica que el backend esté corriendo:
   ```bash
   docker-compose ps
   curl http://192.168.20.22:3000
   ```

2. Configura el firewall:
   ```bash
   backend/configure_firewall.bat
   ```

3. Verifica que el celular esté en la misma WiFi
4. Prueba abrir en el navegador del celular: `http://192.168.20.22:3000`

### ❌ Docker no inicia

**Solución:**
1. Abre Docker Desktop manualmente
2. Espera a que esté completamente iniciado
3. Ejecuta: `backend/start_docker.bat`

### ❌ Dispositivo no detectado

**Solución:**
1. Verifica que el cable USB funcione
2. Activa "Depuración USB" en el celular
3. Acepta la autorización en el celular
4. Ejecuta: `flutter devices`

### ❌ La IP ha cambiado

Si tu IP cambia (después de reiniciar el router):

1. Obtén la nueva IP:
   ```bash
   ipconfig
   ```

2. Actualiza en Flutter:
   ```dart
   // lib/services/auth_service.dart
   return '192.168.20.22'; // Cambia por tu nueva IP
   ```

3. Reinicia Docker si es necesario

### ❌ Error al compilar Flutter

**Solución:**
```bash
cd c:/Proyectos/DemoLife
flutter clean
flutter pub get
flutter run -d 2201116PG
```

### ❌ "Credenciales incorrectas"

**Verifica:**
1. Que el backend esté accesible:
   ```bash
   curl http://192.168.20.22:3000
   ```

2. Las credenciales sean correctas:
   - Email: `admin@asistapp.com`
   - Password: `admin123`

3. Los logs del backend:
   ```bash
   docker-compose logs -f app
   ```

## 📊 Arquitectura del Sistema

```
┌─────────────────┐
│  Celular        │
│  192.168.20.xxx │
│  (Flutter App)  │
└────────┬────────┘
         │ WiFi
         │ HTTP Request
         ▼
┌─────────────────┐
│  PC             │
│  192.168.20.22  │
│                 │
│  ┌───────────┐  │
│  │  Docker   │  │
│  │  Compose  │  │
│  │           │  │
│  │ ┌───────┐ │  │
│  │ │Backend│ │  │ :3000
│  │ │  API  │ │  │
│  │ └───┬───┘ │  │
│  │     │     │  │
│  │ ┌───▼───┐ │  │
│  │ │Postgre│ │  │ :5432
│  │ │  SQL  │ │  │
│  │ └───────┘ │  │
│  └───────────┘  │
└─────────────────┘
```

## 📝 Checklist Pre-Ejecución

Antes de ejecutar la app, verifica:

- [ ] Docker Desktop está corriendo
- [ ] Backend está activo (docker-compose ps)
- [ ] Firewall configurado (puerto 3000 abierto)
- [ ] PC y celular en la misma WiFi (192.168.20.x)
- [ ] Backend accesible desde el navegador: http://192.168.20.22:3000
- [ ] Dispositivo Android conectado (flutter devices)
- [ ] Depuración USB activada en el celular

## 🎯 Scripts Disponibles

### Backend:
- `backend/start_docker.bat` - Inicia Docker Compose
- `backend/configure_firewall.bat` - Configura firewall
- `backend/test_connection.bat` - Prueba conexión

### Flutter:
- `run_on_device.bat` - Ejecuta app en celular

## 📚 Documentos de Referencia

- `START_HERE.md` - Guía de inicio rápido
- `NETWORK_ACCESS_GUIDE.md` - Guía completa de red local
- `NETWORK_SETUP_SUMMARY.md` - Resumen técnico
- `backend/README.md` - Documentación del backend

## 🔐 Credenciales

**Usuario Administrador:**
- Email: `admin@asistapp.com`
- Password: `admin123`

**Base de Datos (PostgreSQL):**
- Usuario: `arroz`
- Password: `pollo`
- Base de datos: `asistapp`

---

**¡Todo listo para ejecutar la app en tu celular!** 🎉

**Siguiente paso:** Ejecuta `run_on_device.bat` o usa `flutter run -d 2201116PG`
