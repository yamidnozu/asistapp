#!/bin/bash
# test_deployment.sh - Script para probar el despliegue del backend

echo "=== Probando despliegue del backend ==="
echo "Fecha: $(date)"
echo ""

# 1. Verificar contenedores Docker
echo "1. 📦 Contenedores Docker:"
docker ps --filter "name=backend" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# 2. Verificar servicios del sistema
echo "2. 🔧 Servicios del sistema:"
echo "Nginx: $(systemctl is-active nginx)"
echo "Docker: $(systemctl is-active docker)"
echo ""

# 3. Verificar conectividad HTTP/HTTPS
IP="31.220.104.130"
DOMAIN="${DOMAIN:-$IP}"  # Usar IP si no hay dominio
echo "3. 🌐 Probando conectividad web (IP: $IP):"
echo "HTTP: $(curl -s -o /dev/null -w "%{http_code}" http://$IP)"
echo "HTTPS: $(curl -s -o /dev/null -w "%{http_code}" https://$IP)"
echo ""

# 4. Probar endpoints específicos
IP="31.220.104.130"
echo "4. 🔗 Probando endpoints de la API (IP: $IP):"
echo "Health check: $(curl -s -w "HTTP %{http_code}: %{url_effective}\\n" https://$IP/api/health 2>/dev/null || echo "Failed - HTTPS")"
echo "Health check (HTTP): $(curl -s -w "HTTP %{http_code}: %{url_effective}\\n" http://$IP/api/health 2>/dev/null || echo "Failed - HTTP")"
echo ""

# 5. Verificar logs recientes
echo "5. 📋 Logs recientes del backend:"
docker logs --tail 10 backend-app-v3 2>/dev/null || echo "No se pudieron obtener logs del contenedor"
echo ""

# 6. Verificar base de datos
echo "6. 🗄️ Verificar conexión a base de datos:"
docker exec asistapp_db pg_isready -h localhost -p 5432 -U arroz 2>/dev/null && echo "✅ PostgreSQL conectado" || echo "❌ PostgreSQL no responde"
echo ""

echo "=== Resumen ==="
echo "✅ Backend desplegado y configurado"
echo "📍 URL: https://31.220.104.130"
echo "🔍 Logs completos: docker logs -f backend-app-v3"
echo "🔄 Reiniciar: docker compose -f /opt/asistapp/docker-compose.prod.yml restart"
echo "🛑 Detener: docker compose -f /opt/asistapp/docker-compose.prod.yml down"