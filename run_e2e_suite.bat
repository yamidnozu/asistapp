@echo off
:: ============================================================================
:: EJECUTOR SUITE E2E COMPLETA - 100%
:: ============================================================================
:: 
:: Ejecuta todos los tests E2E de forma secuencial
:: Cada test tiene aislamiento completo
::
:: ============================================================================

setlocal enabledelayedexpansion

echo.
echo ══════════════════════════════════════════════════════════════════════════
echo 🚀 SUITE E2E COMPLETA - OPERACIONES CRUD REALES
echo ══════════════════════════════════════════════════════════════════════════
echo.

set PASSED=0
set FAILED=0
set TOTAL=0

cd /d "c:\Proyectos\DemoLife"

:: Lista de tests
set "TESTS=e2e_crud_instituciones_test.dart e2e_crud_usuarios_test.dart e2e_crud_materias_test.dart e2e_crud_grupos_test.dart e2e_seguridad_roles_test.dart e2e_flujo_asistencia_test.dart e2e_validaciones_test.dart"

for %%T in (%TESTS%) do (
    set /a TOTAL+=1
    echo.
    echo ──────────────────────────────────────────────────────────────────────────
    echo 📋 Test !TOTAL!: %%T
    echo ──────────────────────────────────────────────────────────────────────────
    
    flutter test integration_test/%%T -d windows --no-pub 2>&1 | findstr /C:"All tests passed" /C:"Some tests failed" /C:"✅" /C:"❌" /C:"TEST COMPLETADO"
    
    if !ERRORLEVEL! EQU 0 (
        set /a PASSED+=1
        echo ✅ PASÓ: %%T
    ) else (
        set /a FAILED+=1
        echo ❌ FALLÓ: %%T
    )
)

echo.
echo ══════════════════════════════════════════════════════════════════════════
echo 📊 RESUMEN FINAL
echo ══════════════════════════════════════════════════════════════════════════
echo.
echo ✅ Pasaron: %PASSED%/%TOTAL%
echo ❌ Fallaron: %FAILED%/%TOTAL%
echo.

set /a PERCENTAGE=(%PASSED%*100)/%TOTAL%
echo 📈 Tasa de éxito: %PERCENTAGE%%%
echo.
echo ══════════════════════════════════════════════════════════════════════════

if %FAILED% GTR 0 (
    exit /b 1
) else (
    echo 🎉 TODOS LOS TESTS PASARON
    exit /b 0
)
