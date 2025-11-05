@echo off
echo ========================================
echo  🚀 EJECUTANDO PRUEBAS E2E ASISTAPP
echo ========================================
echo.

echo [1/3] Verificando base de datos...
docker ps | findstr "asistapp-db" >nul
if %errorlevel% neq 0 (
    echo ⚠️  Base de datos no está corriendo. Iniciando...
    docker compose -f docker-compose.yml up -d db
    echo ⏳ Esperando que la DB esté lista...
    timeout /t 10 /nobreak > nul
) else (
    echo ✅ Base de datos ya está corriendo
)
echo.

echo [2/3] Ejecutando pruebas E2E...
cd /d "%~dp0"
flutter test integration_test -d windows
set TEST_RESULT=%errorlevel%

echo.
echo [3/3] Resultados de las pruebas:
if %TEST_RESULT% equ 0 (
    echo ✅ TODAS LAS PRUEBAS PASARON EXITOSAMENTE
    echo 🎉 La aplicación está funcionando correctamente
) else (
    echo ❌ ALGUNAS PRUEBAS FALLARON
    echo 🔍 Revisa los logs arriba para más detalles
    echo 💡 Posibles soluciones:
    echo    - Verifica que la base de datos esté corriendo
    echo    - Revisa la configuración en .env
    echo    - Verifica que no haya procesos de Flutter corriendo
)

echo.
echo ========================================
echo         FIN DE EJECUCIÓN
echo ========================================
echo.
echo Presiona cualquier tecla para continuar...
pause > nul