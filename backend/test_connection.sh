#!/bin/bash

# Script para probar la conexión al backend de AsistApp desde la red local

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SERVER_IP="192.168.20.22"
SERVER_PORT="3000"
BASE_URL="http://${SERVER_IP}:${SERVER_PORT}"

echo "======================================"
echo "Probando conexión a AsistApp Backend"
echo "======================================"
echo ""
echo "URL: ${BASE_URL}"
echo ""

# Test 1: Prueba básica de conectividad
echo "1. Prueba de conectividad básica..."
response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "${BASE_URL}/")

if [ "$response" == "200" ]; then
    echo -e "${GREEN}✓ Conectado exitosamente (HTTP 200)${NC}"
    
    # Mostrar respuesta completa
    echo ""
    echo "Respuesta del servidor:"
    curl -s "${BASE_URL}/" | json_pp 2>/dev/null || curl -s "${BASE_URL}/"
else
    echo -e "${RED}✗ Error de conexión (HTTP ${response})${NC}"
    echo ""
    echo "Posibles causas:"
    echo "  - El backend no está corriendo"
    echo "  - El firewall está bloqueando el puerto 3000"
    echo "  - No estás en la misma red que el servidor"
    echo "  - La IP del servidor ha cambiado"
    exit 1
fi

echo ""
echo "======================================"

# Test 2: Prueba de login
echo "2. Prueba de login con credenciales de prueba..."
login_response=$(curl -s -X POST "${BASE_URL}/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@asistapp.com","password":"admin123"}')

if echo "$login_response" | grep -q "accessToken"; then
    echo -e "${GREEN}✓ Login exitoso${NC}"
    echo ""
    echo "Respuesta del login:"
    echo "$login_response" | json_pp 2>/dev/null || echo "$login_response"
else
    echo -e "${YELLOW}⚠ Login falló o no configurado${NC}"
    echo "Respuesta:"
    echo "$login_response" | json_pp 2>/dev/null || echo "$login_response"
fi

echo ""
echo "======================================"
echo "Pruebas completadas"
echo "======================================"
