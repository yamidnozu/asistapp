#!/bin/bash
# run_e2e_tests.sh
# Script para ejecutar las pruebas E2E de forma fácil

set -e

echo "=========================================="
echo "🧪 Ejecutor de Pruebas E2E - AsistApp"
echo "=========================================="
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para verificar si el backend está corriendo
check_backend() {
    echo -e "${YELLOW}Verificando backend...${NC}"
    
    if curl -s http://192.168.20.22:3000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Backend está corriendo${NC}"
        return 0
    else
        echo -e "${RED}✗ Backend no responde en 192.168.20.22:3000${NC}"
        echo -e "${YELLOW}Inicia el backend con: cd backend && npm start${NC}"
        return 1
    fi
}

# Función para verificar dispositivo
check_device() {
    echo -e "${YELLOW}Verificando dispositivo...${NC}"
    
    devices=$(flutter devices 2>/dev/null | grep -c "device")
    
    if [ "$devices" -gt 0 ]; then
        echo -e "${GREEN}✓ Dispositivo encontrado${NC}"
        flutter devices
        return 0
    else
        echo -e "${RED}✗ No hay dispositivos conectados${NC}"
        echo -e "${YELLOW}Opciones:${NC}"
        echo "  1. Inicia un emulador: emulator -avd Pixel_4_API_30"
        echo "  2. Conecta un dispositivo físico"
        return 1
    fi
}

# Función para ejecutar prueba específica
run_test() {
    local test_file=$1
    echo ""
    echo -e "${YELLOW}Ejecutando: $test_file${NC}"
    echo ""
    
    flutter test "$test_file" -v
}

# Menú principal
show_menu() {
    echo ""
    echo -e "${YELLOW}Selecciona una opción:${NC}"
    echo "1) Ejecutar prueba principal (app_test.dart)"
    echo "2) Ejecutar pruebas extendidas (extended_tests.dart)"
    echo "3) Ejecutar todas las pruebas"
    echo "4) Ejecutar prueba con screenshot"
    echo "5) Ejecutar con timeout extendido"
    echo "6) Limpiar y ejecutar"
    echo "7) Verificar solo"
    echo "0) Salir"
    echo ""
    read -p "Opción: " choice
}

# Main
main() {
    # Verificar Flutter
    if ! command -v flutter &> /dev/null; then
        echo -e "${RED}Flutter no está instalado${NC}"
        exit 1
    fi

    # Verificar que estamos en el directorio correcto
    if [ ! -f "pubspec.yaml" ]; then
        echo -e "${RED}Este script debe ejecutarse desde la raíz del proyecto${NC}"
        exit 1
    fi

    # Loop del menú
    while true; do
        show_menu
        
        case $choice in
            1)
                check_backend && check_device && run_test "integration_test/app_test.dart"
                ;;
            2)
                check_backend && check_device && run_test "integration_test/extended_tests.dart"
                ;;
            3)
                check_backend && check_device && flutter test integration_test/ -v
                ;;
            4)
                check_backend && check_device
                echo -e "${YELLOW}Ejecutando con screenshots...${NC}"
                flutter test integration_test/app_test.dart --verbose
                ;;
            5)
                check_backend && check_device
                echo -e "${YELLOW}Ejecutando con timeout de 300 segundos...${NC}"
                flutter test integration_test/app_test.dart -v --timeout=300s
                ;;
            6)
                echo -e "${YELLOW}Limpiando proyecto...${NC}"
                flutter clean
                flutter pub get
                check_backend && check_device && run_test "integration_test/app_test.dart"
                ;;
            7)
                echo -e "${YELLOW}Verificando configuración...${NC}"
                check_backend
                check_device
                echo -e "${GREEN}✓ Sistema listo${NC}"
                ;;
            0)
                echo -e "${GREEN}¡Hasta luego!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Opción inválida${NC}"
                ;;
        esac
    done
}

# Ejecutar main
main
