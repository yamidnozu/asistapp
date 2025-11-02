@echo off
REM Script para ejecutar tests E2E en Windows

setlocal enabledelayedexpansion

:menu
cls
echo.
echo ╔════════════════════════════════════════════╗
echo ║   E2E TESTING RUNNER - AsistApp/DemoLife  ║
echo ║   Status: ✓ Fully Functional              ║
echo ╚════════════════════════════════════════════╝
echo.
echo 1. Ejecutar todos los tests (app_e2e_test)
echo 2. Ejecutar tests de diagnóstico (simple_test)
echo 3. Ejecutar tests avanzados (app_test)
echo 4. Ejecutar test específico por nombre
echo 5. Ejecutar con salida verbose
echo 6. Ejecutar en Chrome
echo 7. Salir
echo.
set /p choice="Selecciona una opción (1-7): "

if "%choice%"=="1" goto run_all
if "%choice%"=="2" goto run_simple
if "%choice%"=="3" goto run_app
if "%choice%"=="4" goto run_specific
if "%choice%"=="5" goto run_verbose
if "%choice%"=="6" goto run_chrome
if "%choice%"=="7" goto exit_script

echo.
echo ✗ Opción no válida
timeout /t 2 >nul
goto menu

:run_all
cls
echo.
echo [*] Ejecutando: app_e2e_test.dart
echo [*] Plataforma: Windows Desktop
echo.
echo flutter test integration_test/app_e2e_test.dart -d windows
echo.
call flutter test integration_test/app_e2e_test.dart -d windows
pause
goto menu

:run_simple
cls
echo.
echo [*] Ejecutando: simple_test.dart (diagnóstico rápido)
echo [*] Plataforma: Windows Desktop
echo.
call flutter test integration_test/simple_test.dart -d windows
pause
goto menu

:run_app
cls
echo.
echo [*] Ejecutando: app_test.dart (versión completa)
echo [*] Plataforma: Windows Desktop
echo.
call flutter test integration_test/app_test.dart -d windows
pause
goto menu

:run_specific
cls
echo.
set /p test_name="Ingresa el nombre del test a ejecutar: "
echo.
echo [*] Ejecutando test: %test_name%
echo.
call flutter test integration_test/app_e2e_test.dart -d windows --name "%test_name%"
pause
goto menu

:run_verbose
cls
echo.
echo [*] Ejecutando con salida VERBOSE
echo [*] Plataforma: Windows Desktop
echo.
call flutter test integration_test/app_e2e_test.dart -d windows --verbose
pause
goto menu

:run_chrome
cls
echo.
echo [*] Ejecutando en Chrome (Web)
echo [*] Nota: Requiere Chrome instalado
echo.
call flutter test integration_test/app_e2e_test.dart -d chrome
pause
goto menu

:exit_script
cls
echo.
echo ✓ Saliendo...
echo.
timeout /t 1 >nul
exit /b 0
