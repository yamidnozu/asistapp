@echo off
REM reset-db.bat
REM Script de conveniencia (Windows .bat) para reiniciar la BD, aplicar schema Prisma y ejecutar el seed.
REM Uso:
REM   scripts\reset-db.bat           -> usa seed dentro del contenedor
REM   scripts\reset-db.bat host      -> intenta ejecutar el seed en el host (backend\npm run prisma:seed:host)

setlocal enabledelayedexpansion

set "LOGFILE=%~dp0reset-db.log"
echo ----- Reset DB run at %DATE% %TIME% ----->> "%LOGFILE%"

echo ==================================================================
echo DemoLife - Reset DB ^& Seed (Windows)
echo ==================================================================
echo Este script parara y removera contenedores y volumenes, levantara el servicio de DB,
echo aplicara el schema de Prisma y ejecutara el seed.
echo ADVERTENCIA: Se eliminaran datos en la base de datos (volumenes).
echo.
choice /M "Deseas continuar?"
if errorlevel 2 (
  echo Operación cancelada por el usuario.
  exit /b 1
)

REM Ejecutar desde la raíz del repo (soporta doble-click)
cd /d "%~dp0.."
echo Current dir: %cd%
echo Current dir: %cd%>> "%LOGFILE%"

echo [1/6] Limpiando contenedores antiguos (todos los existentes)...
echo Running: docker ps -aq
echo Running: docker ps -aq>> "%LOGFILE%"
docker ps -aq > "%~dp0container-ids.txt" 2>nul
for /f %%I in (%~dp0container-ids.txt) do (
  echo Eliminando contenedor: %%I
  docker rm -f %%I >> "%LOGFILE%" 2>&1
)
del "%~dp0container-ids.txt" 2>nul
echo [1/6] done.
echo [1/6] done.>> "%LOGFILE%"

echo [2/6] Parando y eliminando contenedores y volumenes del compose (docker compose down -v --rmi all)...
echo Running: docker compose -f docker-compose.yml down -v --rmi all --remove-orphans
echo Running: docker compose -f docker-compose.yml down -v --rmi all --remove-orphans>> "%LOGFILE%"
docker compose -f docker-compose.yml down -v --rmi all --remove-orphans >> "%LOGFILE%" 2>&1
if errorlevel 1 (
  echo.
  echo ERROR: El comando anterior falló con código %errorlevel%.
  echo Revisa la salida arriba y corrige el problema.
  exit /b %errorlevel%
)
echo [2/6] done.
echo [2/6] done.>> "%LOGFILE%"

echo [3/6] Levantando solo el servicio de BD (docker compose up -d db)...
echo Running: docker compose -f docker-compose.yml up -d db
echo Running: docker compose -f docker-compose.yml up -d db>> "%LOGFILE%"
docker compose -f docker-compose.yml up -d db >> "%LOGFILE%" 2>&1
if errorlevel 1 (
  echo.
  echo ERROR: El comando anterior falló con código %errorlevel%.
  echo Revisa la salida arriba y corrige el problema.
  exit /b %errorlevel%
)
echo [3/6] done.
echo [3/6] done.>> "%LOGFILE%"

REM Mostrar estado de los servicios y esperar unos segundos para que DB arranque
echo Mostrando status de docker compose (ps)...
docker compose -f docker-compose.yml ps >> "%LOGFILE%" 2>&1
docker compose -f docker-compose.yml ps
REM Esperar más tiempo para que Postgres esté 100%% lista (10 segundos)
echo Esperando 10 segundos para que la BD este completamente lista...
ping -n 11 127.0.0.1 >nul

echo [4/6] Aplicando el schema de Prisma (db push)...
if /I "%~1"=="host" goto :PRISMA_HOST_PUSH
goto :PRISMA_CONTAINER_PUSH

:PRISMA_HOST_PUSH
echo Running (host): npx prisma db push --schema backend\prisma\schema.prisma --accept-data-loss
echo Running (host): npx prisma db push --schema backend\prisma\schema.prisma --accept-data-loss>> "%LOGFILE%"
set "ORIG_DIR=%cd%"
cd /d "%ORIG_DIR%\backend"
call npx prisma db push --accept-data-loss >> "%LOGFILE%" 2>&1
set PRISMA_EXIT_CODE=!errorlevel!
cd /d "%ORIG_DIR%"
if !PRISMA_EXIT_CODE! neq 0 (
  echo.
  echo ERROR: prisma db push en host falló con código !PRISMA_EXIT_CODE!. Asegúrate de tener npx y las dependencias instaladas en backend y ejecuta `cd backend ^&^& npm install` si es necesario.
  exit /b !PRISMA_EXIT_CODE!
)
goto :PRISMA_DONE

:PRISMA_CONTAINER_PUSH
echo Running: docker compose run --rm backend npx prisma db push --accept-data-loss
echo Running: docker compose run --rm backend npx prisma db push --accept-data-loss>> "%LOGFILE%"
docker compose run --rm backend npx prisma db push --accept-data-loss >> "%LOGFILE%" 2>&1
if errorlevel 1 (
  echo.
  echo ERROR: El comando anterior falló con código %errorlevel%.
  echo Revisa la salida arriba y corrige el problema.
  exit /b %errorlevel%
)

:PRISMA_DONE
echo [4/6] done.
echo [4/6] done.>> "%LOGFILE%"

REM Si se pasó el parámetro host, intentar seed en host (backend\npm run prisma:seed:host)
if /I "%~1"=="host" (
  echo [5/6] Ejecutando seed en el host backend usando npm run prisma^:seed^:host
  set "ORIG_DIR=%cd%"
  cd /d "!ORIG_DIR!\backend"
  call npm run prisma:seed:host >> "%LOGFILE%" 2>&1
  set SEED_EXIT_CODE=!errorlevel!
  cd /d "!ORIG_DIR!"
  if !SEED_EXIT_CODE! neq 0 (
    echo ERROR: Seed en host falló con código !SEED_EXIT_CODE!. Asegúrate de tener DATABASE_URL y las dependencias instaladas.
    exit /b !SEED_EXIT_CODE!
  )
  echo [5/6] done.
  echo [5/6] done.>> "%LOGFILE%"
) else (
  echo [5/6] Ejecutando seed dentro del contenedor (recomendado)...
  echo Running: docker compose run --rm backend npm run prisma:seed
  echo Running: docker compose run --rm backend npm run prisma:seed>> "%LOGFILE%"
  docker compose run --rm backend npm run prisma:seed >> "%LOGFILE%" 2>&1
  if errorlevel 1 (
    echo.
    echo AVISO: El seed dentro del contenedor ha fallado.
    echo Puedes intentar ejecutar el seed en el host con: scripts\reset-db.bat host
    exit /b 1
  )
  echo [5/6] done.
  echo [5/6] done.>> "%LOGFILE%"
)

echo [6/6] Construyendo y levantando el backend (docker compose up -d --build backend)...
echo Running: docker compose -f docker-compose.yml up -d --build backend
echo Running: docker compose -f docker-compose.yml up -d --build backend>> "%LOGFILE%"
docker compose -f docker-compose.yml up -d --build backend >> "%LOGFILE%" 2>&1
if errorlevel 1 (
  echo.
  echo ERROR: El comando anterior falló con código %errorlevel%.
  echo Revisa la salida arriba y corrige el problema.
  exit /b %errorlevel%
)
echo [6/6] done.
echo [6/6] done.>> "%LOGFILE%"

echo.
echo ¡Proceso completado exitosamente! 
echo.
echo Servicios corriendo:
docker compose -f docker-compose.yml ps
echo.
echo Revisa los logs con:
echo   docker compose -f docker-compose.yml logs --tail 200 backend
echo   docker compose -f docker-compose.yml logs --tail 200 db
echo.
endlocal
exit /b 0
