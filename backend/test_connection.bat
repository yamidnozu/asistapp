@echo off
REM Script para probar la conexión al backend de AsistApp

echo ======================================
echo Probando conexión a AsistApp Backend
echo ======================================
echo.

echo Probando conexión LOCAL (localhost:3000)...
curl -s http://localhost:3000
if %errorLevel% equ 0 (
    echo.
    echo [OK] Conexion local exitosa
) else (
    echo.
    echo [ERROR] No se pudo conectar localmente
    echo Verifica que el backend este corriendo: npm run dev
)

echo.
echo ======================================
echo.

echo Probando conexión por RED (192.168.20.22:3000)...
curl -s http://192.168.20.22:3000
if %errorLevel% equ 0 (
    echo.
    echo [OK] Conexion por red exitosa
    echo.
    echo Tu backend es accesible desde otros dispositivos!
) else (
    echo.
    echo [ERROR] No se pudo conectar por la red
    echo.
    echo Posibles causas:
    echo 1. El firewall esta bloqueando el puerto 3000
    echo    Solucion: Ejecuta configure_firewall.bat como Administrador
    echo.
    echo 2. El backend no esta corriendo
    echo    Solucion: Ejecuta: npm run dev
    echo.
    echo 3. La IP ha cambiado
    echo    Solucion: Ejecuta: ipconfig
)

echo.
echo ======================================
echo.
pause
