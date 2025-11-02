@echo off
REM run_e2e_tests.bat
REM Script para ejecutar las pruebas E2E en Windows

setlocal enabledelayedexpansion

cls
echo ==========================================
echo ^^ Ejecutor de Pruebas E2E - AsistApp
echo ==========================================
echo.

:menu
echo.
echo Selecciona una opcion:
echo 1) Ejecutar prueba principal ^(app_test.dart^)
echo 2) Ejecutar pruebas extendidas ^(extended_tests.dart^)
echo 3) Ejecutar todas las pruebas
echo 4) Ejecutar con timeout extendido
echo 5) Limpiar y ejecutar
echo 6) Verificar solo configuracion
echo 0) Salir
echo.
set /p choice="Opcion: "

if "%choice%"=="1" (
    echo.
    echo Ejecutando prueba principal...
    flutter test integration_test\app_test.dart -v
    goto menu
)

if "%choice%"=="2" (
    echo.
    echo Ejecutando pruebas extendidas...
    flutter test integration_test\extended_tests.dart -v
    goto menu
)

if "%choice%"=="3" (
    echo.
    echo Ejecutando todas las pruebas...
    flutter test integration_test\ -v
    goto menu
)

if "%choice%"=="4" (
    echo.
    echo Ejecutando con timeout extendido...
    flutter test integration_test\app_test.dart -v --timeout=300s
    goto menu
)

if "%choice%"=="5" (
    echo.
    echo Limpiando proyecto...
    flutter clean
    flutter pub get
    echo.
    echo Ejecutando prueba principal...
    flutter test integration_test\app_test.dart -v
    goto menu
)

if "%choice%"=="6" (
    echo.
    echo Verificando configuracion...
    echo.
    echo Verificando Flutter...
    flutter --version
    echo.
    echo Verificando dispositivos...
    flutter devices
    echo.
    echo [OK] Sistema listo
    goto menu
)

if "%choice%"=="0" (
    echo.
    echo ^! Hasta luego!
    exit /b 0
)

echo.
echo [ERROR] Opcion invalida
goto menu
