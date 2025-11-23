@echo off
REM Script para ejecutar tests críticos de Super Admin en Windows
REM Uso: run_critical_tests.bat

echo.
echo ================================
echo TESTS CRITICOS - Super Admin
echo ================================
echo.

REM Verificar que Flutter esté instalado
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Flutter no esta instalado
    exit /b 1
)

echo [INFO] Verificando dependencias...
call flutter pub get

echo.
echo [INFO] Ejecutando TODOS los tests criticos...
echo.

REM Ejecutar tests críticos
call flutter test integration_test/comprehensive_flows_test.dart --name "CRITICO"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ================================
    echo [OK] TODOS LOS TESTS PASARON
    echo ================================
    echo.
    echo Tests ejecutados:
    echo   [OK] Login Super Admin ^(sin seleccion institucion^)
    echo   [OK] Comparacion Super Admin vs Admin
    echo   [OK] Acceso Global a Instituciones
    echo   [OK] Restriccion Admin Institucion
    echo   [OK] Arquitectura: Global vs Institucional
    echo   [OK] Base de Datos: Vinculos
    echo.
) else (
    echo.
    echo ================================
    echo [ERROR] ALGUNOS TESTS FALLARON
    echo ================================
    echo.
    echo Por favor revisa los errores arriba.
    echo Los tests criticos detectan:
    echo   - Problemas en flujo de autenticacion
    echo   - Seleccion incorrecta de institucion
    echo   - Permisos mal configurados
    echo   - Concepto arquitectonico incorrecto
    echo.
)

echo ================================
pause
exit /b %ERRORLEVEL%
