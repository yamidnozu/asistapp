@echo off
echo ========================================
echo  FORZANDO INSTALACION DE APK
echo ========================================

echo.
echo Este script intentara instalar la APK forzadamente
echo.

cd /d "C:\Proyectos\DemoLife"

echo 1. Limpiando build anterior...
flutter clean

echo.
echo 2. Construyendo APK...
flutter build apk --debug

echo.
echo 3. Intentando instalacion forzada...
echo.

cd /d "C:\Users\%USERNAME%\AppData\Local\Android\Sdk\platform-tools"

if exist adb.exe (
    echo Desinstalando app anterior (si existe)...
    adb uninstall com.chronolife.demolife

    echo.
    echo Instalando APK forzadamente...
    adb install -r -d -g "C:\Proyectos\DemoLife\build\app\outputs\flutter-apk\app-debug.apk"

    echo.
    echo Verificando instalacion...
    adb shell pm list packages | findstr chronolife
) else (
    echo ERROR: ADB no encontrado
    echo Ejecuta primero el script de diagnostico
)

echo.
echo ========================================
echo  RESULTADO
echo ========================================
echo.
echo Si la instalacion fue exitosa, ahora puedes:
echo 1. Cerrar VS Code completamente
echo 2. Abrir VS Code nuevamente
echo 3. Seleccionar "Flutter (Device Ready)" en debug
echo 4. Presionar F5 para iniciar
echo.

pause