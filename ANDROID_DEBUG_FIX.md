# 🔧 Guía para Resolver Error de Instalación en Android

## ❌ Error Actual
```
Error: ADB exited with exit code 1
adb: failed to install ... Failure [INSTALL_FAILED_USER_RESTRICTED: Install canceled by user]
```

## ✅ Solución Paso a Paso

### 1. Verificar Configuración de Desarrollador en Android

#### En tu dispositivo Android (2201116PG):

1. **Ve a Configuración**
2. **Busca "Acerca del teléfono" o "Acerca del dispositivo"**
3. **Toca "Número de compilación" 7 veces** hasta que aparezca "Ahora eres un desarrollador"
4. **Regresa a Configuración principal**
5. **Busca "Opciones de desarrollador"** (debería aparecer ahora)

#### En Opciones de desarrollador:
- ✅ **Depuración USB**: ACTIVADO
- ✅ **Instalar apps vía USB**: ACTIVADO
- ✅ **Depuración de apps**: ACTIVADO
- ✅ **Verificar apps sobre USB**: DESACTIVADO

### 2. Autorizar el Computador

1. **Conecta tu dispositivo Android al PC**
2. **En el dispositivo, deberías ver un popup preguntando si autorizas este computador**
3. **Marca "Siempre permitir desde este computador"**
4. **Toca "Permitir"**

### 3. Verificar Conexión ADB

Ejecuta en terminal:
```bash
adb devices
```

Deberías ver algo como:
```
List of devices attached
13aee19651c4    device
```

### 4. Limpiar y Reconstruir

```bash
# En el directorio del proyecto
flutter clean
flutter pub get
```

### 5. Reiniciar Servicios

```bash
# Reiniciar ADB
adb kill-server
adb start-server

# O alternativamente:
adb reboot
```

### 6. Configuración Alternativa en VS Code

Si el problema persiste, usa la nueva configuración "Flutter (Device Ready)" que agregué a tu `launch.json`.

## 🚀 Configuraciones de Debug Disponibles

### Flutter (Device Ready)
- Específicamente configurada para tu dispositivo 2201116PG
- Incluye `--device-user 0` para evitar restricciones de usuario

### Flutter Debug (Hot Reload)
- Para desarrollo normal con hot reload

### Flutter Debug (Persistent)
- Para debugging avanzado

## � Scripts de Diagnóstico y Solución

He creado dos scripts para ayudarte:

### 1. `android_debug_diagnostic.bat`
Ejecuta este script primero para diagnosticar el problema:
- Verifica si ADB está funcionando
- Revisa el estado del dispositivo
- Muestra instrucciones específicas

### 2. `force_install_apk.bat`
Si el diagnóstico muestra que todo está bien pero aún falla:
- Limpia y reconstruye la APK
- Fuerza la instalación en el dispositivo
- Verifica que la instalación fue exitosa

## 📞 Pasos Rápidos para Resolver

1. **Ejecuta `android_debug_diagnostic.bat`** (doble click)
2. **Sigue las instrucciones que aparecen en pantalla**
3. **Si es necesario, ejecuta `force_install_apk.bat`**
4. **Reinicia VS Code**
5. **Selecciona "Flutter (Device Ready)" y presiona F5**

Si aún tienes problemas:

1. **Verifica el espacio en el dispositivo**:
   ```bash
   adb shell df
   ```

2. **Verifica permisos de la app**:
   ```bash
   adb shell pm list packages | grep -i flutter
   ```

3. **Fuerza la instalación**:
   ```bash
   adb install -r -d build/app/outputs/flutter-apk/app-debug.apk
   ```

4. **Usa un emulador** como alternativa temporal:
   ```bash
   flutter emulators --launch emulator-5554
   ```

## 📞 Si Nada Funciona

1. **Reinicia el dispositivo Android**
2. **Reinicia VS Code**
3. **Desconecta y reconecta el cable USB**
4. **Prueba con otro cable USB**
5. **Verifica que el dispositivo no esté en "Modo de solo carga"**

¿Sigues teniendo el mismo error después de seguir estos pasos?