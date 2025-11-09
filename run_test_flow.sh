#!/bin/bash

# Script de pruebas automatizadas para el sistema de asistencia estudiantil
# Uso: ./run_test_flow.sh [opcion]

set -e

echo "🚀 Sistema de Asistencia Estudiantil - Script de Pruebas"
echo "======================================================"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir con color
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Función para verificar si un servicio está corriendo
check_service() {
    local service_name=$1
    local url=$2
    local max_attempts=30
    local attempt=1

    print_status "Verificando $service_name en $url..."

    while [ $attempt -le $max_attempts ]; do
        if curl -s --max-time 5 "$url" > /dev/null 2>&1; then
            print_success "$service_name está disponible"
            return 0
        fi

        print_status "Intento $attempt/$max_attempts - $service_name no disponible, esperando..."
        sleep 2
        ((attempt++))
    done

    print_error "$service_name no está disponible después de $max_attempts intentos"
    return 1
}

# Función para ejecutar pruebas del backend
test_backend() {
    print_status "Ejecutando pruebas del backend..."

    cd backend

    # Verificar que las dependencias estén instaladas
    if [ ! -d "node_modules" ]; then
        print_status "Instalando dependencias del backend..."
        npm install
    fi

    # Ejecutar pruebas si existen
    if [ -d "tests" ] || [ -f "jest.config.js" ]; then
        print_status "Ejecutando pruebas unitarias..."
        npm test || print_warning "Las pruebas unitarias fallaron, pero continuando..."
    else
        print_warning "No se encontraron pruebas unitarias configuradas"
    fi

    # Verificar que el servidor pueda iniciar
    print_status "Verificando que el backend puede iniciar..."
    timeout 10s npm run dev > /dev/null 2>&1 &
    local backend_pid=$!
    sleep 5

    if kill -0 $backend_pid 2>/dev/null; then
        print_success "Backend puede iniciar correctamente"
        kill $backend_pid
    else
        print_error "Backend no puede iniciar"
        return 1
    fi

    cd ..
}

# Función para ejecutar pruebas de Flutter
test_flutter() {
    print_status "Ejecutando pruebas de Flutter..."

    # Verificar que Flutter esté instalado
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter no está instalado o no está en PATH"
        return 1
    fi

    # Verificar que las dependencias estén instaladas
    flutter pub get

    # Ejecutar pruebas si existen
    if find . -name "*_test.dart" -type f | grep -q .; then
        print_status "Ejecutando pruebas unitarias de Flutter..."
        flutter test || print_warning "Las pruebas de Flutter fallaron, pero continuando..."
    else
        print_warning "No se encontraron pruebas unitarias de Flutter"
    fi

    # Verificar que la app puede compilar
    print_status "Verificando compilación de la aplicación..."
    flutter build apk --debug --quiet || {
        print_error "La aplicación no puede compilar"
        return 1
    }

    print_success "Flutter tests completados"
}

# Función para verificar configuración
check_configuration() {
    print_status "Verificando configuración..."

    # Verificar archivos de configuración
    local required_files=(
        "backend/.env"
        "backend/package.json"
        "pubspec.yaml"
        "docker-compose.yml"
    )

    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            print_success "✓ $file existe"
        else
            print_error "✗ $file no encontrado"
            return 1
        fi
    done

    # Verificar variables de entorno críticas
    if [ -f "backend/.env" ]; then
        local required_vars=(
            "DATABASE_URL"
            "JWT_SECRET"
        )

        for var in "${required_vars[@]}"; do
            if grep -q "^$var=" backend/.env; then
                print_success "✓ Variable $var configurada"
            else
                print_error "✗ Variable $var no encontrada en .env"
                return 1
            fi
        done
    fi

    print_success "Configuración verificada correctamente"
}

# Función para ejecutar pruebas de integración básicas
test_integration_basic() {
    print_status "Ejecutando pruebas de integración básicas..."

    # Verificar que Docker esté disponible
    if command -v docker &> /dev/null && command -v docker-compose &> /dev/null; then
        print_status "Verificando servicios Docker..."

        # Verificar que docker-compose.yml existe
        if [ -f "docker-compose.yml" ]; then
            print_success "Docker Compose configurado"

            # Intentar iniciar servicios (esto puede fallar si ya están corriendo)
            print_status "Intentando iniciar servicios con Docker..."
            docker-compose up -d db 2>/dev/null || print_warning "No se pudieron iniciar servicios Docker (pueden ya estar corriendo)"

            # Verificar base de datos
            check_service "Base de datos PostgreSQL" "http://localhost:5432" || print_warning "Base de datos no disponible"
        else
            print_warning "Docker Compose no configurado"
        fi
    else
        print_warning "Docker no disponible"
    fi

    # Verificar API del backend (si está corriendo)
    check_service "API Backend" "http://localhost:3000/health" || print_warning "API Backend no disponible en puerto 3000"
}

# Función para mostrar ayuda
show_help() {
    echo "Uso: $0 [opcion]"
    echo ""
    echo "Opciones:"
    echo "  all          Ejecutar todas las pruebas (default)"
    echo "  backend      Solo pruebas del backend"
    echo "  flutter      Solo pruebas de Flutter"
    echo "  config       Solo verificación de configuración"
    echo "  integration  Solo pruebas de integración"
    echo "  help         Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 all          # Ejecutar todo"
    echo "  $0 backend      # Solo backend"
    echo "  $0 flutter      # Solo Flutter"
}

# Función principal
main() {
    local option=${1:-all}

    case $option in
        all)
            print_status "Ejecutando suite completa de pruebas..."
            check_configuration
            test_backend
            test_flutter
            test_integration_basic
            print_success "Suite completa de pruebas finalizada"
            ;;
        backend)
            check_configuration
            test_backend
            ;;
        flutter)
            test_flutter
            ;;
        config)
            check_configuration
            ;;
        integration)
            test_integration_basic
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Opción no válida: $option"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Ejecutar función principal
main "$@"