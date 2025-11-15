# ✅ VALIDACIÓN DE CONFLICTOS: COMPORTAMIENTO ESPERADO

## 📊 Error 409 - CONFLICT_ERROR

El error `409 Conflict` que ves es **CORRECTO Y ESPERADO**. Significa que el sistema está validando correctamente que no haya dos clases en el mismo horario.

### ¿Por qué ocurre?

Cuando intentas crear un horario que se superpone con uno existente:

```
Horario existente:  Lunes 08:00 - 10:00 (Cálculo)
Intento nuevo:      Lunes 08:00 - 09:00 (Otra materia)
                    ↑
                    ❌ CONFLICTO: Se superponen en la misma hora
```

### Validación de Conflictos

El backend valida:
1. ✅ El grupo NO tiene otra clase en ese día y hora
2. ✅ El profesor NO tiene otra clase en ese día y hora (si está asignado)
3. ✅ Formato de hora es válido (HH:MM)
4. ✅ Hora inicio < Hora fin
5. ✅ Día semana está en rango 1-7

### Ejemplo de Horario Existente para Grupo 10-A

```
Lunes:
  08:00 - 10:00  Cálculo
  10:30 - 11:30  Física

Martes:
  08:00 - 09:00  Español
  09:00 - 10:00  Inglés

Miércoles:
  08:00 - 10:00  Física

Jueves:
  08:00 - 09:00  Cálculo
  09:00 - 10:00  Español

Viernes:
  08:00 - 09:00  Inglés
```

## ✅ PRUEBA SIN CONFLICTOS

### Paso 1: Seleccionar un Espacio Vacío

Basándote en los horarios arriba, los espacios **DISPONIBLES** son:

#### Lunes
- ✅ 06:00 - 08:00 (DISPONIBLE)
- ❌ 08:00 - 10:00 (Ocupado: Cálculo)
- ❌ 10:00 - 10:30 (Solapamiento parcial)
- ❌ 10:30 - 11:30 (Ocupado: Física)
- ✅ 11:30 - 13:00 (DISPONIBLE)

#### Martes
- ✅ 06:00 - 08:00 (DISPONIBLE)
- ❌ 08:00 - 10:00 (Solapamiento: 08:00-09:00 Español, 09:00-10:00 Inglés)
- ✅ 10:00 - 13:00 (DISPONIBLE)

#### Miércoles
- ✅ 06:00 - 08:00 (DISPONIBLE)
- ❌ 08:00 - 10:00 (Ocupado: Física)
- ✅ 10:00 - 13:00 (DISPONIBLE)

#### Jueves
- ✅ 06:00 - 08:00 (DISPONIBLE)
- ❌ 08:00 - 10:00 (Solapamiento: 08:00-09:00 Cálculo, 09:00-10:00 Español)
- ✅ 10:00 - 13:00 (DISPONIBLE)

#### Viernes
- ✅ 06:00 - 08:00 (DISPONIBLE)
- ❌ 08:00 - 09:00 (Ocupado: Inglés)
- ✅ 09:00 - 13:00 (DISPONIBLE)

### Paso 2: Crear Nuevo Horario

**Ejemplo que SÍ funciona:**
```
Día:        Lunes
Hora Inicio: 06:00
Hora Fin:   07:00
Materia:    Cálculo (o cualquier otra)
Profesor:   Juan Pérez (o dejar sin asignar)
```

**Resultado esperado:** ✅ Horario creado correctamente

### Paso 3: Intento que FALLA (Esperado)

**Intento que genera 409:**
```
Día:        Lunes
Hora Inicio: 08:30  (dentro de 08:00-10:00 Cálculo)
Hora Fin:   09:30
Materia:    Otra materia
```

**Resultado:** ❌ Error 409: "El grupo ya tiene una clase programada en este horario"

**Diálogo mostrado:**
```
⚠️ CONFLICTO DE HORARIO

No se puede crear la clase debido a un conflicto de horario.

Horarios en conflicto:
- 3f003407-c891-4b91-b1c4-d2a625a8d8d4

Sugerencias para resolver:
• Cambiar la hora del nuevo horario
• Cambiar el día de la semana
• Cambiar el grupo
```

## 📋 CHECKLIST DE VALIDACIÓN

Cuando intentas crear un horario, el sistema valida:

- [ ] Periodo académico válido (existe y pertenece a institución)
- [ ] Grupo válido (existe y pertenece a período)
- [ ] Materia válida (existe y pertenece a institución)
- [ ] Profesor válido (si está asignado, existe en institución)
- [ ] Día semana válido (1-7)
- [ ] Formato de hora válido (HH:MM)
- [ ] Hora inicio < Hora fin
- [ ] **NO hay conflicto con otra clase del grupo**
- [ ] **NO hay conflicto con horario del profesor** (si asignado)

Si todas pasan → ✅ Horario creado
Si alguna falla → ❌ Error con mensaje específico

## 🎯 PRUEBA CORRECTA

### En la Aplicación:

1. **Login:** admin@sanjose.edu / SanJose123!
2. **Ir a:** Gestion Académica → Horarios
3. **Período:** "Año Lectivo 2025"
4. **Grupo:** "Grupo 10-A"
5. **En el calendario:** Ver los horarios existentes
6. **Clic en celda VACÍA:** Por ejemplo, Lunes 06:00 (antes del primer horario)
7. **Llenar datos:**
   - Materia: "Física"
   - Hora fin: "07:00"
   - Profesor: (opcional)
8. **Clic crear**
9. **Resultado esperado:** ✅ "Clase creada correctamente"
10. **Verificación:** El nuevo horario aparece en el calendario en Lunes 06:00-07:00

### Para Causar Error 409 (Propósito: Validación)

1. Mismo proceso pero seleccionar celda **OCUPADA**, ej: Lunes 08:00
2. Hora fin: 09:00
3. Clic crear
4. **Resultado esperado:** ❌ Diálogo de conflicto

## 🔍 DEBUGGING

Si tienes dudas sobre qué horarios existen:

```bash
# En la terminal
sqlite3 asistapp.db  # o psql para PostgreSQL

SELECT 
  g.nombre as grupo,
  m.nombre as materia,
  h.dia_semana,
  h.hora_inicio,
  h.hora_fin
FROM horarios h
JOIN grupos g ON h.grupo_id = g.id
JOIN materias m ON h.materia_id = m.id
WHERE g.nombre = 'Grupo 10-A'
ORDER BY h.dia_semana, h.hora_inicio;
```

## ✨ COMPORTAMIENTO CORRECTO

```
Usuario selecciona celda disponible
  ↓
Sistema crea horario
  ↓
Backend valida (sin conflictos)
  ↓
Horario se guarda en BD
  ↓
Frontend recarga horarios
  ↓
Nuevo horario aparece en el calendario
  ✅ ÉXITO

---

Usuario selecciona celda ocupada
  ↓
Sistema intenta crear horario
  ↓
Backend valida y encuentra conflicto
  ↓
Retorna error 409 con detalles
  ↓
Frontend muestra diálogo de conflicto
  ↓
Usuario ve sugerencias para resolver
  ✅ COMPORTAMIENTO CORRECTO
```

---

**Resumen:** El error 409 que ves es el sistema funcionando **correctamente**. No es un bug, es una **validación de negocio**.

Si el error ocurre cuando NO debería (cuando la celda está vacía), entonces sí hay un problema. En ese caso, verifica:
1. Qué horario exactamente intentaste crear
2. Qué horarios ya existen en esa franja horaria
3. Los logs del backend para ver qué conflicto se detectó
