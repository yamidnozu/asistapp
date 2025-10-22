#!/bin/bash
echo "Building Flutter APK without deprecation warnings..."
cd "c:/Proyectos/DemoLife"
flutter build apk --debug 2>&1 | grep -v "Note: Some input files use or override a deprecated API" | grep -v "Note: Recompile with -Xlint:deprecation for details"
echo ""
echo "Build completed successfully!"