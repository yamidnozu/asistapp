@echo off
REM Script de verificación rápida de iconos
echo.
echo ╔════════════════════════════════════════════════╗
echo ║   VERIFICACIÓN DE ICONOS - AsistApp            ║
echo ╚════════════════════════════════════════════════╝
echo.

REM Verificar logo fuente
echo [1/5] Verificando logo fuente...
if exist "logo.jpg" (
    echo   ✓ logo.jpg encontrado en raíz
) else (
    echo   ✗ logo.jpg NO encontrado
)

if exist "assets\icon\logo.jpg" (
    echo   ✓ assets/icon/logo.jpg encontrado
) else (
    echo   ✗ assets/icon/logo.jpg NO encontrado
)
echo.

REM Verificar configuración
echo [2/5] Verificando configuración...
if exist "flutter_launcher_icons.yaml" (
    echo   ✓ flutter_launcher_icons.yaml configurado
    findstr /C:"logo.jpg" flutter_launcher_icons.yaml >nul
    if errorlevel 1 (
        echo   ⚠ WARNING: No usa logo.jpg como fuente
    ) else (
        echo   ✓ Configurado para usar logo.jpg
    )
) else (
    echo   ✗ flutter_launcher_icons.yaml NO encontrado
)
echo.

REM Verificar iconos Android
echo [3/5] Verificando iconos Android...
set android_ok=0
for %%d in (mdpi hdpi xhdpi xxhdpi xxxhdpi) do (
    if exist "android\app\src\main\res\mipmap-%%d\ic_launcher.png" (
        set /a android_ok+=1
    )
)
if %android_ok%==5 (
    echo   ✓ Todos los iconos Android generados (5/5)
) else (
    echo   ⚠ Faltan iconos Android (%android_ok%/5)
)
echo.

REM Verificar iconos Web
echo [4/5] Verificando iconos Web...
set web_ok=0
if exist "web\icons\Icon-192.png" set /a web_ok+=1
if exist "web\icons\Icon-512.png" set /a web_ok+=1
if exist "web\icons\Icon-maskable-192.png" set /a web_ok+=1
if exist "web\icons\Icon-maskable-512.png" set /a web_ok+=1

if %web_ok%==4 (
    echo   ✓ Todos los iconos Web generados (4/4)
) else (
    echo   ⚠ Faltan iconos Web (%web_ok%/4)
)
echo.

REM Verificar iconos Windows
echo [5/5] Verificando iconos Windows...
if exist "windows\runner\resources\app_icon.ico" (
    echo   ✓ Icono Windows generado
) else (
    echo   ⚠ Falta icono Windows
)
echo.

echo ════════════════════════════════════════════════
echo   RESUMEN
echo ════════════════════════════════════════════════

set total_ok=0
if exist "logo.jpg" set /a total_ok+=1
if %android_ok%==5 set /a total_ok+=1
if %web_ok%==4 set /a total_ok+=1
if exist "windows\runner\resources\app_icon.ico" set /a total_ok+=1

echo.
if %total_ok%==4 (
    echo   ✓✓✓ TODO CORRECTO ✓✓✓
    echo.
    echo   Todos los iconos están generados correctamente.
    echo   Tu aplicación está lista para compilar.
) else (
    echo   ⚠ ATENCIÓN ⚠
    echo.
    echo   Algunos iconos faltan o no están configurados.
    echo   Ejecuta: generate_icons.bat para generarlos.
)
echo.
echo ════════════════════════════════════════════════
echo.
echo Para regenerar iconos: generate_icons.bat
echo Para más información: GENERAR_ICONOS.md
echo.
pause
