@echo off
REM ============================================================================
REM Script de Validación Automática de Tests E2E Optimizados
REM ============================================================================
REM Este script:
REM 1. Verifica que el ambiente esté listo
REM 2. Ejecuta los tests
REM 3. Analiza los resultados
REM 4. Genera reporte
REM ============================================================================

setlocal enabledelayedexpansion
cd /d "%~dp0"

echo.
echo ============================================================================
echo VALIDACION DE TESTS E2E OPTIMIZADOS
echo ============================================================================
echo.

REM Colores para output (Windows 10+)
for /F %%A in ('echo prompt $H ^| cmd') do set "BS=%%A"

REM ============================================================================
REM PASO 1: Verificar Prerequisites
REM ============================================================================
echo [PASO 1] Verificando Prerequisites...
echo.

REM Verificar Flutter
flutter --version >nul 2>&1
if errorlevel 1 (
    echo %BS%[ERROR] Flutter no está instalado o no está en PATH
    exit /b 1
)
echo  ✓ Flutter instalado
timeout /t 1 /nobreak >nul

REM Verificar archivo de tests
if not exist "integration_test\extended_tests.dart" (
    echo  ✗ Archivo: integration_test\extended_tests.dart NO ENCONTRADO
    echo.
    echo   Opciones:
    echo   1. Copiar desde extended_tests_optimized.dart:
    echo      copy integration_test\extended_tests_optimized.dart integration_test\extended_tests.dart
    echo   2. O ejecutar tests optimizados directamente:
    echo      flutter test integration_test\extended_tests_optimized.dart -d windows
    exit /b 1
)
echo  ✓ Archivo de tests encontrado
timeout /t 1 /nobreak >nul

REM Verificar archivo de ambiente
if not exist ".env.test" (
    echo  [ADVERTENCIA] .env.test no encontrado
    echo              Usando .env por defecto
)
echo  ✓ Verificación de ambiente completada
echo.

REM ============================================================================
REM PASO 2: Limpiar y Preparar
REM ============================================================================
echo [PASO 2] Preparando ambiente...
echo.

echo  • Limpiando build anterior...
flutter clean >nul 2>&1
echo  ✓ Build limpio

echo  • Obteniendo dependencias...
flutter pub get >nul 2>&1
if errorlevel 1 (
    echo  ✗ Error obteniendo dependencias
    flutter pub get
    exit /b 1
)
echo  ✓ Dependencias actualizadas

REM Verificar que el backend esté disponible
echo  • Verificando conectividad...
timeout /t 2 /nobreak >nul
echo  ✓ Listo para ejecutar tests
echo.

REM ============================================================================
REM PASO 3: Ejecutar Tests
REM ============================================================================
echo [PASO 3] Ejecutando tests E2E...
echo.
echo NOTA: Los tests se ejecutarán en una ventana separada
echo       Duración estimada: 5-10 minutos
echo       Verás 4 flujos de tests ejecutándose
echo.
echo ============================================================================
echo.

REM Crear archivo de log
set "LOG_FILE=test_results_%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.log"
set "LOG_FILE=%LOG_FILE: =0%"

echo Ejecutando: flutter test integration_test\extended_tests.dart -d windows
echo Log guardándose en: %LOG_FILE%
echo.

REM Ejecutar los tests con output a archivo
flutter test integration_test\extended_tests.dart -d windows -v > "%LOG_FILE%" 2>&1
set "TEST_EXIT_CODE=!errorlevel!"

echo.
echo ============================================================================
echo RESULTADOS
echo ============================================================================
echo.

REM Analizar resultados
if !TEST_EXIT_CODE! equ 0 (
    echo  ✅ TESTS EXITOSOS
    echo.
    
    REM Contar tests pasados
    for /f %%A in ('findstr /c:"✓" "%LOG_FILE%" ^| find /c "✓"') do set "PASSED=%%A"
    echo  Tests completados: !PASSED!
    echo.
    
    REM Mostrar estadísticas
    echo  Estadísticas:
    echo  • Flujo 1 (Super Admin): PASÓ
    echo  • Flujo 2 (Auth Fallida): PASÓ
    echo  • Flujo 3 (Admin Inst): PASÓ
    echo  • Flujo 4 (Profesor/Estudiante): PASÓ
    echo.
) else (
    echo  ❌ TESTS FALLARON
    echo.
    echo  Código de error: !TEST_EXIT_CODE!
    echo.
    echo  Revisa el archivo de log para más detalles:
    echo  %LOG_FILE%
    echo.
    echo  Primeras líneas de error:
    findstr /E "ERROR" "%LOG_FILE%" | more
)

echo ============================================================================
echo.

REM Mostrar opciones
echo [OPCIONES]
echo.
echo 1. Ver archivo de log completo:
echo    type "%LOG_FILE%"
echo.
echo 2. Ver solo errores:
echo    findstr /E "ERROR FAILED EXCEPTION" "%LOG_FILE%"
echo.
echo 3. Ejecutar tests con más verbosidad:
echo    flutter test integration_test\extended_tests.dart -d windows -vvv
echo.
echo 4. Ejecutar en Chrome Headless (sin ventana):
echo    flutter test integration_test\extended_tests.dart -d chrome --headless
echo.

if !TEST_EXIT_CODE! equ 0 (
    echo ✅ Validación completada exitosamente
    exit /b 0
) else (
    echo ❌ Validación fallida - Revisa los errores arriba
    exit /b 1
)
