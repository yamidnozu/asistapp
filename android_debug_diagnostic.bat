@echo off
echo ========================================
echo  DIAGNOSTICO DE DISPOSITIVO ANDROID
echo ========================================

echo.
echo 1. Verificando dispositivos conectados...
echo.

cd /d "C:\Users\%USERNAME%\AppData\Local\Android\Sdk\platform-tools"
if exist adb.exe (
    adb devices
) else (
    echo ERROR: ADB no encontrado en la ruta esperada
    echo Verifica que Android SDK esté instalado correctamente
    goto :end
)

echo.
echo 2. Verificando estado del dispositivo...
echo.

adb shell getprop ro.product.model
adb shell getprop ro.build.version.release

echo.
echo 3. Verificando permisos de desarrollador...
echo.

adb shell settings get global development_settings_enabled
adb shell settings get global adb_enabled

echo.
echo 4. Verificando espacio disponible...
echo.

adb shell df /data

echo.
echo ========================================
echo  INSTRUCCIONES PARA SOLUCIONAR
echo ========================================
echo.
echo SI VES "device" en la lista de dispositivos, continua:
echo.
echo 1. En tu telefono Android:
echo    - Ve a Configuracion
echo    - Busca "Opciones de desarrollador"
echo    - Activa "Depuracion USB"
echo    - Activa "Instalar apps via USB"
echo.
echo 2. Autoriza este computador cuando aparezca el popup
echo.
echo 3. Si el problema persiste, ejecuta:
echo    adb kill-server
echo    adb start-server
echo.
echo 4. Reinicia VS Code y prueba nuevamente
echo.

:end
pause