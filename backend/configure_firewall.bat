@echo off
REM Script para configurar el Firewall de Windows para AsistApp Backend
REM Ejecutar como Administrador

echo ======================================
echo Configurando Firewall para AsistApp
echo ======================================
echo.

REM Verificar si se ejecuta como administrador
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Este script debe ejecutarse como Administrador
    echo.
    echo Haz click derecho sobre el archivo y selecciona "Ejecutar como administrador"
    pause
    exit /b 1
)

echo Creando regla de entrada (permite conexiones al puerto 3000)...
netsh advfirewall firewall add rule name="AsistApp Backend" dir=in action=allow protocol=TCP localport=3000

echo.
echo Creando regla de salida (permite respuestas desde el puerto 3000)...
netsh advfirewall firewall add rule name="AsistApp Backend Out" dir=out action=allow protocol=TCP localport=3000

echo.
echo ======================================
echo Configuracion completada exitosamente!
echo ======================================
echo.
echo El puerto 3000 esta ahora abierto en el Firewall de Windows.
echo Puedes acceder al backend desde otros dispositivos en la red usando:
echo http://192.168.20.22:3000
echo.
pause
