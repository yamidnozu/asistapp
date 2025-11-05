@echo off
REM ============================================================================
REM Script para activar los tests optimizados
REM ============================================================================
REM Este script reemplaza el archivo de tests antiguo con la versión optimizada
REM ============================================================================

setlocal enabledelayedexpansion
cd /d "%~dp0"

echo.
echo ============================================================================
echo ACTIVAR TESTS E2E OPTIMIZADOS
echo ============================================================================
echo.

REM Verificar que el archivo optimizado existe
if not exist "integration_test\extended_tests_optimized.dart" (
    echo ERROR: No se encuentra integration_test\extended_tests_optimized.dart
    echo.
    echo Por favor crea el archivo primero.
    exit /b 1
)

REM Preguntar si desea hacer backup
echo Se va a reemplazar: integration_test\extended_tests.dart
echo.

if exist "integration_test\extended_tests.dart" (
    echo ¿Deseas hacer backup del archivo original?
    echo.
    echo S - Sí, hacer backup (recomendado)
    echo N - No, reemplazar directamente
    echo X - Cancelar
    echo.
    
    set /p choice="Selecciona (S/N/X): "
    
    if /i "!choice!"=="S" (
        REM Crear backup
        set "BACKUP_FILE=integration_test\extended_tests.backup.!RANDOM!.dart"
        copy "integration_test\extended_tests.dart" "!BACKUP_FILE!" >nul
        echo ✓ Backup creado: !BACKUP_FILE!
        echo.
    ) else if /i "!choice!"=="X" (
        echo Operación cancelada.
        exit /b 0
    )
)

REM Reemplazar archivo
echo Copiando archivo optimizado...
copy "integration_test\extended_tests_optimized.dart" "integration_test\extended_tests.dart" >nul 2>&1

if errorlevel 1 (
    echo ✗ ERROR al copiar archivo
    exit /b 1
)

echo ✓ Tests optimizados ACTIVADOS
echo.
echo Ahora puedes ejecutar:
echo   flutter test integration_test\extended_tests.dart -d windows
echo.
echo O ejecutar validación:
echo   .\validate_tests.bat
echo.

exit /b 0
