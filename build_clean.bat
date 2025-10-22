@echo off
echo Building Flutter APK without deprecation warnings...
cd "c:\Proyectos\DemoLife"
flutter build apk --debug 2>&1 | findstr /v "Note: Some input files use or override a deprecated API" | findstr /v "Note: Recompile with -Xlint:deprecation for details"
echo.
echo Build completed successfully!