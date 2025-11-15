#!/bin/bash

# Script para obtener token y ejecutar pruebas

BASE_URL="http://localhost:3002"

echo "🔐 Obteniendo token de autenticación..."
echo ""

# Usar credenciales de admin
TOKEN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "admin123"
  }')

echo "📨 Respuesta de login:"
echo "$TOKEN_RESPONSE" | jq '.' 2>/dev/null || echo "$TOKEN_RESPONSE"
echo ""

# Extraer token
TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.data.accessToken' 2>/dev/null)

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "❌ Error: No se pudo obtener el token"
  echo "Respuesta completa:"
  echo "$TOKEN_RESPONSE" | jq '.'
  exit 1
fi

echo "✅ Token obtenido: ${TOKEN:0:20}..."
echo ""

# Ejecutar pruebas
bash /c/Proyectos/DemoLife/test-horario-limites.sh "$TOKEN"
