#!/bin/bash
# ============================================================================
# EJECUTOR SUITE E2E COMPLETA - 100%
# ============================================================================
#
# Ejecuta todos los tests E2E de forma secuencial
# Cada test tiene aislamiento completo
#
# ============================================================================

echo ""
echo "══════════════════════════════════════════════════════════════════════════"
echo "🚀 SUITE E2E COMPLETA - OPERACIONES CRUD REALES"
echo "══════════════════════════════════════════════════════════════════════════"
echo ""

PASSED=0
FAILED=0
TOTAL=0

cd "c:/Proyectos/DemoLife" || exit 1

# Lista de tests
TESTS=(
    "e2e_crud_instituciones_test.dart"
    "e2e_crud_usuarios_test.dart"
    "e2e_crud_materias_test.dart"
    "e2e_crud_grupos_test.dart"
    "e2e_seguridad_roles_test.dart"
    "e2e_flujo_asistencia_test.dart"
    "e2e_validaciones_test.dart"
)

for TEST in "${TESTS[@]}"; do
    ((TOTAL++))
    echo ""
    echo "──────────────────────────────────────────────────────────────────────────"
    echo "📋 Test $TOTAL: $TEST"
    echo "──────────────────────────────────────────────────────────────────────────"
    
    if flutter test "integration_test/$TEST" -d windows --no-pub 2>&1 | tail -5; then
        if flutter test "integration_test/$TEST" -d windows --no-pub 2>&1 | grep -q "All tests passed"; then
            ((PASSED++))
            echo "✅ PASÓ: $TEST"
        else
            ((FAILED++))
            echo "❌ FALLÓ: $TEST"
        fi
    else
        ((FAILED++))
        echo "❌ FALLÓ: $TEST"
    fi
done

echo ""
echo "══════════════════════════════════════════════════════════════════════════"
echo "📊 RESUMEN FINAL"
echo "══════════════════════════════════════════════════════════════════════════"
echo ""
echo "✅ Pasaron: $PASSED/$TOTAL"
echo "❌ Fallaron: $FAILED/$TOTAL"
echo ""

if [ $TOTAL -gt 0 ]; then
    PERCENTAGE=$((PASSED * 100 / TOTAL))
    echo "📈 Tasa de éxito: ${PERCENTAGE}%"
fi
echo ""
echo "══════════════════════════════════════════════════════════════════════════"

if [ $FAILED -gt 0 ]; then
    exit 1
else
    echo "🎉 TODOS LOS TESTS PASARON"
    exit 0
fi
