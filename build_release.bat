@echo off
echo Generando App Bundle para Play Store...
echo.

flutter clean
flutter pub get

echo.
echo Construyendo App Bundle...
echo.

flutter build appbundle --release

if %errorlevel% equ 0 (
    echo.
    echo ✅ App Bundle generado exitosamente!
    echo 📁 Ubicación: build\app\outputs\bundle\release\app-release.aab
    echo.
    echo Sube este archivo a Google Play Console
    echo.
) else (
    echo.
    echo ❌ Error al generar el App Bundle
    echo.
)

pause