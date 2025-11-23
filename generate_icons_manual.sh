#!/bin/bash
# Script manual para generar iconos usando ImageMagick
# Solo si prefieres no usar flutter_launcher_icons

echo "========================================="
echo " Generación Manual de Iconos con ImageMagick"
echo "========================================="
echo ""

# Verificar que ImageMagick está instalado
if ! command -v convert &> /dev/null; then
    echo "[ERROR] ImageMagick no está instalado"
    echo "Por favor instala ImageMagick primero:"
    echo "  Windows: choco install imagemagick"
    echo "  Mac: brew install imagemagick"
    echo "  Linux: sudo apt install imagemagick"
    exit 1
fi

# Verificar que existe logo.jpg
if [ ! -f "logo.jpg" ]; then
    echo "[ERROR] No se encontró logo.jpg"
    exit 1
fi

echo "✓ ImageMagick encontrado"
echo "✓ Logo.jpg encontrado"
echo ""

# Crear directorios necesarios
mkdir -p assets/icon
mkdir -p android/app/src/main/res/mipmap-mdpi
mkdir -p android/app/src/main/res/mipmap-hdpi
mkdir -p android/app/src/main/res/mipmap-xhdpi
mkdir -p android/app/src/main/res/mipmap-xxhdpi
mkdir -p android/app/src/main/res/mipmap-xxxhdpi
mkdir -p web/icons

# Copiar logo original
cp logo.jpg assets/icon/logo.jpg

echo "[1/4] Generando iconos Android..."

# Android icons
convert logo.jpg -resize 48x48 android/app/src/main/res/mipmap-mdpi/ic_launcher.png
convert logo.jpg -resize 72x72 android/app/src/main/res/mipmap-hdpi/ic_launcher.png
convert logo.jpg -resize 96x96 android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
convert logo.jpg -resize 144x144 android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
convert logo.jpg -resize 192x192 android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png

echo "  ✓ mdpi (48x48)"
echo "  ✓ hdpi (72x72)"
echo "  ✓ xhdpi (96x96)"
echo "  ✓ xxhdpi (144x144)"
echo "  ✓ xxxhdpi (192x192)"
echo ""

echo "[2/4] Generando iconos Web..."

# Web icons
convert logo.jpg -resize 192x192 web/icons/Icon-192.png
convert logo.jpg -resize 512x512 web/icons/Icon-512.png
convert logo.jpg -resize 192x192 web/icons/Icon-maskable-192.png
convert logo.jpg -resize 512x512 web/icons/Icon-maskable-512.png
convert logo.jpg -resize 32x32 web/favicon.png

echo "  ✓ Icon-192.png"
echo "  ✓ Icon-512.png"
echo "  ✓ Icon-maskable-192.png"
echo "  ✓ Icon-maskable-512.png"
echo "  ✓ favicon.png (32x32)"
echo ""

echo "[3/4] Generando iconos iOS..."

# iOS requiere estructura específica - se recomienda usar flutter_launcher_icons
echo "  ⚠ Para iOS, se recomienda usar flutter_launcher_icons"
echo "  Ejecuta: bash generate_icons.sh"
echo ""

echo "[4/4] Generando iconos Windows..."

# Windows icon (multi-size ICO)
if [ -d "windows/runner/resources" ]; then
    convert logo.jpg \
        \( -clone 0 -resize 16x16 \) \
        \( -clone 0 -resize 32x32 \) \
        \( -clone 0 -resize 48x48 \) \
        \( -clone 0 -resize 256x256 \) \
        -delete 0 windows/runner/resources/app_icon.ico
    echo "  ✓ app_icon.ico (multi-size)"
else
    echo "  ⚠ Carpeta windows/ no encontrada"
fi
echo ""

echo "========================================="
echo "  ✓ Iconos generados con ImageMagick"
echo "========================================="
echo ""
echo "Nota: Para una generación completa incluyendo iOS,"
echo "ejecuta: bash generate_icons.sh"
echo ""
