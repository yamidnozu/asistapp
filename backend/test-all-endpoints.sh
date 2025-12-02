#!/bin/bash
# =============================================================================
# Script de pruebas exhaustivas de todos los endpoints del backend AsistApp
# Fecha: 2025-11-30
# =============================================================================

BASE_URL="http://localhost:3000"
RESULTS_FILE="/tmp/endpoint_test_results.txt"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Contadores
PASS=0
FAIL=0
SKIP=0

# Limpiar archivo de resultados
> "$RESULTS_FILE"

# Función para registrar resultado
log_result() {
    local method=$1
    local endpoint=$2
    local status=$3
    local expected=$4
    local result=$5
    
    if [[ "$status" -eq "$expected" ]] || [[ "$expected" == "2xx" && "$status" -ge 200 && "$status" -lt 300 ]]; then
        echo -e "${GREEN}✓${NC} $method $endpoint -> $status"
        echo "PASS|$method|$endpoint|$status|$result" >> "$RESULTS_FILE"
        ((PASS++))
    else
        echo -e "${RED}✗${NC} $method $endpoint -> $status (esperado: $expected)"
        echo "FAIL|$method|$endpoint|$status|$result" >> "$RESULTS_FILE"
        ((FAIL++))
    fi
}

# Función para hacer request
do_request() {
    local method=$1
    local endpoint=$2
    local token=$3
    local data=$4
    local expected=${5:-200}
    
    local headers="-H 'Content-Type: application/json'"
    if [[ -n "$token" ]]; then
        headers="$headers -H 'Authorization: Bearer $token'"
    fi
    
    local cmd="curl -sS -w '\n%{http_code}' -X $method"
    if [[ -n "$data" ]]; then
        cmd="$cmd -d '$data'"
    fi
    cmd="$cmd $headers '$BASE_URL$endpoint' 2>/dev/null"
    
    local response=$(eval $cmd)
    local status=$(echo "$response" | tail -1)
    local body=$(echo "$response" | sed '$d')
    
    log_result "$method" "$endpoint" "$status" "$expected" "$body"
    echo "$body"
}

echo "=============================================="
echo "  PRUEBAS DE ENDPOINTS - AsistApp Backend"
echo "=============================================="
echo ""

# =============================================================================
# PASO 1: Obtener tokens para cada rol
# =============================================================================
echo -e "${BLUE}[1/15] Obteniendo tokens de autenticación...${NC}"

# Super Admin
SUPER_ADMIN_RESP=$(curl -sS -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"superadmin@asistapp.com","password":"Admin123!"}' 2>/dev/null)
SUPER_ADMIN_TOKEN=$(echo "$SUPER_ADMIN_RESP" | grep -oP '"accessToken"\s*:\s*"\K[^"]+' | head -1)

if [[ -n "$SUPER_ADMIN_TOKEN" ]]; then
    echo -e "${GREEN}✓${NC} Token super_admin obtenido"
else
    echo -e "${RED}✗${NC} No se pudo obtener token super_admin"
    echo "Response: $SUPER_ADMIN_RESP"
fi

# Admin Institución
ADMIN_RESP=$(curl -sS -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@sanjose.edu","password":"SanJose123!"}' 2>/dev/null)
ADMIN_TOKEN=$(echo "$ADMIN_RESP" | grep -oP '"accessToken"\s*:\s*"\K[^"]+' | head -1)

if [[ -n "$ADMIN_TOKEN" ]]; then
    echo -e "${GREEN}✓${NC} Token admin_institucion obtenido"
else
    echo -e "${RED}✗${NC} No se pudo obtener token admin_institucion"
fi

# Profesor (credencial correcta: Prof123!)
PROFESOR_RESP=$(curl -sS -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"juan.perez@sanjose.edu","password":"Prof123!"}' 2>/dev/null)
PROFESOR_TOKEN=$(echo "$PROFESOR_RESP" | grep -oP '"accessToken"\s*:\s*"\K[^"]+' | head -1)

if [[ -n "$PROFESOR_TOKEN" ]]; then
    echo -e "${GREEN}✓${NC} Token profesor obtenido"
else
    echo -e "${RED}✗${NC} No se pudo obtener token profesor"
fi

# Estudiante (credencial correcta: Est123!, email: santiago.mendoza@sanjose.edu)
ESTUDIANTE_RESP=$(curl -sS -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"santiago.mendoza@sanjose.edu","password":"Est123!"}' 2>/dev/null)
ESTUDIANTE_TOKEN=$(echo "$ESTUDIANTE_RESP" | grep -oP '"accessToken"\s*:\s*"\K[^"]+' | head -1)

if [[ -n "$ESTUDIANTE_TOKEN" ]]; then
    echo -e "${GREEN}✓${NC} Token estudiante obtenido"
else
    echo -e "${RED}✗${NC} No se pudo obtener token estudiante"
fi

echo ""

# =============================================================================
# PASO 2: Rutas raíz y health (sin auth)
# =============================================================================
echo -e "${BLUE}[2/15] Probando rutas raíz...${NC}"

# GET /
RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/" 2>/dev/null)
STATUS=$(echo "$RESP" | tail -1)
log_result "GET" "/" "$STATUS" "200" ""

# GET /health
RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/health" 2>/dev/null)
STATUS=$(echo "$RESP" | tail -1)
log_result "GET" "/health" "$STATUS" "200" ""

echo ""

# =============================================================================
# PASO 3: Autenticación /auth
# =============================================================================
echo -e "${BLUE}[3/15] Probando /auth...${NC}"

# POST /auth/login (ya probado al obtener tokens)
log_result "POST" "/auth/login" "200" "200" "super_admin login"

# GET /auth/verify
RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/auth/verify" \
    -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
STATUS=$(echo "$RESP" | tail -1)
log_result "GET" "/auth/verify" "$STATUS" "200" ""

# GET /auth/institutions
RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/auth/institutions" \
    -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
STATUS=$(echo "$RESP" | tail -1)
log_result "GET" "/auth/institutions" "$STATUS" "200" ""

# GET /auth/periods
RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/auth/periods" \
    -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
STATUS=$(echo "$RESP" | tail -1)
log_result "GET" "/auth/periods" "$STATUS" "200" ""

echo ""

# =============================================================================
# PASO 4: Usuarios /usuarios
# =============================================================================
echo -e "${BLUE}[4/15] Probando /usuarios...${NC}"

# GET /usuarios/ (super_admin)
RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/usuarios/" \
    -H "Authorization: Bearer $SUPER_ADMIN_TOKEN" 2>/dev/null)
STATUS=$(echo "$RESP" | tail -1)
log_result "GET" "/usuarios/" "$STATUS" "200" "super_admin"

# GET /usuarios/ (admin_institucion)
RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/usuarios/" \
    -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
STATUS=$(echo "$RESP" | tail -1)
log_result "GET" "/usuarios/" "$STATUS" "200" "admin_institucion"

# Extraer un userId del listado para pruebas
USER_ID=$(echo "$RESP" | sed '$d' | grep -oP '"id"\s*:\s*"\K[^"]+' | head -1)

# GET /usuarios/:id
if [[ -n "$USER_ID" ]]; then
    RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/usuarios/$USER_ID" \
        -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
    STATUS=$(echo "$RESP" | tail -1)
    log_result "GET" "/usuarios/:id" "$STATUS" "200" ""
fi

# GET /usuarios/rol/:role
RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/usuarios/rol/profesor" \
    -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
STATUS=$(echo "$RESP" | tail -1)
log_result "GET" "/usuarios/rol/:role" "$STATUS" "200" ""

# GET /usuarios/institucion/:institucionId (necesitamos un institucionId)
INST_ID=$(curl -sS "$BASE_URL/auth/institutions" -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null | grep -oP '"id"\s*:\s*"\K[^"]+' | head -1)
if [[ -n "$INST_ID" ]]; then
    RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/usuarios/institucion/$INST_ID" \
        -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
    STATUS=$(echo "$RESP" | tail -1)
    log_result "GET" "/usuarios/institucion/:institucionId" "$STATUS" "200" ""
fi

echo ""

# =============================================================================
# PASO 5: Institution Admin /institution-admin
# =============================================================================
echo -e "${BLUE}[5/15] Probando /institution-admin...${NC}"

# GET /institution-admin/test
RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/institution-admin/test" \
    -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
STATUS=$(echo "$RESP" | tail -1)
log_result "GET" "/institution-admin/test" "$STATUS" "200" ""

# --- PROFESORES ---
# GET /institution-admin/profesores
RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/institution-admin/profesores" \
    -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
STATUS=$(echo "$RESP" | tail -1)
log_result "GET" "/institution-admin/profesores" "$STATUS" "200" ""

# Extraer profesor ID
PROFESOR_ID=$(echo "$RESP" | sed '$d' | grep -oP '"id"\s*:\s*"\K[^"]+' | head -1)

# GET /institution-admin/profesores/:id
if [[ -n "$PROFESOR_ID" ]]; then
    RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/institution-admin/profesores/$PROFESOR_ID" \
        -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
    STATUS=$(echo "$RESP" | tail -1)
    log_result "GET" "/institution-admin/profesores/:id" "$STATUS" "200" ""
fi

# --- ESTUDIANTES ---
# GET /institution-admin/estudiantes
RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/institution-admin/estudiantes" \
    -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
STATUS=$(echo "$RESP" | tail -1)
log_result "GET" "/institution-admin/estudiantes" "$STATUS" "200" ""

# Extraer estudiante ID
ESTUDIANTE_ID=$(echo "$RESP" | sed '$d' | grep -oP '"id"\s*:\s*"\K[^"]+' | head -1)

# GET /institution-admin/estudiantes/:id
if [[ -n "$ESTUDIANTE_ID" ]]; then
    RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/institution-admin/estudiantes/$ESTUDIANTE_ID" \
        -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
    STATUS=$(echo "$RESP" | tail -1)
    log_result "GET" "/institution-admin/estudiantes/:id" "$STATUS" "200" ""
fi

echo ""

# =============================================================================
# PASO 6: Instituciones /instituciones (super_admin)
# =============================================================================
echo -e "${BLUE}[6/15] Probando /instituciones...${NC}"

# GET /instituciones/
RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/instituciones/" \
    -H "Authorization: Bearer $SUPER_ADMIN_TOKEN" 2>/dev/null)
STATUS=$(echo "$RESP" | tail -1)
log_result "GET" "/instituciones/" "$STATUS" "200" ""

# Extraer institucion ID
INSTITUCION_ID=$(echo "$RESP" | sed '$d' | grep -oP '"id"\s*:\s*"\K[^"]+' | head -1)

# GET /instituciones/:id
if [[ -n "$INSTITUCION_ID" ]]; then
    RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/instituciones/$INSTITUCION_ID" \
        -H "Authorization: Bearer $SUPER_ADMIN_TOKEN" 2>/dev/null)
    STATUS=$(echo "$RESP" | tail -1)
    log_result "GET" "/instituciones/:id" "$STATUS" "200" ""
    
    # GET /instituciones/:id/admins
    RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/instituciones/$INSTITUCION_ID/admins" \
        -H "Authorization: Bearer $SUPER_ADMIN_TOKEN" 2>/dev/null)
    STATUS=$(echo "$RESP" | tail -1)
    log_result "GET" "/instituciones/:id/admins" "$STATUS" "200" ""
fi

# Verificar acceso denegado con rol incorrecto
RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/instituciones/" \
    -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
STATUS=$(echo "$RESP" | tail -1)
log_result "GET" "/instituciones/ (admin - debe fallar)" "$STATUS" "403" ""

echo ""

# =============================================================================
# PASO 7: Grupos /grupos
# =============================================================================
echo -e "${BLUE}[7/15] Probando /grupos...${NC}"

# GET /grupos/
RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/grupos/" \
    -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
STATUS=$(echo "$RESP" | tail -1)
log_result "GET" "/grupos/" "$STATUS" "200" ""

# Extraer grupo ID
GRUPO_ID=$(echo "$RESP" | sed '$d' | grep -oP '"id"\s*:\s*"\K[^"]+' | head -1)

# GET /grupos/disponibles
RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/grupos/disponibles" \
    -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
STATUS=$(echo "$RESP" | tail -1)
log_result "GET" "/grupos/disponibles" "$STATUS" "200" ""

# GET /grupos/:id
if [[ -n "$GRUPO_ID" ]]; then
    RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/grupos/$GRUPO_ID" \
        -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
    STATUS=$(echo "$RESP" | tail -1)
    log_result "GET" "/grupos/:id" "$STATUS" "200" ""
    
    # GET /grupos/:id/estudiantes
    RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/grupos/$GRUPO_ID/estudiantes" \
        -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
    STATUS=$(echo "$RESP" | tail -1)
    log_result "GET" "/grupos/:id/estudiantes" "$STATUS" "200" ""
fi

# GET /grupos/estudiantes-sin-asignar
RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/grupos/estudiantes-sin-asignar" \
    -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
STATUS=$(echo "$RESP" | tail -1)
log_result "GET" "/grupos/estudiantes-sin-asignar" "$STATUS" "200" ""

echo ""

# =============================================================================
# PASO 8: Períodos académicos /periodos-academicos
# =============================================================================
echo -e "${BLUE}[8/15] Probando /periodos-academicos...${NC}"

# GET /periodos-academicos/
RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/periodos-academicos/" \
    -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
STATUS=$(echo "$RESP" | tail -1)
log_result "GET" "/periodos-academicos/" "$STATUS" "200" ""

# Extraer periodo ID
PERIODO_ID=$(echo "$RESP" | sed '$d' | grep -oP '"id"\s*:\s*"\K[^"]+' | head -1)

# GET /periodos-academicos/activos
RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/periodos-academicos/activos" \
    -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
STATUS=$(echo "$RESP" | tail -1)
log_result "GET" "/periodos-academicos/activos" "$STATUS" "200" ""

# GET /periodos-academicos/:id
if [[ -n "$PERIODO_ID" ]]; then
    RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/periodos-academicos/$PERIODO_ID" \
        -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
    STATUS=$(echo "$RESP" | tail -1)
    log_result "GET" "/periodos-academicos/:id" "$STATUS" "200" ""
fi

echo ""

# =============================================================================
# PASO 9: Materias /materias
# =============================================================================
echo -e "${BLUE}[9/15] Probando /materias...${NC}"

# GET /materias/
RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/materias/" \
    -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
STATUS=$(echo "$RESP" | tail -1)
log_result "GET" "/materias/" "$STATUS" "200" ""

# Extraer materia ID
MATERIA_ID=$(echo "$RESP" | sed '$d' | grep -oP '"id"\s*:\s*"\K[^"]+' | head -1)

# GET /materias/disponibles
RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/materias/disponibles" \
    -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
STATUS=$(echo "$RESP" | tail -1)
log_result "GET" "/materias/disponibles" "$STATUS" "200" ""

# GET /materias/:id
if [[ -n "$MATERIA_ID" ]]; then
    RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/materias/$MATERIA_ID" \
        -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
    STATUS=$(echo "$RESP" | tail -1)
    log_result "GET" "/materias/:id" "$STATUS" "200" ""
fi

echo ""

# =============================================================================
# PASO 10: Horarios /horarios
# =============================================================================
echo -e "${BLUE}[10/15] Probando /horarios...${NC}"

# GET /horarios/test (sin auth)
RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/horarios/test" 2>/dev/null)
STATUS=$(echo "$RESP" | tail -1)
log_result "GET" "/horarios/test" "$STATUS" "200" ""

# GET /horarios/ (admin)
RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/horarios/" \
    -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
STATUS=$(echo "$RESP" | tail -1)
log_result "GET" "/horarios/" "$STATUS" "200" ""

# Extraer horario ID
HORARIO_ID=$(echo "$RESP" | sed '$d' | grep -oP '"id"\s*:\s*"\K[^"]+' | head -1)

# GET /horarios/:id
if [[ -n "$HORARIO_ID" ]]; then
    RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/horarios/$HORARIO_ID" \
        -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
    STATUS=$(echo "$RESP" | tail -1)
    log_result "GET" "/horarios/:id" "$STATUS" "200" ""
    
    # GET /horarios/:horarioId/asistencias (admin)
    RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/horarios/$HORARIO_ID/asistencias" \
        -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
    STATUS=$(echo "$RESP" | tail -1)
    log_result "GET" "/horarios/:id/asistencias (admin)" "$STATUS" "200" ""
    
    # GET /horarios/:horarioId/asistencias (profesor)
    RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/horarios/$HORARIO_ID/asistencias" \
        -H "Authorization: Bearer $PROFESOR_TOKEN" 2>/dev/null)
    STATUS=$(echo "$RESP" | tail -1)
    log_result "GET" "/horarios/:id/asistencias (profesor)" "$STATUS" "200" ""
fi

# GET /horarios/grupo/:grupoId
if [[ -n "$GRUPO_ID" ]]; then
    RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/horarios/grupo/$GRUPO_ID" \
        -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
    STATUS=$(echo "$RESP" | tail -1)
    log_result "GET" "/horarios/grupo/:grupoId" "$STATUS" "200" ""
fi

echo ""

# =============================================================================
# PASO 11: Profesores /profesores (dashboard)
# =============================================================================
echo -e "${BLUE}[11/15] Probando /profesores (dashboard)...${NC}"

# GET /profesores/dashboard/clases-hoy
RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/profesores/dashboard/clases-hoy" \
    -H "Authorization: Bearer $PROFESOR_TOKEN" 2>/dev/null)
STATUS=$(echo "$RESP" | tail -1)
log_result "GET" "/profesores/dashboard/clases-hoy" "$STATUS" "200" ""

# GET /profesores/dashboard/clases/:diaSemana (día 1 = lunes)
RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/profesores/dashboard/clases/1" \
    -H "Authorization: Bearer $PROFESOR_TOKEN" 2>/dev/null)
STATUS=$(echo "$RESP" | tail -1)
log_result "GET" "/profesores/dashboard/clases/:diaSemana" "$STATUS" "200" ""

# GET /profesores/dashboard/horario-semanal
RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/profesores/dashboard/horario-semanal" \
    -H "Authorization: Bearer $PROFESOR_TOKEN" 2>/dev/null)
STATUS=$(echo "$RESP" | tail -1)
log_result "GET" "/profesores/dashboard/horario-semanal" "$STATUS" "200" ""

# Verificar acceso denegado con rol incorrecto (admin no es profesor)
RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/profesores/dashboard/clases-hoy" \
    -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
STATUS=$(echo "$RESP" | tail -1)
log_result "GET" "/profesores/dashboard/clases-hoy (admin - debe fallar)" "$STATUS" "403" ""

echo ""

# =============================================================================
# PASO 12: Asistencias /asistencias
# =============================================================================
echo -e "${BLUE}[12/15] Probando /asistencias...${NC}"

# GET /asistencias/ (admin)
RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/asistencias/" \
    -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
STATUS=$(echo "$RESP" | tail -1)
log_result "GET" "/asistencias/ (admin)" "$STATUS" "200" ""

# GET /asistencias/ (profesor)
RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/asistencias/" \
    -H "Authorization: Bearer $PROFESOR_TOKEN" 2>/dev/null)
STATUS=$(echo "$RESP" | tail -1)
log_result "GET" "/asistencias/ (profesor)" "$STATUS" "200" ""

# GET /asistencias/estudiante (estudiante)
if [[ -n "$ESTUDIANTE_TOKEN" ]]; then
    RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/asistencias/estudiante" \
        -H "Authorization: Bearer $ESTUDIANTE_TOKEN" 2>/dev/null)
    STATUS=$(echo "$RESP" | tail -1)
    log_result "GET" "/asistencias/estudiante" "$STATUS" "200" ""
fi

# GET /asistencias/estadisticas/:horarioId
if [[ -n "$HORARIO_ID" ]]; then
    RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/asistencias/estadisticas/$HORARIO_ID" \
        -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
    STATUS=$(echo "$RESP" | tail -1)
    log_result "GET" "/asistencias/estadisticas/:horarioId" "$STATUS" "200" ""
fi

echo ""

# =============================================================================
# PASO 13: Notificaciones /api
# =============================================================================
echo -e "${BLUE}[13/15] Probando /api (notificaciones)...${NC}"

# POST /api/notifications/manual-trigger (requiere institutionId en body)
RESP=$(curl -sS -w '\n%{http_code}' -X POST "$BASE_URL/api/notifications/manual-trigger" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"scope":"LAST_DAY","institutionId":"'"$INSTITUCION_ID"'"}' 2>/dev/null)
STATUS=$(echo "$RESP" | tail -1)
if [[ "$STATUS" == "200" ]]; then
    log_result "POST" "/api/notifications/manual-trigger" "$STATUS" "200" ""
else
    log_result "POST" "/api/notifications/manual-trigger" "$STATUS" "200" ""
fi

echo ""

# =============================================================================
# PASO 14: Estudiantes /estudiantes (dashboard)
# =============================================================================
echo -e "${BLUE}[14/15] Probando /estudiantes (dashboard)...${NC}"

if [[ -n "$ESTUDIANTE_TOKEN" ]]; then
    # GET /estudiantes/dashboard/clases-hoy
    RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/estudiantes/dashboard/clases-hoy" \
        -H "Authorization: Bearer $ESTUDIANTE_TOKEN" 2>/dev/null)
    STATUS=$(echo "$RESP" | tail -1)
    log_result "GET" "/estudiantes/dashboard/clases-hoy" "$STATUS" "200" ""
    
    # GET /estudiantes/dashboard/horario-semanal
    RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/estudiantes/dashboard/horario-semanal" \
        -H "Authorization: Bearer $ESTUDIANTE_TOKEN" 2>/dev/null)
    STATUS=$(echo "$RESP" | tail -1)
    log_result "GET" "/estudiantes/dashboard/horario-semanal" "$STATUS" "200" ""
    
    # GET /estudiantes/dashboard/clases/:diaSemana
    RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/estudiantes/dashboard/clases/1" \
        -H "Authorization: Bearer $ESTUDIANTE_TOKEN" 2>/dev/null)
    STATUS=$(echo "$RESP" | tail -1)
    log_result "GET" "/estudiantes/dashboard/clases/:diaSemana" "$STATUS" "200" ""
    
    # GET /estudiantes/perfil
    RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/estudiantes/perfil" \
        -H "Authorization: Bearer $ESTUDIANTE_TOKEN" 2>/dev/null)
    STATUS=$(echo "$RESP" | tail -1)
    log_result "GET" "/estudiantes/perfil" "$STATUS" "200" ""
    
    # GET /estudiantes/grupos
    RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/estudiantes/grupos" \
        -H "Authorization: Bearer $ESTUDIANTE_TOKEN" 2>/dev/null)
    STATUS=$(echo "$RESP" | tail -1)
    log_result "GET" "/estudiantes/grupos" "$STATUS" "200" ""
    
    # GET /estudiantes/me
    RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/estudiantes/me" \
        -H "Authorization: Bearer $ESTUDIANTE_TOKEN" 2>/dev/null)
    STATUS=$(echo "$RESP" | tail -1)
    log_result "GET" "/estudiantes/me" "$STATUS" "200" ""
    
    # Verificar acceso denegado con rol incorrecto
    RESP=$(curl -sS -w '\n%{http_code}' "$BASE_URL/estudiantes/dashboard/clases-hoy" \
        -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
    STATUS=$(echo "$RESP" | tail -1)
    log_result "GET" "/estudiantes/dashboard/clases-hoy (admin - debe fallar)" "$STATUS" "403" ""
else
    echo -e "${YELLOW}⚠${NC} Saltando pruebas de estudiante (no se obtuvo token)"
    ((SKIP+=6))
fi

echo ""

# =============================================================================
# PASO 15: Resumen final
# =============================================================================
echo -e "${BLUE}[15/15] Generando resumen...${NC}"
echo ""
echo "=============================================="
echo "           RESUMEN DE PRUEBAS"
echo "=============================================="
echo -e "  ${GREEN}Pasaron:${NC}  $PASS"
echo -e "  ${RED}Fallaron:${NC} $FAIL"
echo -e "  ${YELLOW}Saltados:${NC} $SKIP"
echo ""
echo "Total endpoints probados: $((PASS + FAIL))"
echo ""

# Mostrar endpoints fallidos
if [[ $FAIL -gt 0 ]]; then
    echo -e "${RED}Endpoints que fallaron:${NC}"
    grep "^FAIL" "$RESULTS_FILE" | while IFS='|' read -r status method endpoint code body; do
        echo "  - $method $endpoint (HTTP $code)"
    done
    echo ""
fi

echo "Resultados guardados en: $RESULTS_FILE"
echo "=============================================="
