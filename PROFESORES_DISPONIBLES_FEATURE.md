# ✨ NUEVA FEATURE - Profesores Disponibles por Horario

**Fecha:** 15 de Noviembre 2025  
**Implementación:** Filtro de disponibilidad de profesores  
**Status:** ✅ COMPLETADO

---

## 📋 La Solicitud

"Cuando vamos a crear una clase para un horario, la lista de profesores debería mostrar solamente los profesores que a esa hora ese día tienen disponible, es decir evitar que se le cruce"

---

## ✅ Solución Implementada

Se agregó lógica para **filtrar automáticamente** los profesores disponibles basándose en:
- **Día de la semana** específico
- **Hora de inicio** de la clase
- **Hora de fin** de la clase

---

## 🔧 Cambios Realizados

### 1. Agregar Método al HorarioProvider

**Archivo:** `lib/providers/horario_provider.dart`

**Método nuevo:** `getProfesoresDisponibles()`

```dart
/// Obtiene profesores disponibles para un horario específico
/// Sin conflictos en ese día y hora
List<User> getProfesoresDisponibles(
  List<User> allProfesors,
  int diaSemana,
  String horaInicio,
  String horaFin,
) {
  final profesoresConConflicto = <String>{};

  // Convertir horas a minutos
  final inicioMinutos = _timeToMinutes(horaInicio);
  final finMinutos = _timeToMinutes(horaFin);

  // Encontrar profesores con conflictos
  for (final horario in _horarios) {
    if (horario.diaSemana == diaSemana && horario.profesor != null) {
      final hInicio = _timeToMinutes(horario.horaInicio);
      final hFin = _timeToMinutes(horario.horaFin);

      // Hay conflicto si se solapan los horarios
      if (inicioMinutos < hFin && finMinutos > hInicio) {
        profesoresConConflicto.add(horario.profesor!.id);
      }
    }
  }

  // Retornar solo los profesores sin conflictos
  return allProfesors.where((profesor) => !profesoresConConflicto.contains(profesor.id)).toList();
}

/// Convierte una hora en formato HH:MM a minutos
int _timeToMinutes(String time) {
  final parts = time.split(':');
  final hours = int.parse(parts[0]);
  final minutes = int.parse(parts[1]);
  return hours * 60 + minutes;
}
```

**Lógica:**
1. ✅ Itera sobre todos los horarios cargados
2. ✅ Busca horarios del **mismo día**
3. ✅ Busca si hay **superposición de horas**
4. ✅ Marca profesores en conflicto
5. ✅ Retorna solo profesores sin conflictos

---

### 2. Actualizar CreateClassDialog

**Archivo:** `lib/screens/academic/horarios_screen.dart`

**Cambio:** Usar `Consumer2<UserProvider, HorarioProvider>`

**ANTES:**
```dart
Consumer<UserProvider>(
  builder: (context, userProvider, child) {
    return DropdownButtonFormField<User?>(
      // Mostraba TODOS los profesores sin importar disponibilidad
      items: userProvider.professors.map(...)
    );
  },
);
```

**DESPUÉS:**
```dart
Consumer2<UserProvider, HorarioProvider>(
  builder: (context, userProvider, horarioProvider, child) {
    // ✅ NUEVO: Obtener profesores disponibles
    final profesoresDisponibles = horarioProvider.getProfesoresDisponibles(
      userProvider.professors,
      widget.diaSemana,
      widget.horaInicio,
      _selectedHoraFin ?? _getHoraFin(widget.horaInicio),
    );

    // ✅ NUEVO: Mostrar cuántos están disponibles
    return DropdownButtonFormField<User?>(
      decoration: InputDecoration(
        labelText: 'Profesor (opcional)',
        hintText: 'Selecciona un profesor',
        helperText: profesoresDisponibles.length < userProvider.professors.length
            ? '${profesoresDisponibles.length} disponibles'
            : null,
      ),
      // ✅ NUEVO: Usar solo profesores disponibles
      items: [
        const DropdownMenuItem<User?>(
          value: null,
          child: Text('Sin profesor'),
        ),
        ...profesoresDisponibles.map((profesor) {
          return DropdownMenuItem<User?>(
            value: profesor,
            child: Text('${profesor.nombres} ${profesor.apellidos}'),
          );
        }),
      ],
      onChanged: (profesor) {
        setState(() => _selectedProfesor = profesor);
      },
    );
  },
);
```

---

## 🎯 Cómo Funciona

### Ejemplo Práctico

**Supongamos que:**
- Hay 5 profesores: Juan, María, Pedro, Ana, Luis
- Queremos crear una clase el **Lunes de 10:00 a 11:00**
- **Estado actual:**
  - Juan: Lunes 09:00-10:00 (disponible)
  - María: Lunes 10:00-11:00 (❌ CONFLICTO)
  - Pedro: Lunes 10:30-11:30 (❌ CONFLICTO)
  - Ana: Lunes 14:00-15:00 (disponible)
  - Luis: Martes 10:00-11:00 (disponible, otro día)

**El dropdown mostrará:**
```
✅ Sin profesor
✅ Juan
✅ Ana
✅ Luis

❌ María (no aparece - conflicto)
❌ Pedro (no aparece - conflicto)
```

**Helper text:** "3 disponibles"

---

## 🧮 Algoritmo de Conflicto

La lógica usa el mismo algoritmo del backend:

```
Hay conflicto si:
  (inicioNuevo < finExistente) AND (finNuevo > inicioExistente)
```

**Ejemplos:**
```
Existente: 10:00 - 11:00
Nueva:     09:00 - 10:00  → ✅ No conflicto (termina justo cuando empieza)
Nueva:     10:00 - 11:00  → ❌ Conflicto (exacto)
Nueva:     10:30 - 11:30  → ❌ Conflicto (se solapa)
Nueva:     11:00 - 12:00  → ✅ No conflicto (empieza justo cuando termina)
```

---

## 💡 Características Implementadas

### ✅ Filtrado Automático
- El dropdown se actualiza automáticamente cuando cambias:
  - Hora inicio
  - Hora fin
  - Día de la semana (aunque está fijo en el diálogo)

### ✅ Información Visual
- Helper text muestra cuántos profesores están disponibles
- Si hay disponibilidad parcial, muestra: "3 disponibles"
- Si todos están disponibles, no muestra nada

### ✅ Basado en Datos Reales
- Usa los horarios ya cargados en el `HorarioProvider`
- Solo considera conflictos reales
- Sincronizado con la validación del backend

### ✅ Nullable Profesor
- Sigue siendo opcional asignar profesor
- "Sin profesor" siempre está disponible

---

## 🔄 Flujo de Trabajo

1. **Usuario abre CreateClassDialog**
   - Sistema obtiene horarios cargados
   - Calcula profesores con conflictos

2. **Usuario selecciona hora fin**
   - El widget se reconstruye (setState)
   - Se recalculan profesores disponibles
   - El dropdown se actualiza automáticamente

3. **Usuario selecciona profesor**
   - Se valida al momento de crear (backend)
   - El backend también valida conflictos
   - Es una validación doble (cliente + servidor)

---

## ✅ Validación

```bash
✅ flutter analyze
   Analyzing DemoLife...
   No issues found! (ran in 4.5s)
```

**Status:** Sin errores ni warnings

---

## 🧪 Cómo Probar

### Test Manual

1. **Crear algunos horarios:**
   - Lunes 10:00-11:00 con Profesor A
   - Lunes 10:30-11:30 con Profesor B
   - Martes 14:00-15:00 con Profesor C

2. **Crear nueva clase:**
   - Lunes a las 10:00
   - Abrir CreateClassDialog
   - Ver dropdown profesor
   - **Resultado esperado:** Profesor A y B NO aparecen, C sí

3. **Cambiar hora fin:**
   - Cambiar de 11:00 a 10:15
   - **Resultado esperado:** Se filtra diferente (más conflictos)

4. **Cambiar hora fin de nuevo:**
   - Cambiar a 09:00
   - **Resultado esperado:** Todos aparecen (sin conflictos)

---

## 🔗 Integración con Backend

**El backend ya valida esto:**

En `backend/src/services/horario.service.ts`:
```typescript
if (profesorId) {
  const horariosProfesor = await prisma.horario.findMany({
    where: {
      profesorId: profesorId,
      diaSemana: diaSemana,
    },
  });
  
  // Validar conflictos con la misma lógica
  const hayConflicto = inicioMinutos < hFin && finMinutos > hInicio;
  
  if (hayConflicto) {
    throw new ConflictError('Profesor tiene conflicto en este horario');
  }
}
```

**Entonces:**
- ✅ Frontend: Filtra para mejor UX
- ✅ Backend: Valida para seguridad

---

## 📊 Resumen

| Aspecto | Antes | Después |
|--------|-------|---------|
| Mostraba | Todos los profesores | Solo disponibles |
| Validación | Solo backend | Frontend + Backend |
| Información | Ninguna | "X disponibles" |
| UX | Confusa | Clara |
| Conflictos | Detectados en servidor | Evitados desde cliente |

---

## 🎉 Beneficios

✅ **Mejor UX** - Usuario no ve opciones que después fallarán  
✅ **Feedback inmediato** - Cambia el dropdown al cambiar horas  
✅ **Información clara** - Muestra cuántos disponibles  
✅ **Validación doble** - Cliente + servidor  
✅ **Sincronizado** - Con los datos cargados

---

## 📝 Documentación

Se han creado:
- Este documento: PROFESORES_DISPONIBLES_FEATURE.md
- Cambios en 2 archivos:
  - `lib/providers/horario_provider.dart`
  - `lib/screens/academic/horarios_screen.dart`

---

*Implementación completada - 15 de Noviembre 2025*
*Desarrollador: GitHub Copilot*
