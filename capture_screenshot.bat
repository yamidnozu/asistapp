@echo off
REM Script para capturar screenshots del emulador Android a docs/images/
REM Uso: capture_screenshot.bat nombre_screenshot
REM Ejemplo: capture_screenshot.bat login_screen

SET ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe
SET OUTPUT_DIR=%~dp0docs\images
SET SCREENSHOT_NAME=%1

IF "%SCREENSHOT_NAME%"=="" (
    echo Uso: capture_screenshot.bat nombre_screenshot
    echo Ejemplo: capture_screenshot.bat login_screen
    exit /b 1
)

REM Crear directorio si no existe
IF NOT EXIST "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

REM Capturar screenshot en el emulador
echo Capturando screenshot: %SCREENSHOT_NAME%.png
"%ADB%" shell screencap -p /sdcard/%SCREENSHOT_NAME%.png

REM Descargar a PC
"%ADB%" pull /sdcard/%SCREENSHOT_NAME%.png "%OUTPUT_DIR%\%SCREENSHOT_NAME%.png"

REM Limpiar archivo del emulador
"%ADB%" shell rm /sdcard/%SCREENSHOT_NAME%.png

echo Screenshot guardado en: %OUTPUT_DIR%\%SCREENSHOT_NAME%.png
