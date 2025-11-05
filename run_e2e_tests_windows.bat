@echo off
echo ========================================
echo  🚀 EJECUTANDO PRUEBAS E2E ASISTAPP
echo ========================================
echo.

echo [1/4] Iniciando base de datos...
docker compose -f docker-compose.yml up -d db
if %errorlevel% neq 0 (
    echo ❌ Error al iniciar la base de datos
    pause
    exit /b 1
)
echo ✅ Base de datos iniciada
echo.

echo [2/4] Esperando que la DB esté lista...
timeout /t 5 /nobreak > nul
echo ✅ Base de datos lista
echo.

echo [3/4] Ejecutando pruebas E2E...
cd /d "%~dp0"
flutter test integration_test\acceptance_flows_test.dart --no-pub
set TEST_RESULT=%errorlevel%

echo.
echo [4/4] Resultados de las pruebas:
if %TEST_RESULT% equ 0 (
    echo ✅ TODAS LAS PRUEBAS PASARON EXITOSAMENTE
    echo.
    echo 🎉 Las pruebas E2E se ejecutaron correctamente
) else (
    echo ❌ ALGUNAS PRUEBAS FALLARON
    echo.
    echo 🔍 Revisa los logs arriba para más detalles
)

echo.
echo ========================================
echo         FIN DE EJECUCIÓN
echo ========================================
echo.
echo Presiona cualquier tecla para continuar...
pause > nul