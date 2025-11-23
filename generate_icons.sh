#!/bin/bash
# Script para generar todos los iconos de la aplicación desde logo.jpg
# Requiere: Flutter y flutter_launcher_icons

echo "========================================"
echo "  Generador de Iconos - AsistApp"
echo "========================================"
echo ""

# Verificar que existe logo.jpg
if [ ! -f "logo.jpg" ]; then
    echo "[ERROR] No se encontró logo.jpg en la raíz del proyecto"
    echo "Por favor, coloca tu logo en la raíz del proyecto con el nombre logo.jpg"
    exit 1
fi

echo "[1/5] Verificando logo.jpg..."
echo "✓ Logo encontrado"
echo ""

# Crear carpeta de assets si no existe
mkdir -p assets/icon

# Copiar logo.jpg a la carpeta de assets
echo "[2/5] Copiando logo a assets/icon/..."
cp logo.jpg assets/icon/logo.jpg
echo "✓ Logo copiado a assets/icon/"
echo ""

# Eliminar iconos antiguos de Android
echo "[3/5] Eliminando iconos antiguos..."
rm -f android/app/src/main/res/mipmap-mdpi/ic_launcher.png 2>/dev/null
rm -f android/app/src/main/res/mipmap-hdpi/ic_launcher.png 2>/dev/null
rm -f android/app/src/main/res/mipmap-xhdpi/ic_launcher.png 2>/dev/null
rm -f android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png 2>/dev/null
rm -f android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png 2>/dev/null
echo "✓ Iconos antiguos eliminados"
echo ""

# Actualizar dependencias
echo "[4/5] Instalando flutter_launcher_icons..."
flutter pub add flutter_launcher_icons --dev
echo "✓ Dependencia instalada"
echo ""

# Generar nuevos iconos
echo "[5/5] Generando nuevos iconos..."
echo "Este proceso puede tardar un momento..."
flutter pub get
dart run flutter_launcher_icons:main -f flutter_launcher_icons.yaml

if [ $? -ne 0 ]; then
    echo ""
    echo "[ERROR] Hubo un problema al generar los iconos"
    echo "Verifica el archivo flutter_launcher_icons.yaml y la configuración"
    exit 1
fi

echo ""
echo "========================================"
echo "  ✓ ¡Iconos generados exitosamente!"
echo "========================================"
echo ""
echo "Los iconos se han generado para:"
echo "  ✓ Android (todos los tamaños mipmap)"
echo "  ✓ iOS (AppIcon.appiconset)"
echo "  ✓ Web (favicon y PWA icons)"
echo "  ✓ Windows (app_icon.ico)"
echo ""
echo "Puedes ejecutar la aplicación para ver los cambios."
echo ""
