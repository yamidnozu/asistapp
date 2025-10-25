@echo off
REM Script para iniciar el backend con Docker

echo ======================================
echo Iniciando AsistApp Backend con Docker
echo ======================================
echo.

echo Verificando si Docker esta corriendo...
docker ps >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo ERROR: Docker Desktop no esta corriendo
    echo.
    echo Por favor:
    echo 1. Abre Docker Desktop
    echo 2. Espera a que inicie completamente
    echo 3. Ejecuta este script nuevamente
    echo.
    pause
    exit /b 1
)

echo Docker esta corriendo correctamente
echo.

echo Deteniendo contenedores previos...
docker-compose down

echo.
echo Construyendo e iniciando contenedores...
echo (Esto puede tardar unos minutos la primera vez)
echo.

docker-compose up --build -d

echo.
echo Esperando a que la base de datos este lista...
timeout /t 10 /nobreak >nul

echo.
echo Verificando estado de los contenedores...
docker-compose ps

echo.
echo ======================================
echo Backend iniciado exitosamente!
echo ======================================
echo.
echo URLs disponibles:
echo   - Local:   http://localhost:3000
echo   - Red:     http://192.168.20.22:3000
echo.
echo Para ver los logs:
echo   docker-compose logs -f
echo.
echo Para detener:
echo   docker-compose down
echo.
pause
