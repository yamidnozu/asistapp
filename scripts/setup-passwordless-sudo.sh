#!/bin/bash
# Script para configurar passwordless sudo para el usuario de deployment
# Ejecuta esto EN LA VPS como root o con sudo

echo "🔧 Configurando passwordless sudo..."

# Obtener el usuario actual
DEPLOY_USER=$(whoami)

echo "Usuario de deployment: $DEPLOY_USER"

# Si ya es root, no necesita sudo
if [ "$DEPLOY_USER" = "root" ]; then
    echo "✅ Usuario es root, no necesita configuración adicional"
    echo "⚠️  Sin embargo, el workflow está fallando. Verifica:"
    echo "   1. Que VPS_USER en GitHub Secrets sea 'root'"
    echo "   2. Que la SSH key esté correctamente configurada"
    exit 0
fi

# Configurar passwordless sudo para usuario no-root
echo "$DEPLOY_USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$DEPLOY_USER > /dev/null
sudo chmod 0440 /etc/sudoers.d/$DEPLOY_USER

echo "✅ Passwordless sudo configurado para $DEPLOY_USER"
echo ""
echo "Verificando..."
if sudo -n true 2>/dev/null; then
    echo "✅ Verificación exitosa - passwordless sudo funciona"
else
    echo "❌ Verificación falló - intenta cerrar sesión y volver a entrar"
fi

echo ""
echo "🎯 Ahora puedes re-ejecutar el workflow en GitHub Actions"
