# Guía de Acceso por Red Local

Esta guía explica cómo configurar el backend para que sea accesible desde otros dispositivos en la misma red local.

## 📋 Configuración Actual

- **IP Local del Servidor**: `192.168.20.22`
- **Puerto del Backend**: `3000`
- **URL de Acceso**: `http://192.168.20.22:3000`

## ✅ Cambios Realizados

### 1. Backend - CORS Habilitado
Se agregó soporte CORS para permitir conexiones desde cualquier origen:
- Instalado `@fastify/cors`
- Configurado para aceptar todas las peticiones
- Headers permitidos: `Content-Type`, `Authorization`
- Métodos permitidos: `GET`, `POST`, `PUT`, `DELETE`, `PATCH`, `OPTIONS`

### 2. Backend - Host 0.0.0.0
El servidor está configurado para escuchar en todas las interfaces de red:
```typescript
host: '0.0.0.0'  // Acepta conexiones de cualquier IP
```

### 3. Flutter App - Detección de IP
La aplicación Flutter ya está configurada para usar la IP `192.168.20.22`:
```dart
return '192.168.20.22';  // lib/services/auth_service.dart
```

## 🔥 Configurar Firewall de Windows

Para que otros dispositivos puedan acceder al backend, debes abrir el puerto 3000 en el Firewall de Windows:

### Opción 1: Comando PowerShell (Recomendado)
Ejecuta estos comandos en PowerShell como **Administrador**:

```powershell
# Regla de entrada (permite conexiones entrantes)
New-NetFirewallRule -DisplayName "AsistApp Backend" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow

# Regla de salida (permite respuestas)
New-NetFirewallRule -DisplayName "AsistApp Backend Out" -Direction Outbound -LocalPort 3000 -Protocol TCP -Action Allow
```

### Opción 2: Interfaz Gráfica

1. Abre **Windows Defender Firewall con seguridad avanzada**
   - Presiona `Win + R`
   - Escribe: `wf.msc`
   - Presiona Enter

2. **Regla de entrada**:
   - Click en "Reglas de entrada" → "Nueva regla..."
   - Tipo: Puerto → Siguiente
   - TCP, Puerto local: `3000` → Siguiente
   - Acción: "Permitir la conexión" → Siguiente
   - Aplicar a: Todos (Dominio, Privado, Público) → Siguiente
   - Nombre: `AsistApp Backend` → Finalizar

3. **Regla de salida** (opcional pero recomendado):
   - Repetir los mismos pasos en "Reglas de salida"

## 🧪 Probar la Conexión

### Desde el mismo PC (localhost)
```bash
curl http://localhost:3000
```

### Desde otro dispositivo en la red
```bash
curl http://192.168.20.22:3000
```

### Respuesta esperada:
```json
{
  "success": true,
  "message": "Hola Mundo desde AsistApp Backend v2.0!",
  "timestamp": "2025-10-24T..."
}
```

### Probar Login desde otro dispositivo:
```bash
curl -X POST http://192.168.20.22:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@asistapp.com","password":"admin123"}'
```

## 📱 Configurar IP en la App Flutter

Si necesitas cambiar la IP (por ejemplo, si tu router te asigna otra IP):

1. Abre `lib/services/auth_service.dart`
2. Busca la línea:
   ```dart
   return '192.168.20.22';
   ```
3. Cambia por tu nueva IP local
4. Reinicia la app

### Obtener tu IP actual:
```bash
ipconfig | grep "IPv4"
```

## 🚀 Iniciar el Backend

```bash
cd backend
npm run dev
```

Deberías ver:
```
✅ Servidor corriendo en:
   - Local:   http://localhost:3000
   - Red:     http://192.168.20.22:3000
🎯 API lista para recibir conexiones
```

## 🐛 Solución de Problemas

### Error: "Credenciales incorrectas"

**Verifica que el backend esté iniciado correctamente:**
```bash
curl http://192.168.20.22:3000
```

**Verifica las credenciales de prueba:**
- Email: `admin@asistapp.com`
- Password: `admin123`

### Error: "Connection refused" o timeout

1. **Verifica que el backend esté corriendo**
2. **Verifica el firewall** (pasos arriba)
3. **Verifica que ambos dispositivos estén en la misma red**
   ```bash
   ipconfig
   ```
   Ambos deben tener IPs en el mismo rango (ej: 192.168.20.x)

### Error: "Network unreachable"

1. **Desactiva VPN temporalmente** (Cloudflare WARP puede interferir)
2. **Verifica que el dispositivo móvil esté en WiFi** (no en datos móviles)
3. **Reinicia el router** si es necesario

### El backend funciona en localhost pero no en la red

1. **Verifica el host en `backend/.env`:**
   ```
   HOST=0.0.0.0
   ```

2. **Verifica la configuración de Docker** (si usas Docker):
   ```yaml
   ports:
     - "3000:3000"
   ```

3. **Prueba con otra IP** si tienes múltiples adaptadores:
   ```bash
   ipconfig
   ```

## 📌 Notas Importantes

- La IP `192.168.20.22` puede cambiar si:
  - Reinicias el router
  - Cambias de red WiFi
  - Tu router tiene DHCP dinámico

- **Solución**: Configura una IP estática en tu router o PC

- Si usas Docker, asegúrate de que los puertos estén correctamente mapeados

## 🔒 Seguridad

Para producción, deberías:
- Cambiar el `JWT_SECRET` en las variables de entorno
- Configurar CORS para permitir solo dominios específicos
- Usar HTTPS con certificados SSL
- Implementar rate limiting más estricto
- Usar una base de datos segura con contraseñas fuertes

## 📝 Credenciales de Prueba

Usuario administrador (creado automáticamente):
- **Email**: `admin@asistapp.com`
- **Password**: `admin123`

⚠️ **IMPORTANTE**: Cambia estas credenciales en producción.
