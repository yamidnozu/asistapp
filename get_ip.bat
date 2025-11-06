@echo off
echo ==========================================
echo     OBTENIENDO IP LOCAL DE TU PC
echo ==========================================
echo.

for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
    echo IP encontrada: %%a
)

echo.
echo ==========================================
echo IMPORTANTE: Usa una de estas IPs en:
echo lib/config/app_config.dart
echo Linea 27 y 31 (return 'http://TU_IP:3001';)
echo ==========================================
pause
