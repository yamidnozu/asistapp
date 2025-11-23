#!/bin/bash

# Script para ejecutar tests críticos de Super Admin
# Uso: ./run_critical_tests.sh

echo "🔴 EJECUTANDO TESTS CRÍTICOS - Super Admin"
echo "=========================================="
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar que Flutter esté instalado
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter no está instalado${NC}"
    exit 1
fi

echo -e "${YELLOW}📦 Verificando dependencias...${NC}"
flutter pub get

echo ""
echo -e "${YELLOW}🧪 Ejecutando TODOS los tests críticos...${NC}"
echo ""

# Ejecutar tests críticos
flutter test integration_test/comprehensive_flows_test.dart --name "CRÍTICO"

TEST_RESULT=$?

echo ""
echo "=========================================="

if [ $TEST_RESULT -eq 0 ]; then
    echo -e "${GREEN}✅ TODOS LOS TESTS CRÍTICOS PASARON${NC}"
    echo ""
    echo "Tests ejecutados:"
    echo "  ✅ Login Super Admin (sin selección institución)"
    echo "  ✅ Comparación Super Admin vs Admin"
    echo "  ✅ Acceso Global a Instituciones"
    echo "  ✅ Restricción Admin Institución"
    echo "  ✅ Arquitectura: Global vs Institucional"
    echo "  ✅ Base de Datos: Vínculos"
else
    echo -e "${RED}❌ ALGUNOS TESTS CRÍTICOS FALLARON${NC}"
    echo ""
    echo "Por favor revisa los errores arriba."
    echo "Los tests críticos detectan:"
    echo "  - Problemas en flujo de autenticación"
    echo "  - Selección incorrecta de institución"
    echo "  - Permisos mal configurados"
    echo "  - Concepto arquitectónico incorrecto"
fi

echo "=========================================="
exit $TEST_RESULT
