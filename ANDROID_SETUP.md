# 📱 CONFIGURACIÓN PARA ACCESO DESDE ANDROID

## ✅ **CAMBIO REALIZADO:**

Modificado `lib/config/app_config.dart` para que detecte automáticamente la plataforma:

- **Web:** `http://localhost:3001`
- **Android/iOS:** `http://192.168.20.22:3002` (tu IP local)
- **Desktop:** `http://localhost:3001`

---

## 🔥 **CONFIGURAR FIREWALL DE WINDOWS**

Para que tu Android pueda conectarse al backend, necesitas abrir el puerto 3002 en el firewall de Windows:

### **Opción 1: Usando PowerShell (Recomendado)**

Ejecuta como **Administrador**:

```powershell
# Crear regla de firewall para el puerto 3002
New-NetFirewallRule -DisplayName "AsistApp Backend (Docker)" -Direction Inbound -Protocol TCP -LocalPort 3001 -Action Allow

# Verificar que se creó
Get-NetFirewallRule -DisplayName "AsistApp Backend (Docker)"
```

### **Opción 2: Interfaz Gráfica**

1. Presiona `Win + R` y escribe: `wf.msc`
2. Click en **"Reglas de entrada"** → **"Nueva regla..."**
3. Selecciona **"Puerto"** → Next
4. **TCP** → Puerto específico: **3002** → Next
5. **Permitir la conexión** → Next
6. Marca: **Dominio, Privado, Público** → Next
7. Nombre: **"AsistApp Backend"** → Finalizar

### **Opción 3: Temporalmente deshabilitar el firewall (NO RECOMENDADO)**

Solo para pruebas rápidas:
```powershell
# Deshabilitar (como Admin)
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

# Volver a habilitar después de probar
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
```

---

## 📱 **VERIFICAR CONECTIVIDAD DESDE ANDROID**

### **1. Verificar que ambos dispositivos están en la misma red:**
- PC: 192.168.20.22
- Android: debe estar en 192.168.20.X

### **2. Probar conexión desde el navegador del Android:**
Abre Chrome en tu Android y visita:
```
http://192.168.20.22:3002/health
```

**Respuesta esperada:**
```json
{
  "success": true,
  "status": "healthy",
  "timestamp": "2025-11-05T...",
  "services": {
    "server": "running"
  }
}
```

---

## 🚀 **EJECUTAR LA APP EN ANDROID**

```bash
cd /c/Proyectos/DemoLife
flutter run -d android
```

La app ahora usará automáticamente `http://192.168.20.22:3002` en lugar de `localhost`.

---

## 🔍 **DEBUGGING**

### **Si no conecta, verificar:**

1. **Docker está corriendo:**
   ```bash
   docker ps
   # Debe mostrar asistapp_backend en puerto 3002
   ```

2. **Backend responde en la red:**
   ```bash
   curl http://192.168.20.22:3002/health
   ```

3. **Android está en la misma red WiFi:**
   - Configuración → WiFi → Detalles de la red
   - La IP debe ser 192.168.20.X

4. **Puerto abierto en firewall:**
   ```powershell
   Get-NetFirewallRule -DisplayName "AsistApp*" | Get-NetFirewallPortFilter
   ```

---

## 📝 **LOGS DE DEBUGGING**

La app mostrará en la consola:
```
I/flutter: Inicializando AppConfig...
   I/flutter: URL base configurada: http://192.168.20.22:3002
```

Si ves:
```
I/flutter: Error: ClientException with SocketException: Connection refused
```

Significa que:
- El firewall está bloqueando el puerto 3001, O
- Los dispositivos no están en la misma red, O
- El backend no está corriendo

---

## 🎯 **CREDENCIALES DE PRUEBA**

Una vez conectado, usa:

**Profesor:**
```
Email: juan.perez@sanjose.edu
Password: Prof123!
```

**Estudiante:**
```
Email: santiago.mendoza@sanjose.edu
Password: Est123!
```

---

## 💡 **TIP: Si tu IP cambia**

Si tu PC obtiene una IP diferente (ej: después de reiniciar el router), necesitas:

1. Ejecutar: `get_ip.bat` para obtener la nueva IP
2. Actualizar `lib/config/app_config.dart` líneas 27 y 31
3. Ejecutar: `flutter run -d android`

O simplemente crea un archivo `.env` en la raíz del proyecto:
   ```env
   API_BASE_URL=http://192.168.20.22:3002
   ```

Y la app lo usará automáticamente sin necesidad de recompilar.

---

**¡Listo para probar! 🚀**
