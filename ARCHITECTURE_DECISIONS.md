# Decisiones Arquitectónicas - AsistApp

Este documento registra las decisiones arquitectónicas importantes tomadas durante el desarrollo de AsistApp.

## Índice
1. [Manejo de Fechas en UTC](#decisión-1-manejo-de-fechas-en-utc)
2. [Sistema de Constantes Centralizadas](#decisión-2-sistema-de-constantes-centralizadas)
3. [Sistema de Roles y Autorizaciones](#decisión-3-sistema-de-roles-y-autorizaciones)

---

## Decisión #1: Manejo de Fechas en UTC

**Fecha**: 2025-11-18  
**Estado**: Aprobado  
**Decisores**: Equipo de Desarrollo

### Contexto
El sistema tenía inconsistencias en el manejo de fechas:
- El backend mezclaba fechas locales del servidor con fechas UTC
- Al registrar asistencias, usaba `new Date()` y `setHours(0,0,0,0)` (hora local)
- Al consultar asistencias, creaba fechas con `Date.UTC()` (hora UTC)
- Esto causaba que "hoy" pudiera ser diferente dependiendo de la hora y zona horaria del servidor

### Problema
Si el servidor está en una zona horaria diferente a la del colegio (ej. servidor en UTC, colegio en UTC-5), pueden ocurrir:
1. Asistencias registradas el día incorrecto
2. Reportes que no muestran asistencias del día actual
3. Duplicados de asistencia cuando se cruza medianoche
4. Inconsistencia entre lo que ve el profesor en la app y lo registrado en BD

### Decisión
**Estandarizar TODO el manejo de fechas a UTC en el backend:**
- Crear utilidades centralizadas en `backend/src/utils/date.utils.ts`
- Usar `getStartOf Day()` para obtener el inicio del día en UTC
- Usar `parseDateString()` para parsear fechas de strings
- Usar `formatDateToISO()` para formatear fechas de respuesta
- Almacenar todas las fechas en BD como UTC
- El frontend debe manejar la conversión a zona horaria local solo para visualización

### Consecuencias
**Positivas:**
- Consistencia total en el manejo de fechas
- No hay ambigüedad sobre "qué día es hoy"
- Funciona correctamente sin importar dónde esté el servidor
- Facilita testing y debugging

**Negativas:**
- Requiere actualizar TODO el código que maneja fechas
- Los desarrolladores deben ser conscientes de siempre usar UTC
- Posible confusión inicial al ver fechas en UTC en la BD

**Mitigación:**
- Documentar claramente en código con comentarios
- Crear funciones de utilidad fáciles de usar
- Agregar tests que validen el comportamiento correcto

---

## Decisión #2: Sistema de Constantes Centralizadas

**Fecha**: 2025-11-18  
**Estado**: Aprobado  
**Decisores**: Equipo de Desarrollo

### Contexto
El código tenía "magic strings" (cadenas mágicas) dispersas por toda la aplicación:
- Roles: `'profesor'`, `'estudiante'`, `'admin_institucion'`, `'super_admin'`
- Estados de asistencia: `'PRESENTE'`, `'AUSENTE'`, `'TARDANZA'`, `'JUSTIFICADO'`
- Tipos de registro: `'MANUAL'`, `'QR'`, `'AUTOMATICO'`

### Problema
- **Errores de tipeo**: Un `'professor'` (con doble 's') rompe la lógica silenciosamente
- **Difícil de refactorizar**: Cambiar un valor requiere buscar y reemplazar en múltiples archivos
- **Sin autocomplete**: Los IDEs no ayudan con sugerencias
- **Inconsistencias**: Backend usa `'PRESENTE'` y frontend podría usar `'presente'`

### Decisión
**Crear archivos de constantes centralizadas:**

Backend (`backend/src/constants/`):
- `roles.ts` - Enum `UserRole` con todos los roles
- `attendance.ts` - Enums `AttendanceStatus` y `AttendanceType`

Frontend (`lib/constants/`):
- `roles.dart` - Clase `UserRoles` con constantes estáticas
- `attendance.dart` - Clases `AttendanceStatus` y `AttendanceType`

**Además, incluir funciones de utilidad:**
- `isValid(value)` - Valida si un string es un valor válido
- `getName(value)` - Obtiene nombre legible para UI
- `getColor(value)` - Obtiene color asociado (para attendance)

### Consecuencias
**Positivas:**
- Eliminación de errores de tipeo
- Autocomplete en IDEs
- Un solo lugar para cambiar valores
- Validación tipo-segura en TypeScript
- Código más mantenible y legible

**Negativas:**
- Requiere actualizar TODOS los archivos que usan strings
- Imports adicionales en cada archivo
- Curva de aprendizaje para nuevos desarrolladores

**Implementación:**
- Crear archivos de constantes primero
- Actualizar servicios uno por uno
- Actualizar modelos frontend
- Agregar tests para validar el uso correcto

---

## Decisión #3: Sistema de Roles y Autorizaciones

**Fecha**: 2025-11-18  
**Estado**: En Evaluación  
**Decisores**: Equipo de Desarrollo

### Contexto
El sistema actual tiene una dualidad confusa:
- `Usuario.rol` - Rol global del usuario (ej. 'profesor')
- `UsuarioInstitucion.rolEnInstitucion` - Rol específico en cada institución (opcional)
- La lógica actual se basa principalmente en `Usuario.rol`

### Problema
**Limitación actual:** Un usuario NO puede tener diferentes roles en diferentes instituciones.

**Escenario problemático:**
- Juan es **Profesor** en el Colegio A
- Juan es **Administrador** en el Colegio B (donde también es director)
- Con el sistema actual: Juan solo puede tener UN rol global

### Opciones Evaluadas

#### Opción A: Migrar a Roles Basados en Contexto
**Propuesta:** El `rol` debe determinarse por el contexto de la institución activa.

**Pros:**
- Soporta múltiples roles por usuario
- Más flexible y escalable

**Contras:**
- Requiere refactorización significativa de middleware de auth
- Cada request debe incluir `institucionId` en contexto
- Complejidad adicional en lógica de autorización

#### Opción B: Mantener Rol Global, Eliminar rolEnInstitucion
**Propuesta:** Eliminar `rolEnInstitucion` completamente si no se planea soportar multi-rol.

**Pros:**
- Simplifica el esquema
- Elimina confusión
- Menos complejidad

**Contras:**
- Limitado a un rol por usuario
- No escalable a futuro

### Decisión (Pendiente)
**Recomendación:** Mantener el sistema actual por ahora, pero DOCUMENTAR la limitación.

**Para futuro:**
- Si se necesita soporte multi-rol: Opción A
- Si se confirma que nunca se necesitará: Opción B

### Consecuencias
**Acción inmediata:**
- Documentar claramente la limitación en el README
- Agregar validación para evitar asignaciones conflictivas
- Decidir si `rolEnInstitucion` debe deprecarse o usarse

---

## Registro de Cambios

| Fecha | Decisión | Cambios |
|-------|----------|---------|
| 2025-11-18 | Manejo de Fechas UTC | Aprobado e implementado |
| 2025-11-18 | Constantes Centralizadas | Aprobado e implementado |
| 2025-11-18 | Sistema de Roles | En evaluación |
