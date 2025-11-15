# 🔮 Mejoras Futuras Sugeridas - Límites Horarios

**Documento**: Recomendaciones para optimización
**Prioridad**: Media-Baja (Sistema ya funciona correctamente)

## 1. 🎯 Validación de Aulas/Salones

### Problema Actual
- Solo se validan conflictos de grupo y profesor
- No se valida si el aula/salón ya está en uso

### Propuesta
```typescript
// Agregar campo aulaId a horario
if (aulaId) {
  const aulaConflicts = await prisma.horario.findMany({
    where: {
      aulaId: aulaId,
      diaSemana: diaSemana,
      // ... validación de tiempo
    }
  });
}
```

### Beneficio
- Mayor control de recursos
- Mejor asignación de aulas

---

## 2. 📅 Validación de Períodos Académicos

### Problema Actual
- Se permite crear horarios en cualquier período
- No se valida si el período está activo

### Propuesta
```typescript
// Validar período activo
const periodo = await prisma.periodoAcademico.findFirst({
  where: { id: data.periodoId, activo: true }
});

if (!periodo) {
  throw new ValidationError('El período académico no está activo');
}
```

### Beneficio
- Evita horarios en períodos cerrados
- Mejor control de ciclos académicos

---

## 3. ⏰ Restricción de Horarios Válidos

### Problema Actual
- Se permiten horarios en cualquier hora del día

### Propuesta
```typescript
// Definir horas válidas por institución
const HORARIO_VALIDO = {
  minimo: 7 * 60,      // 07:00
  maximo: 19 * 60,     // 19:00
  intervalo: 30        // solo 30min o 1hora
};

if (inicioMinutos < HORARIO_VALIDO.minimo) {
  throw new ValidationError('Hora fuera de rango permitido');
}
```

### Beneficio
- Control de horario escolar
- Evita errores de entrada

---

## 4. 📊 Detección de Sobreasignación

### Problema Actual
- Un profesor puede tener muchas clases en poco tiempo

### Propuesta
```typescript
// Validar que profesor no tiene más de N clases por día
const clasesProfesor = await prisma.horario.findMany({
  where: { profesorId, diaSemana },
});

if (clasesProfesor.length >= MAX_CLASES_DIA) {
  throw new ValidationError('Profesor alcanzó máximo de clases por día');
}
```

### Beneficio
- Evita sobrecarga de profesores
- Mejor distribución de carga

---

## 5. 🔔 Notificaciones de Conflictos

### Problema Actual
- Usuario solo ve error 409
- No sabe exactamente qué horarios entran en conflicto

### Propuesta
```typescript
// Retornar detalles de conflictos
throw new ConflictError('Conflicto de horario', 'grupo_conflict', {
  conflictingHorarios: grupoConflicts.map(h => ({
    id: h.id,
    diaSemana: h.diaSemana,
    horaInicio: h.horaInicio,
    horaFin: h.horaFin,
    materia: h.materia.nombre,
    profesor: h.profesor?.nombres
  }))
});
```

### Beneficio
- UX mejorado
- Usuario ve exactamente qué conflictúa

---

## 6. 🗺️ Mapa de Horarios Disponibles

### Problema Actual
- Usuario no ve qué horarios están libres
- Tiene que probar uno por uno

### Propuesta
```typescript
// Endpoint para obtener horarios disponibles
GET /horarios/grupo/{grupoId}/disponibles?diaSemana={1-7}

Respuesta:
{
  "disponibles": [
    { "horaInicio": "07:00", "horaFin": "08:00", "disponible": true },
    { "horaInicio": "08:00", "horaFin": "09:00", "disponible": false, "conflictCon": "..." },
    ...
  ]
}
```

### Beneficio
- UI mejorada
- Usuario ve opciones disponibles de inmediato

---

## 7. 🔄 Suscripción a Cambios de Horarios

### Problema Actual
- Si otro admin cambia horarios, usuario no se entera

### Propuesta
```typescript
// WebSocket para actualizaciones en tiempo real
socket.on('horario:creado', (horario) => {
  // Actualizar UI
});

socket.on('horario:conflicto', (data) => {
  // Notificar conflicto
});
```

### Beneficio
- Sincronización en tiempo real
- Mejor colaboración entre admins

---

## 8. 📋 Reporte de Utilización de Horarios

### Problema Actual
- No hay visibilidad de horarios más concurridos

### Propuesta
```typescript
GET /reportes/utilizacion-horarios

Respuesta:
{
  "horarios": [
    {
      "diaSemana": 1,
      "horaInicio": "08:00",
      "horaFin": "10:00",
      "clasesProgamadas": 5,
      "salonesUtilizados": 3,
      "utilizacion": "83%"
    }
  ]
}
```

### Beneficio
- Mejor planificación
- Identificar cuellos de botella

---

## 9. 🎓 Horarios Recurrentes

### Problema Actual
- Crear cada clase una por una es tedioso
- Riesgo de errores de consistencia

### Propuesta
```typescript
// Crear horario recurrente
POST /horarios/recurrente
{
  "materiaId": "...",
  "grupoId": "...",
  "diasSemana": [1, 3, 5],  // Lunes, Miércoles, Viernes
  "horaInicio": "08:00",
  "horaFin": "10:00",
  "desde": "2025-01-01",
  "hasta": "2025-12-31"
}
```

### Beneficio
- Interfaz más rápida
- Consistencia garantizada

---

## 10. 📱 Sincronización con Google Calendar

### Problema Actual
- Horarios solo en app
- Estudiantes no pueden integrar con su calendario

### Propuesta
```typescript
// Exportar horario como iCalendar
GET /horarios/grupo/{grupoId}/ical

// Retorna .ics con todos los horarios
```

### Beneficio
- Integración con herramientas populares
- Mejor accesibilidad

---

## 🏆 Priorización Recomendada

### Corto Plazo (1-2 semanas)
1. ✅ Validación actual - **YA HECHO**
2. Validación de período activo
3. Restricción de horarios válidos

### Mediano Plazo (3-4 semanas)
4. Detección de sobreasignación
5. Mapa de horarios disponibles
6. Notificaciones mejoradas

### Largo Plazo (1-2 meses)
7. WebSocket para sincronización
8. Reportes de utilización
9. Horarios recurrentes
10. Integración Google Calendar

---

## 💡 Notas Generales

- La validación actual es **sólida y correcta**
- Las mejoras son para **UX y control de negocio**
- No afectan la seguridad o integridad de datos
- Pueden implementarse sin breaking changes

---

**Documento generado**: 14 de Noviembre 2025
**Revisado por**: Equipo de Desarrollo
**Estado**: Listo para revisión
