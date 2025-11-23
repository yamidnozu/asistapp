@echo off
REM Script para generar todos los iconos de la aplicación desde logo.jpg
REM Requiere: Flutter y flutter_launcher_icons

echo ========================================
echo   Generador de Iconos - AsistApp
echo ========================================
echo.

REM Verificar que existe logo.jpg
if not exist "logo.jpg" (
    echo [ERROR] No se encontró logo.jpg en la raíz del proyecto
    echo Por favor, coloca tu logo en la raíz del proyecto con el nombre logo.jpg
    pause
    exit /b 1
)

echo [1/5] Verificando logo.jpg...
echo ✓ Logo encontrado
echo.

REM Crear carpeta de assets si no existe
if not exist "assets\icon\" mkdir assets\icon

REM Copiar logo.jpg a la carpeta de assets
echo [2/5] Copiando logo a assets/icon/...
copy /Y logo.jpg assets\icon\logo.jpg >nul
echo ✓ Logo copiado a assets/icon/
echo.

REM Eliminar iconos antiguos de Android
echo [3/5] Eliminando iconos antiguos...
if exist "android\app\src\main\res\mipmap-mdpi\ic_launcher.png" del /F /Q android\app\src\main\res\mipmap-mdpi\ic_launcher.png >nul 2>&1
if exist "android\app\src\main\res\mipmap-hdpi\ic_launcher.png" del /F /Q android\app\src\main\res\mipmap-hdpi\ic_launcher.png >nul 2>&1
if exist "android\app\src\main\res\mipmap-xhdpi\ic_launcher.png" del /F /Q android\app\src\main\res\mipmap-xhdpi\ic_launcher.png >nul 2>&1
if exist "android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png" del /F /Q android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png >nul 2>&1
if exist "android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png" del /F /Q android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png >nul 2>&1
echo ✓ Iconos antiguos eliminados
echo.

REM Actualizar dependencias
echo [4/5] Instalando flutter_launcher_icons...
call flutter pub add flutter_launcher_icons --dev
echo ✓ Dependencia instalada
echo.

REM Generar nuevos iconos
echo [5/5] Generando nuevos iconos...
echo Este proceso puede tardar un momento...
call flutter pub get
call dart run flutter_launcher_icons:main -f flutter_launcher_icons.yaml

if errorlevel 1 (
    echo.
    echo [ERROR] Hubo un problema al generar los iconos
    echo Verifica el archivo flutter_launcher_icons.yaml y la configuración
    pause
    exit /b 1
)

echo.
echo ========================================
echo   ✓ ¡Iconos generados exitosamente!
echo ========================================
echo.
echo Los iconos se han generado para:
echo   ✓ Android (todos los tamaños mipmap)
echo   ✓ iOS (AppIcon.appiconset)
echo   ✓ Web (favicon y PWA icons)
echo   ✓ Windows (app_icon.ico)
echo.
echo Puedes ejecutar la aplicación para ver los cambios.
echo.
pause
