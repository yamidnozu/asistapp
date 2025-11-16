  if not exist "%REPO_ROOT%\windows\runner\resources\app_icon.ico" (
    where python >nul 2>&1
    if %errorlevel%==0 (
      echo Attempting to generate .ico using Python Pillow fallback
      python "%REPO_ROOT%\scripts\png_to_ico.py" "%ICON_SRC%" "%REPO_ROOT%\windows\runner\resources\app_icon.ico" || (
        echo Python generation failed; please install Pillow with 'pip install pillow'
      )
    )
  )
@echo off
REM Usage: scripts\install_icons.bat C:\path\to\flutter_app_icons

set SRC_DIR=%1
if "%SRC_DIR%"=="" (
  echo Usage: %~nx0 C:\path\to\flutter_app_icons
  exit /b 2
)

if NOT EXIST "%SRC_DIR%" (
  echo Source directory not found: %SRC_DIR%
  exit /b 2
)

set REPO_ROOT=%~dp0..\
set REPO_ROOT=%REPO_ROOT:~0,-1%

echo Installing icons from %SRC_DIR%

REM Android mipmap
  for /d %%D in ("%SRC_DIR%\mipmap-*" ) do (
  set DIR_NAME=%%~nD
  set TARGET=%REPO_ROOT%\android\app\src\main\res\%%~nD
  if not exist "%TARGET%" mkdir "%TARGET%"
  echo Copying files from %%D to %TARGET%
  copy "%%D\*" "%TARGET%"
)

REM iOS AppIcon
if exist "%SRC_DIR%\iOS\AppIcon.appiconset" (
  set TARGET=%REPO_ROOT%\ios\Runner\Assets.xcassets\AppIcon.appiconset
  if not exist "%TARGET%" mkdir "%TARGET%"
  echo Copying iOS icons
  copy "%SRC_DIR%\iOS\AppIcon.appiconset\*" "%TARGET%"
)

REM Windows
  if exist "%SRC_DIR%\app_icon.ico" (
  )
  REM If the source had launcher_icon, copy it to ic_launcher (preferred)
  REM Do not copy launcher_icon fallback. We prefer ic_launcher and clean launcher_icon files.
  set TARGET=%REPO_ROOT%\windows\runner\resources\app_icon.ico
  if exist "%TARGET%" (
    rename "%TARGET%" "%TARGET%.backup"
  )
  copy "%SRC_DIR%\app_icon.ico" "%TARGET%"
)
REM If app_icon.ico missing, try create with ImageMagick (magick.exe)
if not exist "%REPO_ROOT%\windows\runner\resources\app_icon.ico" (
  if exist "%SRC_DIR%\mipmap-xxxhdpi\ic_launcher.png" (
    set ICON_SRC=%SRC_DIR%\mipmap-xxxhdpi\ic_launcher.png
  ) else if exist "%SRC_DIR%\mipmap-xxhdpi\ic_launcher.png" (
    set ICON_SRC=%SRC_DIR%\mipmap-xxhdpi\ic_launcher.png
  ) else if exist "%SRC_DIR%\mipmap-xhdpi\ic_launcher.png" (
    set ICON_SRC=%SRC_DIR%\mipmap-xhdpi\ic_launcher.png
  ) else if exist "%SRC_DIR%\mipmap-hdpi\ic_launcher.png" (
    set ICON_SRC=%SRC_DIR%\mipmap-hdpi\ic_launcher.png
  ) else if exist "%SRC_DIR%\mipmap-mdpi\ic_launcher.png" (
    set ICON_SRC=%SRC_DIR%\mipmap-mdpi\ic_launcher.png
  )

  if defined ICON_SRC (
    where magick >nul 2>&1
    if %errorlevel%==0 (
      echo Generating %REPO_ROOT%\windows\runner\resources\app_icon.ico from %ICON_SRC%
      magick convert "%ICON_SRC%" -resize 16x16 "%TEMP%\\icon-16.png"
      magick convert "%ICON_SRC%" -resize 32x32 "%TEMP%\\icon-32.png"
      magick convert "%ICON_SRC%" -resize 48x48 "%TEMP%\\icon-48.png"
      magick convert "%ICON_SRC%" -resize 256x256 "%TEMP%\\icon-256.png"
      magick convert "%TEMP%\\icon-16.png" "%TEMP%\\icon-32.png" "%TEMP%\\icon-48.png" "%TEMP%\\icon-256.png" "%REPO_ROOT%\windows\runner\resources\app_icon.ico"
      del "%TEMP%\\icon-16.png" "%TEMP%\\icon-32.png" "%TEMP%\\icon-48.png" "%TEMP%\\icon-256.png"
    ) else (
      echo ImageMagick 'magick' not found. Provide app_icon.ico in source.
    )
  )
)

REM Web favicon
if exist "%SRC_DIR%\favicon.png" (
  copy "%SRC_DIR%\favicon.png" "%REPO_ROOT%\web\favicon.png"
) else if exist "%SRC_DIR%\assets\icon\app_icon.png" (
  copy "%SRC_DIR%\assets\icon\app_icon.png" "%REPO_ROOT%\web\favicon.png"
)

echo Icons installed.
echo Run: flutter pub run flutter_launcher_icons:main if needed.
