@echo off
REM Script para ejecutar la app Flutter en el dispositivo móvil

echo ======================================
echo Ejecutando AsistApp en el celular
echo ======================================
echo.

echo Verificando dispositivos conectados...
flutter devices

echo.
echo ======================================
echo.

echo Configuracion actual:
echo   IP del Backend: 192.168.20.22:3000
echo   Dispositivo: Android (2201116PG)
echo.

echo IMPORTANTE:
echo 1. Asegúrate de que el backend este corriendo
echo 2. El celular debe estar en la misma WiFi (192.168.20.x)
echo 3. El firewall debe estar configurado (puerto 3000 abierto)
echo.

set /p continuar="¿Continuar con la ejecucion? (S/N): "
if /i not "%continuar%"=="S" (
    echo.
    echo Ejecucion cancelada.
    pause
    exit /b 0
)

echo.
echo Instalando dependencias de Flutter...
flutter pub get

echo.
echo Compilando y ejecutando en el dispositivo...
echo (Esto puede tardar varios minutos)
echo.

flutter run -d 2201116PG --release

echo.
echo ======================================
echo App ejecutada en el dispositivo
echo ======================================
echo.
pause
