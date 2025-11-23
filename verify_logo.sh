#!/bin/bash
# Script para verificar y optimizar logo.jpg antes de generar iconos

echo "========================================="
echo " Verificador y Optimizador de Logo"
echo "========================================="
echo ""

# Verificar que ImageMagick está instalado
if ! command -v identify &> /dev/null; then
    echo "⚠ ImageMagick no está instalado (opcional para verificación)"
    echo "Puedes continuar sin él, pero no se verificará la calidad"
    echo ""
else
    # Obtener información del logo
    echo "[Analizando logo.jpg...]"
    echo ""
    
    if [ -f "logo.jpg" ]; then
        WIDTH=$(identify -format "%w" logo.jpg)
        HEIGHT=$(identify -format "%h" logo.jpg)
        SIZE=$(du -h logo.jpg | cut -f1)
        FORMAT=$(identify -format "%m" logo.jpg)
        
        echo "📊 Información del Logo:"
        echo "  • Formato: $FORMAT"
        echo "  • Dimensiones: ${WIDTH}x${HEIGHT} px"
        echo "  • Tamaño archivo: $SIZE"
        echo ""
        
        # Verificar si es cuadrado
        if [ "$WIDTH" != "$HEIGHT" ]; then
            echo "⚠ ADVERTENCIA: El logo no es cuadrado (${WIDTH}x${HEIGHT})"
            echo "  Se recomienda que sea cuadrado para mejores resultados"
            echo ""
        else
            echo "✓ El logo es cuadrado"
        fi
        
        # Verificar resolución mínima
        if [ "$WIDTH" -lt 512 ] || [ "$HEIGHT" -lt 512 ]; then
            echo "⚠ ADVERTENCIA: Resolución baja (${WIDTH}x${HEIGHT})"
            echo "  Se recomienda mínimo 1024x1024 px para mejor calidad"
            echo ""
        elif [ "$WIDTH" -ge 1024 ] && [ "$HEIGHT" -ge 1024 ]; then
            echo "✓ Resolución óptima (≥1024x1024)"
        fi
        
        # Sugerir conversión a PNG si es JPG
        if [ "$FORMAT" = "JPEG" ]; then
            echo ""
            echo "💡 Sugerencia: Convertir a PNG para mejor calidad"
            read -p "¿Deseas convertir logo.jpg a logo.png con fondo transparente? (y/n): " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                convert logo.jpg -background none -alpha set logo.png
                if [ -f "logo.png" ]; then
                    echo "✓ Convertido a logo.png"
                    echo "  Puedes usar logo.png en vez de logo.jpg"
                    echo "  Actualiza flutter_launcher_icons.yaml con logo.png"
                fi
            fi
        fi
        
    else
        echo "❌ No se encontró logo.jpg"
        exit 1
    fi
fi

echo ""
echo "========================================="
echo " Recomendaciones para el Logo"
echo "========================================="
echo ""
echo "✓ Formato: PNG con transparencia (o JPG)"
echo "✓ Dimensiones: 1024x1024 px (mínimo 512x512)"
echo "✓ Aspecto: Cuadrado (1:1 ratio)"
echo "✓ Padding: Dejar margen de ~10% alrededor"
echo "✓ Colores: Funciona en fondos claros y oscuros"
echo ""
echo "Para iOS:"
echo "  • NO usar transparencia (fondo sólido)"
echo "  • Bordes redondeados los aplica el sistema"
echo ""
echo "Para Android:"
echo "  • Puede tener transparencia"
echo "  • El sistema Android aplicará forma adaptativa"
echo ""

# Ofrecer generar iconos
read -p "¿Deseas generar los iconos ahora? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "generate_icons.sh" ]; then
        bash generate_icons.sh
    else
        echo "❌ No se encontró generate_icons.sh"
        echo "Ejecuta manualmente: bash generate_icons.sh"
    fi
fi
