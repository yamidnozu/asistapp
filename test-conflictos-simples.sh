#!/bin/bash

# Script de prueba de límites horarios

echo "🔐 Obteniendo token..."

TOKEN_RESPONSE=$(curl -s -X POST "http://localhost:3002/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@sanjose.edu","password":"SanJose123!"}')

TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "❌ Error: No se pudo obtener el token"
  exit 1
fi

echo "✅ Token obtenido: ${TOKEN:0:20}..."
echo ""

BASE_URL="http://localhost:3002"
GRUPO_ID="78031d74-49f3-4081-ae74-e89d8bf3dde5"
PERIODO_ID="5e1499b6-a9aa-4589-9516-39c1b131ee9d"
INSTITUCION_ID="01c818af-824a-4d14-be62-5cb26d5f5da4"
MATERIA_CALC="810a3f03-557b-4050-9331-963a5d1eba40"
MATERIA_FISI="fb77fb09-e7cf-4f44-a24c-3f9feab45f5b"
PROFESOR_ID="6a01c899-224f-44ac-8732-9d6c126f5427"

echo "============================================"
echo "🧪 PRUEBA 1: Crear horario base (08:00-10:00 Lunes)"
echo "============================================"

RESP1=$(curl -s -X POST "$BASE_URL/horarios" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"periodoId\": \"$PERIODO_ID\",
    \"grupoId\": \"$GRUPO_ID\",
    \"materiaId\": \"$MATERIA_CALC\",
    \"profesorId\": \"$PROFESOR_ID\",
    \"diaSemana\": 1,
    \"horaInicio\": \"08:00\",
    \"horaFin\": \"10:00\",
    \"institucionId\": \"$INSTITUCION_ID\"
  }")

echo "$RESP1" | grep -q '"success":true'
if [ $? -eq 0 ]; then
  echo "✅ PASÓ: Horario creado correctamente"
else
  echo "❌ FALLÓ: No se creó el horario"
  echo "$RESP1"
fi
echo ""

echo "============================================"
echo "🧪 PRUEBA 2: Intentar crear conflicto TOTAL (08:00-10:00 Lunes)"
echo "============================================"

RESP2=$(curl -s -X POST "$BASE_URL/horarios" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"periodoId\": \"$PERIODO_ID\",
    \"grupoId\": \"$GRUPO_ID\",
    \"materiaId\": \"$MATERIA_FISI\",
    \"profesorId\": null,
    \"diaSemana\": 1,
    \"horaInicio\": \"08:00\",
    \"horaFin\": \"10:00\",
    \"institucionId\": \"$INSTITUCION_ID\"
  }")

echo "$RESP2" | grep -q '"success":false'
if [ $? -eq 0 ]; then
  echo "✅ PASÓ: Conflicto detectado correctamente"
  echo "$RESP2" | grep -o '"error":"[^"]*' | cut -d'"' -f4
else
  echo "❌ FALLÓ: Debería haber rechazado el conflicto"
  echo "$RESP2"
fi
echo ""

echo "============================================"
echo "🧪 PRUEBA 3: Crear horario SIN conflicto (10:00-12:00 Lunes)"
echo "============================================"

RESP3=$(curl -s -X POST "$BASE_URL/horarios" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"periodoId\": \"$PERIODO_ID\",
    \"grupoId\": \"$GRUPO_ID\",
    \"materiaId\": \"$MATERIA_FISI\",
    \"profesorId\": null,
    \"diaSemana\": 1,
    \"horaInicio\": \"10:00\",
    \"horaFin\": \"12:00\",
    \"institucionId\": \"$INSTITUCION_ID\"
  }")

echo "$RESP3" | grep -q '"success":true'
if [ $? -eq 0 ]; then
  echo "✅ PASÓ: Horario sin conflicto creado correctamente"
else
  echo "❌ FALLÓ: No se debería haber rechazado"
  echo "$RESP3"
fi
echo ""

echo "============================================"
echo "🧪 PRUEBA 4: Intentar crear conflicto PARCIAL inicio (09:00-11:00 Lunes)"
echo "============================================"

RESP4=$(curl -s -X POST "$BASE_URL/horarios" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"periodoId\": \"$PERIODO_ID\",
    \"grupoId\": \"$GRUPO_ID\",
    \"materiaId\": \"$MATERIA_CALC\",
    \"profesorId\": null,
    \"diaSemana\": 1,
    \"horaInicio\": \"09:00\",
    \"horaFin\": \"11:00\",
    \"institucionId\": \"$INSTITUCION_ID\"
  }")

echo "$RESP4" | grep -q '"success":false'
if [ $? -eq 0 ]; then
  echo "✅ PASÓ: Conflicto parcial detectado"
  echo "$RESP4" | grep -o '"error":"[^"]*' | cut -d'"' -f4
else
  echo "❌ FALLÓ: Debería haber detectado el conflicto"
  echo "$RESP4"
fi
echo ""

echo "============================================"
echo "✅ PRUEBAS COMPLETADAS"
echo "============================================"
