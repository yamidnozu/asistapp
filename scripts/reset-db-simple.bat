echo "cd /c/Proyectos/DemoLife && ./scripts/reset-db-simple.bat"
@echo off
REM Simple batch script to reset database, apply Prisma schema, seed and start backend
setlocal enabledelayedexpansion

echo ==================================================================
echo DemoLife - Reset DB and Seed
echo ==================================================================
echo.
choice /M "Continue? This will delete all data"
if errorlevel 2 exit /b 1

cd /d "%~dp0.."

echo [1/6] Cleaning old containers...
for /f %%i in ('docker ps -aq 2^>nul') do docker rm -f %%i >nul 2>&1
echo Done.

echo [2/6] Docker compose down...
docker compose down -v --rmi all --remove-orphans >nul 2>&1
echo Done.

echo [3/6] Starting database...
docker compose up -d db
echo Waiting 10 seconds...
ping -n 11 127.0.0.1 >nul
echo Done.

echo [4/6] Applying Prisma schema...
cd backend
call npx prisma db push --accept-data-loss
cd ..
echo Done.

echo [5/6] Running seed...
cd backend
call npm run prisma:seed:host
cd ..
echo Done.

echo [6/6] Starting backend...
docker compose up -d --build backend
echo Done.

echo.
echo All done! Services:
docker compose ps

endlocal
