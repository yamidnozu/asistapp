#!/bin/bash
# Script de auto-configuración completa para producción
# Se ejecuta automáticamente por el workflow de GitHub Actions
# NO requiere intervención manual

set -e

echo "=========================================="
echo "🚀 AUTO-CONFIGURACIÓN PRODUCCIÓN"
echo "=========================================="
echo ""

# Determinar si necesitamos sudo
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO=sudo
        if ! $SUDO -n true 2>/dev/null; then
            echo "❌ Error: User '$(whoami)' requires password for sudo."
            exit 1
        fi
    else
        echo "❌ Error: Need root or sudo"
        exit 1
    fi
fi

# 1. Verificar que existen las variables necesarias en .env
echo "1️⃣  Verificando archivo .env..."
if [ ! -f /opt/asistapp/.env ]; then
    echo "❌ Archivo .env no existe. El workflow debería haberlo creado."
    exit 1
fi

echo "✅ Archivo .env existe"

# 2. Verificar/Crear Firebase Service Account si la variable existe
echo ""
echo "2️⃣  Configurando Firebase Service Account..."
if [ -n "$FIREBASE_SERVICE_ACCOUNT_JSON" ]; then
    echo "$FIREBASE_SERVICE_ACCOUNT_JSON" | $SUDO tee /opt/asistapp/firebase-service-account.json > /dev/null
    $SUDO chmod 600 /opt/asistapp/firebase-service-account.json
    echo "✅ Firebase Service Account configurado"
    
    # Verificar que es un JSON válido
    if command -v jq >/dev/null 2>&1; then
        if jq empty /opt/asistapp/firebase-service-account.json 2>/dev/null; then
            PROJECT_ID=$(jq -r '.project_id' /opt/asistapp/firebase-service-account.json)
            echo "✅ JSON válido - Project ID: $PROJECT_ID"
        else
            echo "⚠️  JSON inválido, pero continuando..."
        fi
    fi
else
    echo "⚠️  FIREBASE_SERVICE_ACCOUNT_JSON no configurado"
    # Crear archivo vacío para que el volumen no falle
    echo '{}' | $SUDO tee /opt/asistapp/firebase-service-account.json > /dev/null
    $SUDO chmod 600 /opt/asistapp/firebase-service-account.json
fi

# 3. Actualizar docker-compose.prod.yml para incluir volumen de Firebase
echo ""
echo "3️⃣  Actualizando docker-compose.prod.yml..."

# Verificar si ya tiene la configuración del volumen
if grep -q "firebase-service-account.json" /opt/asistapp/docker-compose.prod.yml; then
    echo "✅ docker-compose.prod.yml ya tiene configuración de Firebase"
else
    echo "⚠️  Agregando configuración de Firebase a docker-compose.prod.yml"
    # Hacer backup
    $SUDO cp /opt/asistapp/docker-compose.prod.yml /opt/asistapp/docker-compose.prod.yml.pre-firebase-backup
    
    # Insertar la sección de volumes antes de depends_on
    # Esto es una solución temporal - el workflow debería generar el archivo completo
    echo "⚠️  Se necesita regenerar docker-compose.prod.yml desde el workflow"
fi

# 4. Mostrar resumen de configuración
echo ""
echo "=========================================="
echo "📋 RESUMEN DE CONFIGURACIÓN"
echo "=========================================="
echo ""

echo "Variables en .env:"
grep -E '^[A-Z_]+=.+' /opt/asistapp/.env | cut -d= -f1 | sort | sed 's/^/  ✓ /'

echo ""
echo "Archivos críticos:"
[ -f /opt/asistapp/.env ] && echo "  ✓ .env" || echo "  ✗ .env"
[ -f /opt/asistapp/firebase-service-account.json ] && echo "  ✓ firebase-service-account.json" || echo "  ✗ firebase-service-account.json"
[ -f /opt/asistapp/docker-compose.prod.yml ] && echo "  ✓ docker-compose.prod.yml" || echo "  ✗ docker-compose.prod.yml"

echo ""
echo "✅ Auto-configuración completada"
echo ""
