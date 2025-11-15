# 🐛 DEBUGGING: Guía de Solución de Problemas

## 🔧 Herramientas de Diagnóstico Disponibles

### 1. Ver Logs del Backend

```bash
# Últimas 100 líneas
docker compose logs app --tail 100

# Con seguimiento en vivo
docker compose logs app -f

# Solo errores
docker compose logs app | grep -i error
```

**Qué buscar:**
- `ERROR` - Errores del servidor
- `cannot find horario` - Problema con consulta a BD
- `ECONNREFUSED` - Base de datos no responde
- `401` - Problema con autenticación

### 2. Ver Logs de la Base de Datos

```bash
# Última línea de logs
docker compose logs db

# Errores de conexión
docker compose logs db | grep -i error
```

### 3. Verificar Estado de Contenedores

```bash
# Ver si están corriendo
docker ps

# Resultado esperado:
# backend-app-v3   3002  ✅ Up
# asistapp_db      5433  ✅ Up
```

### 4. Verificar Conectividad

```bash
# ¿Backend responde?
curl -I http://localhost:3002/health

# ¿Base de datos responde?
docker exec asistapp_db pg_isready
```

## 🎯 Escenarios Comunes y Soluciones

### ❌ Problema: "Cargando horarios..." nunca termina

**Diagnóstico:**

```bash
# 1. Verifica logs del backend
docker compose logs app --tail 50 | grep -i error

# 2. Verifica que la BD está lista
docker exec asistapp_db psql -U arroz -d asistapp -c "SELECT COUNT(*) FROM horarios;"

# 3. Prueba el endpoint directamente
TOKEN="<token>"
curl -v http://localhost:3002/horarios?grupoId=78031d74-49f3-4081-ae74-e89d8bf3dde5 \
  -H "Authorization: Bearer $TOKEN"
```

**Soluciones (en orden):**

```bash
# Solución 1: Reinicia el backend
docker compose restart app

# Solución 2: Reinicia todo
docker compose restart

# Solución 3: Limpia y reinicia (nuclear option)
docker compose down -v
docker compose up -d db
sleep 10
docker compose up -d app
```

---

### ❌ Problema: "Error: Connection refused"

**Diagnóstico:**

```bash
# ¿Backend corriendo?
docker ps | grep backend-app

# ¿Puerto 3002 activo?
netstat -ano | findstr :3002  # Windows
ss -tuln | grep 3002          # Linux
```

**Soluciones:**

```bash
# Solución 1: Inicia backend
docker compose up -d app

# Solución 2: Limpia puerto (Windows)
taskkill /PID <PID> /F

# Solución 3: Cambia puerto en docker-compose.yml
# Cambiar: ports: ["3002:3000"] por ["3003:3000"]
```

---

### ❌ Problema: "No hay horarios en la BD"

**Diagnóstico:**

```bash
# Ver cuántos horarios hay
docker exec asistapp_db psql -U arroz -d asistapp -c \
  "SELECT COUNT(*) FROM horarios;"

# Ver horarios por grupo
docker exec asistapp_db psql -U arroz -d asistapp -c \
  "SELECT g.nombre, COUNT(h.id) 
   FROM horarios h 
   JOIN grupos g ON h.grupo_id = g.id 
   GROUP BY g.nombre;"
```

**Soluciones:**

```bash
# Si hay 0 horarios, ejecuta el seed
cd /c/Proyectos/DemoLife/backend
npm run prisma:seed

# Si falla el seed, reinicia BD
docker compose down -v
docker compose up -d db
sleep 10
npm run prisma:seed
```

---

### ❌ Problema: "Error de autenticación (401)"

**Diagnóstico:**

```bash
# Prueba login
curl -X POST http://localhost:3002/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@sanjose.edu","password":"SanJose123!"}'

# Si falla, la credencial no es válida
```

**Soluciones:**

```bash
# Verifica usuarios en BD
docker exec asistapp_db psql -U arroz -d asistapp -c \
  "SELECT email, rol FROM usuarios LIMIT 5;"

# Si falta admin, recrea usuarios
cd /c/Proyectos/DemoLife/backend
npm run prisma:seed
```

---

### ❌ Problema: "Calendario está vacío pero no hay error"

**Diagnóstico:**

```bash
# 1. Verifica que se está llamando la API
flutter logs | grep getHorariosPorGrupo

# 2. Verifica que la API retorna datos
TOKEN="<token>"
curl -s http://localhost:3002/horarios?grupoId=78031d74-49f3-4081-ae74-e89d8bf3dde5 \
  -H "Authorization: Bearer $TOKEN" | jq '.data | length'

# 3. Verifica el estado del provider
# En la app, abre la consola y busca: "HorarioProvider:"
```

**Soluciones:**

```bash
# Solución 1: Verifica que el grupoId es correcto
# (El que obtienes del dropdown de grupos)

# Solución 2: Reinicia la app
flutter run  # O flutter clean && flutter run

# Solución 3: Verifica el groupId en la BD
docker exec asistapp_db psql -U arroz -d asistapp -c \
  "SELECT id, nombre FROM grupos;"
```

---

## 📊 Flujo de Debug Completo

Cuando reportes un problema, ejecuta esto en orden:

```bash
# 1. Verificar backend
echo "=== BACKEND ===" && \
curl -I http://localhost:3002/health && \
echo -e "\n=== OK ===" || echo "ERROR: Backend no responde"

# 2. Verificar BD
echo -e "\n=== BASE DE DATOS ===" && \
docker exec asistapp_db psql -U arroz -d asistapp -c "SELECT COUNT(*) as horarios FROM horarios;" && \
echo "OK" || echo "ERROR: BD no responde"

# 3. Verificar login
echo -e "\n=== LOGIN ===" && \
curl -s -X POST http://localhost:3002/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@sanjose.edu","password":"SanJose123!"}' | \
grep -q "accessToken" && echo "OK" || echo "ERROR: Login fallido"

# 4. Verificar horarios
echo -e "\n=== HORARIOS ===" && \
TOKEN=$(curl -s -X POST http://localhost:3002/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@sanjose.edu","password":"SanJose123!"}' | \
  grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4) && \
curl -s http://localhost:3002/horarios?grupoId=78031d74-49f3-4081-ae74-e89d8bf3dde5 \
  -H "Authorization: Bearer $TOKEN" | \
  grep -o '"id":"[^"]*"' | wc -l && echo "horarios encontrados"
```

## 🚨 Estado de Salud del Sistema

Copia y ejecuta este script para obtener un reporte completo:

```bash
#!/bin/bash

echo "╔════════════════════════════════════════════╗"
echo "║        REPORTE DE SALUD DEL SISTEMA        ║"
echo "╚════════════════════════════════════════════╝"

echo -e "\n🔹 CONTENEDORES"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "backend-app|asistapp_db"

echo -e "\n🔹 BACKEND"
if curl -s -I http://localhost:3002/health | grep -q "200"; then
  echo "✅ Backend respondiendo"
else
  echo "❌ Backend NO responde"
fi

echo -e "\n🔹 BASE DE DATOS"
HORARIOS=$(docker exec asistapp_db psql -U arroz -d asistapp -c "SELECT COUNT(*) FROM horarios;" 2>/dev/null | tail -1)
echo "📊 Horarios en BD: $HORARIOS"

echo -e "\n🔹 AUTENTICACIÓN"
AUTH=$(curl -s -X POST http://localhost:3002/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@sanjose.edu","password":"SanJose123!"}' | grep -o '"accessToken":"[^"]*"')
if [ -n "$AUTH" ]; then
  echo "✅ Login funciona"
else
  echo "❌ Login fallido"
fi

echo -e "\n✅ RESUMEN: El sistema está $([ "$HORARIOS" -gt 0 ] && echo 'LISTO' || echo 'INCOMPLETO')"
```

## 📋 Checklist de Troubleshooting

Antes de reportar un problema, verifica:

- [ ] Backend está corriendo: `docker ps | grep backend`
- [ ] BD está corriendo: `docker ps | grep asistapp_db`
- [ ] Hay datos en BD: `docker exec asistapp_db psql -U arroz -d asistapp -c "SELECT COUNT(*) FROM horarios;"`
- [ ] Login funciona: `curl -X POST http://localhost:3002/auth/login ...`
- [ ] Endpoint `/horarios` retorna datos: `curl http://localhost:3002/horarios?grupoId=... -H "Authorization: Bearer $TOKEN"`
- [ ] Flutter análisis pasa: `flutter analyze`
- [ ] No hay errores en logs de Flutter: `flutter logs`

## 💾 Comandos Rápidos

```bash
# Reiniciar todo
docker compose down -v && docker compose up -d

# Ver logs en vivo
docker compose logs -f

# Resetear datos (PERDER TODO)
docker compose down -v
docker compose up -d db
sleep 10
docker compose run --rm app npx prisma db push --accept-data-loss
docker compose run --rm app npm run prisma:seed
docker compose up -d app

# Ver todos los horarios
docker exec asistapp_db psql -U arroz -d asistapp -c \
  "SELECT g.nombre, m.nombre, h.hora_inicio, h.hora_fin FROM horarios h 
   JOIN grupos g ON h.grupo_id = g.id 
   JOIN materias m ON h.materia_id = m.id 
   ORDER BY g.nombre, h.dia_semana, h.hora_inicio;"
```

---

**Recuerda:** Si algo no funciona:
1. Mira los logs: `docker compose logs app`
2. Reinicia: `docker compose restart app`
3. Si falla, limpia y recrea: `docker compose down -v && docker compose up -d`

