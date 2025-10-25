@echo off
echo Cerrando VS Code...
taskkill /f /im Code.exe >nul 2>&1
timeout /t 2 >nul
echo Iniciando VS Code...
start "" "C:\Users\%USERNAME%\AppData\Local\Programs\Microsoft VS Code\Code.exe" "%~dp0.."
echo VS Code reiniciado correctamente.