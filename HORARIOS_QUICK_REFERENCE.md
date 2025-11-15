# 🚀 QUICK REFERENCE - Límites Horarios

## Resumen Ejecutivo

✅ **Estado**: Los límites horarios funcionan correctamente
✅ **Validación**: Detecta todos los tipos de solapamientos
✅ **Error 409**: Es correcto y esperado cuando hay conflictos

---

## Cómo Funciona

### Regla Simple

```
Hay conflicto si:
Nueva empieza ANTES de que termine la existente
     AND
Nueva termina DESPUÉS de que empiece la existente
```

### En Minutos

```
CONFLICTO = (inicioNuevo < finExistente) AND (finNuevo > inicioExistente)
```

### En Español

Si quieres crear una clase de 09:00 a 11:00 y ya existe una de 08:00 a 10:00:
- ¿Empieza la nueva antes de que termine la existente? 09:00 < 10:00 = SÍ ✓
- ¿Termina la nueva después de que empiece la existente? 11:00 > 08:00 = SÍ ✓
- Resultado: ❌ CONFLICTO

---

## Casos de Uso

### ✅ ACEPTADO: Horarios Consecutivos
```
Existente: 08:00 - 10:00
Nueva:    10:00 - 12:00
Resultado: ✅ Se crea correctamente
```

### ❌ RECHAZADO: Conflicto Total
```
Existente: 08:00 - 10:00
Nueva:    08:00 - 10:00
Resultado: ❌ Error 409
```

### ❌ RECHAZADO: Conflicto Parcial
```
Existente: 08:00 - 10:00
Nueva:    09:00 - 11:00
Resultado: ❌ Error 409
```

### ❌ RECHAZADO: Conflicto Contención
```
Existente: 08:00 - 10:00
Nueva:    07:00 - 11:00
Resultado: ❌ Error 409
```

---

## Cuándo Obtienes Error 409

```
❌ POST /horarios - Status: 409
   Error: "El grupo ya tiene una clase programada en este horario"
   Code: "CONFLICT_ERROR"
   Reason: "grupo_conflict"
   Meta: { conflictingHorarioIds: ["id-del-horario-conflictivo"] }
```

**Significa**: Ya existe una clase que se solapa con la que intentas crear.

**Qué hacer**: Elige otro horario que no tenga conflicto.

---

## Limitaciones Actuales

1. Solo se valida grupo y profesor
2. No se valida aula/salón
3. No se valida período activo
4. No hay restricción de horarios válidos (7:00-19:00)

Mejoras propuestas en: `MEJORAS_FUTURAS_HORARIOS.md`

---

## Pruebas Documentadas

Ejecutado en: 14 de Noviembre 2025

```
✅ Conflicto Total - DETECTADO
✅ Conflicto Parcial Inicio - DETECTADO
✅ Conflicto Parcial Fin - DETECTADO
✅ Conflicto Contención - DETECTADO
✅ Sin Conflicto - ACEPTADO
```

---

## Archivos de Referencia

| Archivo | Propósito |
|---------|-----------|
| `RESUMEN_LIMITES_HORARIOS.md` | Resumen completo con cambios |
| `PRUEBAS_LIMITES_HORARIOS.md` | Documentación técnica |
| `VISUALIZACION_LIMITES_HORARIOS.md` | Ejemplos gráficos |
| `MEJORAS_FUTURAS_HORARIOS.md` | Recomendaciones futuras |
| `test-conflictos-simples.sh` | Script de pruebas |

---

## Preguntas Frecuentes

### P: ¿Por qué me rechaza la clase?
R: Porque ya existe otra clase que se solapa. Elige otro horario.

### P: ¿Puedo crear clases consecutivas?
R: SÍ. 08:00-10:00 y 10:00-12:00 no entran en conflicto.

### P: ¿Se validan aulas?
R: No por ahora. Solo grupo y profesor.

### P: ¿Se valida profesor?
R: SÍ. Un profesor no puede tener dos clases al mismo tiempo.

### P: ¿Hay horarios permitidos?
R: No hay restricción. Puedes crear desde 00:00 a 23:59.

---

## Estado Actual

✅ **LISTO PARA PRODUCCIÓN**

- Lógica de validación: Correcta
- Pruebas: Exitosas
- Documentación: Completa
- Logging: Detallado

---

**Última actualización**: 14 de Noviembre 2025
**Versión**: 1.0
**Estado**: APROBADO ✅
