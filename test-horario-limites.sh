#!/bin/bash

# Script de prueba para validar límites horarios en el backend
# Prueba casos de solapamiento de horarios

BASE_URL="http://localhost:3002"
TOKEN="$1"

if [ -z "$TOKEN" ]; then
  echo "❌ Error: Debes proporcionar el token de autenticación"
  echo "Uso: ./test-horario-limites.sh <TOKEN>"
  exit 1
fi

echo "============================================"
echo "🧪 PRUEBAS DE LÍMITES HORARIOS"
echo "============================================"
echo ""

# IDs de test (cambiar según tu BD)
PERIODO_ID="5e1499b6-a9aa-4589-9516-39c1b131ee9d"
GRUPO_ID="78031d74-49f3-4081-ae74-e89d8bf3dde5"
INSTITUCION_ID="01c818af-824a-4d14-be62-5cb26d5f5da4"

# Materias disponibles
MATERIA_CALC="810a3f03-557b-4050-9331-963a5d1eba40"  # Cálculo
MATERIA_FISI="fb77fb09-e7cf-4f44-a24c-3f9feab45f5b"  # Física
MATERIA_ESPAN="a5c4f8b1-5a2c-4f7e-b8e9-2c3f1d5a8b9f"  # Español

# Profesor
PROFESOR_ID="6a01c899-224f-44ac-8732-9d6c126f5427"

echo "📋 DATOS DE PRUEBA:"
echo "  Período: $PERIODO_ID"
echo "  Grupo: $GRUPO_ID"
echo "  Institución: $INSTITUCION_ID"
echo ""

# Función para hacer request POST
test_crear_horario() {
  local name=$1
  local hora_inicio=$2
  local hora_fin=$3
  local dia=$4
  local materia=$5
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📌 TEST: $name"
  echo "  Hora: $hora_inicio - $hora_fin (Día $dia)"
  echo "  Materia: $materia"
  echo ""
  
  RESPONSE=$(curl -s -X POST "$BASE_URL/horarios" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "{
      \"periodoId\": \"$PERIODO_ID\",
      \"grupoId\": \"$GRUPO_ID\",
      \"materiaId\": \"$materia\",
      \"profesorId\": \"$PROFESOR_ID\",
      \"diaSemana\": $dia,
      \"horaInicio\": \"$hora_inicio\",
      \"horaFin\": \"$hora_fin\",
      \"institucionId\": \"$INSTITUCION_ID\"
    }")
  
  # Mostrar respuesta formateada
  echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
  echo ""
}

# Función para obtener horarios
list_horarios() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📊 HORARIOS ACTUALES DEL GRUPO"
  echo ""
  
  RESPONSE=$(curl -s -X GET "$BASE_URL/horarios/grupo/$GRUPO_ID" \
    -H "Authorization: Bearer $TOKEN")
  
  echo "$RESPONSE" | jq '.data[] | {id, diaSemana, horaInicio, horaFin, materia: .materia.nombre}' 2>/dev/null || echo "$RESPONSE"
  echo ""
}

# ========== CASOS DE PRUEBA ==========

echo "🧪 CASO 1: Crear horario básico (Lunes 08:00-10:00)"
test_crear_horario "Horario 1" "08:00" "10:00" "1" "$MATERIA_CALC"

list_horarios

echo "🧪 CASO 2: Intentar crear horario que SE SOLAPA TOTALMENTE"
echo "           (Lunes 08:00-10:00) - DEBERÍA FALLAR ❌"
test_crear_horario "Horario conflicto total" "08:00" "10:00" "1" "$MATERIA_FISI"

echo "🧪 CASO 3: Intentar crear horario que EMPIEZA DURANTE OTRA CLASE"
echo "           (Lunes 09:00-11:00) - DEBERÍA FALLAR ❌"
test_crear_horario "Horario conflicto inicio" "09:00" "11:00" "1" "$MATERIA_ESPAN"

echo "🧪 CASO 4: Intentar crear horario que TERMINA DURANTE OTRA CLASE"
echo "           (Lunes 07:00-09:00) - DEBERÍA FALLAR ❌"
test_crear_horario "Horario conflicto fin" "07:00" "09:00" "1" "$MATERIA_CALC"

echo "🧪 CASO 5: Intentar crear horario que CONTIENE OTRA CLASE"
echo "           (Lunes 07:00-11:00) - DEBERÍA FALLAR ❌"
test_crear_horario "Horario conflicto contiene" "07:00" "11:00" "1" "$MATERIA_FISI"

echo "🧪 CASO 6: Crear horario EXACTAMENTE DESPUÉS"
echo "           (Lunes 10:00-12:00) - DEBERÍA FUNCIONAR ✅"
test_crear_horario "Horario sin conflicto" "10:00" "12:00" "1" "$MATERIA_ESPAN"

echo "🧪 CASO 7: Crear horario en OTRO DÍA"
echo "           (Martes 08:00-10:00) - DEBERÍA FUNCIONAR ✅"
test_crear_horario "Horario otro día" "08:00" "10:00" "2" "$MATERIA_CALC"

list_horarios

echo "✅ Pruebas completadas"
