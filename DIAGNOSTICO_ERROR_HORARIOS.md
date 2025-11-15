# 🔧 PASOS PARA DIAGNOSTICAR EL PROBLEMA

## 1. Limpia la app

```bash
cd /c/Proyectos/DemoLife
flutter clean
flutter pub get
```

## 2. Ejecuta con logs visible

```bash
flutter run -v
```

## 3. Abre Flutter Logs en otra terminal

```bash
flutter logs
```

## 4. Navega a Gestión de Horarios

En la app:
- Admin Dashboard → Gestión de Horarios
- Selecciona Período: "Año Lectivo 2025"
- Selecciona Grupo: "Grupo 10-A"

## 5. Busca los logs

En la terminal de `flutter logs`, busca:

```
✅ Horario 0 parseado exitosamente
✅ Horario 1 parseado exitosamente
...
Total horarios cargados: 8
```

## Si Ves Errores

Si vez:
```
❌ Error parseando horario 0: ...
Data: {...}
```

**Copía los datos del error y reporta qué campo está diferente.**

## Verificación Rápida del Backend

```bash
# 1. Login
TOKEN=$(curl -s -X POST http://localhost:3002/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@sanjose.edu","password":"SanJose123!"}' \
  | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)

# 2. Ver primer horario
curl -s -H "Authorization: Bearer $TOKEN" \
  "http://localhost:3002/horarios?grupoId=78031d74-49f3-4081-ae74-e89d8bf3dde5" \
  | jq '.data[0]'
```

## Qué Buscar

El JSON del horario debe tener estos campos:
- `id` (string)
- `diaSemana` (number: 1-7)
- `horaInicio` (string: "HH:MM")
- `horaFin` (string: "HH:MM")
- `grupoId` (string)
- `materiaId` (string)
- `grupo` (object) - IMPORTANTE
- `materia` (object) - IMPORTANTE
- `periodoAcademico` (object) - IMPORTANTE

---

**Estado:** En diagnóstico
**Fecha:** 14 de Noviembre 2025
