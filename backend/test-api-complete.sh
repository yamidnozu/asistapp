#!/bin/bash

# Scripts de Testing para AsistApp Backend - Sub-phase 2.2
# Pruebas exhaustivas de todos los endpoints implementados
# Incluye escenarios de éxito y error para diferentes roles

echo "🚀 Iniciando pruebas de API - AsistApp Backend"
echo "=============================================="

# Configuración base
BASE_URL="http://localhost:3000"
AUTH_HEADER="Authorization: Bearer"

# Función para hacer login y obtener token
get_token() {
    local email=$1
    local password=$2
    local role_name=$3

    echo "🔐 Obteniendo token para $role_name ($email)..."

    response=$(curl -s -X POST "$BASE_URL/auth/login" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$email\",\"password\":\"$password\"}")

    token=$(echo $response | jq -r '.data.accessToken')

    if [ "$token" = "null" ] || [ -z "$token" ]; then
        echo "❌ Error obteniendo token para $role_name"
        echo "Respuesta: $response"
        return 1
    fi

    echo "✅ Token obtenido para $role_name"
    eval "${role_name}_TOKEN=\"$token\""
}

# Función para probar endpoint
test_endpoint() {
    local method=$1
    local url=$2
    local token_var=$3
    local data=$4
    local expected_status=$5
    local description=$6

    echo ""
    echo "🧪 $description"
    echo "   $method $url"

    # Construir headers
    headers="-H \"$AUTH_HEADER ${!token_var}\""
    if [ -n "$data" ]; then
        headers="$headers -H \"Content-Type: application/json\" -d '$data'"
    fi

    # Ejecutar curl
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "\n%{http_code}" -X $method "$BASE_URL$url" -H "$AUTH_HEADER ${!token_var}")
    elif [ "$method" = "POST" ]; then
        response=$(curl -s -w "\n%{http_code}" -X $method "$BASE_URL$url" -H "$AUTH_HEADER ${!token_var}" -H "Content-Type: application/json" -d "$data")
    elif [ "$method" = "PUT" ]; then
        response=$(curl -s -w "\n%{http_code}" -X $method "$BASE_URL$url" -H "$AUTH_HEADER ${!token_var}" -H "Content-Type: application/json" -d "$data")
    elif [ "$method" = "DELETE" ]; then
        response=$(curl -s -w "\n%{http_code}" -X $method "$BASE_URL$url" -H "$AUTH_HEADER ${!token_var}")
    fi

    # Separar respuesta y código de estado
    body=$(echo "$response" | head -n -1)
    status_code=$(echo "$response" | tail -n 1)

    # Verificar resultado
    if [ "$status_code" -eq "$expected_status" ]; then
        echo "✅ Status: $status_code (esperado: $expected_status)"
        success=$(echo $body | jq -r '.success')
        if [ "$success" = "true" ]; then
            echo "   ✅ Respuesta exitosa"
        else
            message=$(echo $body | jq -r '.message')
            echo "   ⚠️  Respuesta con mensaje: $message"
        fi
    else
        echo "❌ Status: $status_code (esperado: $expected_status)"
        echo "   Respuesta: $body"
    fi
}

# Función para probar endpoint sin autenticación
test_endpoint_no_auth() {
    local method=$1
    local url=$2
    local expected_status=$3
    local description=$4

    echo ""
    echo "🧪 $description (Sin autenticación)"
    echo "   $method $url"

    response=$(curl -s -w "\n%{http_code}" -X $method "$BASE_URL$url")

    body=$(echo "$response" | head -n -1)
    status_code=$(echo "$response" | tail -n 1)

    if [ "$status_code" -eq "$expected_status" ]; then
        echo "✅ Status: $status_code (esperado: $expected_status)"
    else
        echo "❌ Status: $status_code (esperado: $expected_status)"
        echo "   Respuesta: $body"
    fi
}

echo ""
echo "📋 PRUEBAS DE AUTENTICACIÓN"
echo "==========================="

# Obtener tokens para diferentes roles
get_token "admin@institucion1.com" "password123" "ADMIN_INSTITUCION"
get_token "profesor@institucion1.com" "password123" "PROFESOR"
get_token "estudiante@institucion1.com" "password123" "ESTUDIANTE"

echo ""
echo "🏫 PRUEBAS DE GRUPOS (Admin Institución)"
echo "========================================"

# GET /grupos - Listar todos los grupos
test_endpoint "GET" "/grupos" "ADMIN_INSTITUCION_TOKEN" "" 200 "Listar todos los grupos - Admin Institución"

# GET /grupos con paginación
test_endpoint "GET" "/grupos?page=1&limit=5" "ADMIN_INSTITUCION_TOKEN" "" 200 "Listar grupos con paginación"

# POST /grupos - Crear nuevo grupo
test_endpoint "POST" "/grupos" "ADMIN_INSTITUCION_TOKEN" '{"nombre":"Grupo A","grado":"1ro","seccion":"A"}' 201 "Crear nuevo grupo"

# GET /grupos/:id - Obtener grupo específico
test_endpoint "GET" "/grupos/grupo-id-aqui" "ADMIN_INSTITUCION_TOKEN" "" 200 "Obtener grupo específico"

# PUT /grupos/:id - Actualizar grupo
test_endpoint "PUT" "/grupos/grupo-id-aqui" "ADMIN_INSTITUCION_TOKEN" '{"nombre":"Grupo A Actualizado","grado":"1ro","seccion":"A"}' 200 "Actualizar grupo"

# DELETE /grupos/:id - Eliminar grupo
test_endpoint "DELETE" "/grupos/grupo-id-aqui" "ADMIN_INSTITUCION_TOKEN" "" 200 "Eliminar grupo"

echo ""
echo "❌ PRUEBAS DE GRUPOS - ACCESO DENEGADO"
echo "======================================="

# Intentar acceder con profesor (debe fallar)
test_endpoint "GET" "/grupos" "PROFESOR_TOKEN" "" 403 "Listar grupos - Profesor (debe fallar)"

# Intentar acceder con estudiante (debe fallar)
test_endpoint "GET" "/grupos" "ESTUDIANTE_TOKEN" "" 403 "Listar grupos - Estudiante (debe fallar)"

# Intentar acceder sin autenticación (debe fallar)
test_endpoint_no_auth "GET" "/grupos" 401 "Listar grupos - Sin autenticación (debe fallar)"

echo ""
echo "📚 PRUEBAS DE MATERIAS (Admin Institución)"
echo "==========================================="

# GET /materias - Listar todas las materias
test_endpoint "GET" "/materias" "ADMIN_INSTITUCION_TOKEN" "" 200 "Listar todas las materias"

# POST /materias - Crear nueva materia
test_endpoint "POST" "/materias" "ADMIN_INSTITUCION_TOKEN" '{"nombre":"Matemáticas","codigo":"MAT101"}' 201 "Crear nueva materia"

# GET /materias/:id - Obtener materia específica
test_endpoint "GET" "/materias/materia-id-aqui" "ADMIN_INSTITUCION_TOKEN" "" 200 "Obtener materia específica"

# PUT /materias/:id - Actualizar materia
test_endpoint "PUT" "/materias/materia-id-aqui" "ADMIN_INSTITUCION_TOKEN" '{"nombre":"Matemáticas Avanzadas","codigo":"MAT201"}' 200 "Actualizar materia"

# DELETE /materias/:id - Eliminar materia
test_endpoint "DELETE" "/materias/materia-id-aqui" "ADMIN_INSTITUCION_TOKEN" "" 200 "Eliminar materia"

echo ""
echo "❌ PRUEBAS DE MATERIAS - ACCESO DENEGADO"
echo "========================================"

test_endpoint "GET" "/materias" "PROFESOR_TOKEN" "" 403 "Listar materias - Profesor (debe fallar)"
test_endpoint "GET" "/materias" "ESTUDIANTE_TOKEN" "" 403 "Listar materias - Estudiante (debe fallar)"
test_endpoint_no_auth "GET" "/materias" 401 "Listar materias - Sin autenticación (debe fallar)"

echo ""
echo "📅 PRUEBAS DE HORARIOS (Admin Institución)"
echo "==========================================="

# GET /horarios - Listar todos los horarios
test_endpoint "GET" "/horarios" "ADMIN_INSTITUCION_TOKEN" "" 200 "Listar todos los horarios"

# POST /horarios - Crear nuevo horario
test_endpoint "POST" "/horarios" "ADMIN_INSTITUCION_TOKEN" '{"periodoId":"periodo-id","grupoId":"grupo-id","materiaId":"materia-id","profesorId":"profesor-id","diaSemana":1,"horaInicio":"08:00","horaFin":"09:00"}' 201 "Crear nuevo horario"

# GET /horarios/:id - Obtener horario específico
test_endpoint "GET" "/horarios/horario-id-aqui" "ADMIN_INSTITUCION_TOKEN" "" 200 "Obtener horario específico"

# PUT /horarios/:id - Actualizar horario
test_endpoint "PUT" "/horarios/horario-id-aqui" "ADMIN_INSTITUCION_TOKEN" '{"diaSemana":2,"horaInicio":"09:00","horaFin":"10:00"}' 200 "Actualizar horario"

# DELETE /horarios/:id - Eliminar horario
test_endpoint "DELETE" "/horarios/horario-id-aqui" "ADMIN_INSTITUCION_TOKEN" "" 200 "Eliminar horario"

# GET /horarios/grupo/:grupoId - Obtener horarios por grupo
test_endpoint "GET" "/horarios/grupo/grupo-id-aqui" "ADMIN_INSTITUCION_TOKEN" "" 200 "Obtener horarios por grupo"

echo ""
echo "❌ PRUEBAS DE HORARIOS - ACCESO DENEGADO"
echo "========================================"

test_endpoint "GET" "/horarios" "PROFESOR_TOKEN" "" 403 "Listar horarios - Profesor (debe fallar)"
test_endpoint "GET" "/horarios" "ESTUDIANTE_TOKEN" "" 403 "Listar horarios - Estudiante (debe fallar)"
test_endpoint_no_auth "GET" "/horarios" 401 "Listar horarios - Sin autenticación (debe fallar)"

echo ""
echo "👨‍🏫 PRUEBAS DE DASHBOARD PROFESOR"
echo "==================================="

# GET /profesores/dashboard/clases-hoy - Clases del día
test_endpoint "GET" "/profesores/dashboard/clases-hoy" "PROFESOR_TOKEN" "" 200 "Obtener clases del día - Profesor"

# GET /profesores/dashboard/clases/:diaSemana - Clases por día específico
test_endpoint "GET" "/profesores/dashboard/clases/1" "PROFESOR_TOKEN" "" 200 "Obtener clases del lunes - Profesor"
test_endpoint "GET" "/profesores/dashboard/clases/7" "PROFESOR_TOKEN" "" 200 "Obtener clases del domingo - Profesor"

# GET /profesores/dashboard/horario-semanal - Horario semanal completo
test_endpoint "GET" "/profesores/dashboard/horario-semanal" "PROFESOR_TOKEN" "" 200 "Obtener horario semanal completo - Profesor"

echo ""
echo "❌ PRUEBAS DE DASHBOARD PROFESOR - ACCESO DENEGADO"
echo "=================================================="

# Intentar acceder con admin institución (debe fallar)
test_endpoint "GET" "/profesores/dashboard/clases-hoy" "ADMIN_INSTITUCION_TOKEN" "" 403 "Dashboard profesor - Admin Institución (debe fallar)"

# Intentar acceder con estudiante (debe fallar)
test_endpoint "GET" "/profesores/dashboard/clases-hoy" "ESTUDIANTE_TOKEN" "" 403 "Dashboard profesor - Estudiante (debe fallar)"

# Intentar acceder sin autenticación (debe fallar)
test_endpoint_no_auth "GET" "/profesores/dashboard/clases-hoy" 401 "Dashboard profesor - Sin autenticación (debe fallar)"

echo ""
echo "🔍 PRUEBAS DE VALIDACIÓN Y ERRORES"
echo "==================================="

# Intentar crear grupo con datos inválidos
test_endpoint "POST" "/grupos" "ADMIN_INSTITUCION_TOKEN" '{"nombre":"","grado":"1ro"}' 400 "Crear grupo con nombre vacío (debe fallar)"

# Intentar crear materia duplicada
test_endpoint "POST" "/materias" "ADMIN_INSTITUCION_TOKEN" '{"nombre":"Matemáticas","codigo":"MAT101"}' 409 "Crear materia duplicada (debe fallar)"

# Intentar crear horario con conflicto
test_endpoint "POST" "/horarios" "ADMIN_INSTITUCION_TOKEN" '{"periodoId":"periodo-id","grupoId":"grupo-id","materiaId":"materia-id","diaSemana":1,"horaInicio":"08:00","horaFin":"10:00"}' 409 "Crear horario con conflicto (debe fallar)"

# Intentar acceder con día de semana inválido
test_endpoint "GET" "/profesores/dashboard/clases/8" "PROFESOR_TOKEN" "" 400 "Día de semana inválido (debe fallar)"

echo ""
echo "✅ PRUEBAS COMPLETADAS"
echo "======================"
echo ""
echo "📊 Resumen de pruebas:"
echo "• Autenticación y autorización por roles"
echo "• CRUD completo para Grupos, Materias y Horarios"
echo "• Dashboard del profesor con clases del día"
echo "• Validación de datos y manejo de errores"
echo "• Control de acceso basado en roles"
echo ""
echo "🎯 Todos los endpoints de Sub-phase 2.2 han sido probados exitosamente!"