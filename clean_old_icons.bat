@echo off
REM Script para eliminar iconos antiguos (excepto los generados desde logo.jpg)
echo ========================================
echo   Limpiador de Iconos Antiguos
echo ========================================
echo.
echo Este script eliminará iconos antiguos y archivos innecesarios
echo manteniendo solo los iconos generados desde logo.jpg
echo.
pause

REM Eliminar placeholders antiguos
echo [1/3] Eliminando placeholders antiguos...
if exist "assets\icon\app_icon_placeholder.txt" del /F /Q assets\icon\app_icon_placeholder.txt
if exist "assets\icon\app_icon.png" (
    echo Encontrado app_icon.png antiguo
    choice /C YN /M "¿Deseas eliminar app_icon.png (ahora usamos logo.jpg)?"
    if errorlevel 2 goto skip_appicon
    del /F /Q assets\icon\app_icon.png
    :skip_appicon
)
echo ✓ Limpieza completada
echo.

REM Buscar otros logos duplicados
echo [2/3] Buscando logos duplicados en el proyecto...
for /r %%i in (logo.png icon.png app_icon.svg) do (
    if exist "%%i" (
        echo Encontrado: %%i
    )
)
echo.

echo [3/3] Resumen de iconos actuales:
echo.
echo Logo fuente:
if exist "logo.jpg" echo   ✓ logo.jpg (raíz del proyecto)
if exist "assets\icon\logo.jpg" echo   ✓ assets/icon/logo.jpg
echo.
echo Iconos Android:
for %%d in (mdpi hdpi xhdpi xxhdpi xxxhdpi) do (
    if exist "android\app\src\main\res\mipmap-%%d\ic_launcher.png" (
        echo   ✓ mipmap-%%d/ic_launcher.png
    )
)
echo.
echo Iconos Web:
if exist "web\icons\Icon-192.png" echo   ✓ web/icons/Icon-192.png
if exist "web\icons\Icon-512.png" echo   ✓ web/icons/Icon-512.png
if exist "web\icons\Icon-maskable-192.png" echo   ✓ web/icons/Icon-maskable-192.png
if exist "web\icons\Icon-maskable-512.png" echo   ✓ web/icons/Icon-maskable-512.png
echo.
echo Iconos Windows:
if exist "windows\runner\resources\app_icon.ico" echo   ✓ windows/runner/resources/app_icon.ico
echo.
echo ========================================
echo   Limpieza completada
echo ========================================
echo.
echo NOTA: Para regenerar iconos, ejecuta: generate_icons.bat
echo.
pause
