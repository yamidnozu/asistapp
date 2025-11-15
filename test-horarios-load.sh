#!/bin/bash
# Test rápido para verificar que los horarios se están cargando correctamente

API_URL="http://localhost:3002"
ADMIN_EMAIL="admin@sanjose.edu"
ADMIN_PASSWORD="SanJose123!"

echo "🧪 TEST: Verificar carga de horarios"
echo "===================================="
echo ""

# 1. Login
echo "1️⃣  Autenticándome..."
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$ADMIN_EMAIL\",
    \"password\": \"$ADMIN_PASSWORD\"
  }")

TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)
if [ -z "$TOKEN" ]; then
  echo "❌ Error: No se pudo obtener token"
  echo "Respuesta: $LOGIN_RESPONSE"
  exit 1
fi
echo "✅ Token obtenido"
echo ""

# 2. Obtener períodos
echo "2️⃣  Obteniendo períodos académicos..."
PERIODOS=$(curl -s -X GET "$API_URL/periodos-academicos" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

PERIODO_ID=$(echo $PERIODOS | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
if [ -z "$PERIODO_ID" ]; then
  echo "❌ Error: No se encontraron períodos"
  exit 1
fi
echo "✅ Período encontrado: $PERIODO_ID"
echo ""

# 3. Obtener grupos
echo "3️⃣  Obteniendo grupos..."
GRUPOS=$(curl -s -X GET "$API_URL/grupos" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

GRUPO_ID=$(echo $GRUPOS | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
GRUPO_NOMBRE=$(echo $GRUPOS | grep -o '"nombre":"[^"]*' | head -1 | cut -d'"' -f4)
if [ -z "$GRUPO_ID" ]; then
  echo "❌ Error: No se encontraron grupos"
  exit 1
fi
echo "✅ Grupo encontrado: $GRUPO_NOMBRE ($GRUPO_ID)"
echo ""

# 4. Obtener horarios del grupo
echo "4️⃣  Obteniendo horarios del grupo..."
HORARIOS=$(curl -s -X GET "$API_URL/horarios/grupo/$GRUPO_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

HORARIO_COUNT=$(echo $HORARIOS | grep -o '"id"' | wc -l)
echo "✅ Horarios encontrados: $HORARIO_COUNT"
echo ""

# 5. Mostrar horarios
echo "5️⃣  Horarios del grupo '$GRUPO_NOMBRE':"
echo "===================================="
echo $HORARIOS | python3 -m json.tool 2>/dev/null | grep -E '"nombre"|"diaSemana"|"horaInicio"|"horaFin"|"diaSemanaNombre"' | head -20

echo ""
echo "✅ TEST COMPLETADO"
