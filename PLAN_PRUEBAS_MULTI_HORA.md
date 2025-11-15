# Plan de Pruebas - Funcionalidad Multi-Hora en Horarios

## Resumen Ejecutivo
Este plan de pruebas valida la implementación completa de la funcionalidad multi-hora en la pantalla de gestión de horarios, incluyendo creación, edición, visualización y validación de conflictos.

## Alcance de las Pruebas

### 1. Pruebas de Frontend (Flutter)

#### 1.1 Visualización Multi-Hora
- **Objetivo**: Verificar que las clases multi-hora se muestren correctamente en el calendario semanal
- **Casos de prueba**:
  - Clase de 1 hora: Debe ocupar 1 celda (60px)
  - Clase de 2 horas: Debe ocupar 2 celdas (120px)
  - Clase de 3 horas: Debe ocupar 3 celdas (180px)
  - Clase de 4+ horas: Debe ocupar múltiples celdas proporcionalmente

#### 1.2 Creación de Clases Multi-Hora
- **Objetivo**: Validar la creación de clases con duración variable
- **Casos de prueba**:
  - Crear clase de 1 hora (08:00-09:00)
  - Crear clase de 2 horas (08:00-10:00)
  - Crear clase de 3 horas (08:00-11:00)
  - Validar que horaFin > horaInicio
  - Validar límites de horario (máximo 18:00)

#### 1.3 Edición de Clases Multi-Hora
- **Objetivo**: Verificar modificación de duración en clases existentes
- **Casos de prueba**:
  - Cambiar duración de 1 a 2 horas
  - Cambiar duración de 2 a 1 hora
  - Cambiar duración de 2 a 3 horas
  - Validar actualización visual inmediata

#### 1.4 Ocupación de Celdas
- **Objetivo**: Asegurar que las celdas ocupadas por clases multi-hora no sean clickeables
- **Casos de prueba**:
  - Celda ocupada por extensión de clase anterior: No debe ser clickeable
  - Celda con clase que comienza: Debe ser clickeable para edición
  - Celda vacía: Debe ser clickeable para creación

### 2. Pruebas de Backend (Node.js/TypeScript)

#### 2.1 Validación de Conflictos
- **Objetivo**: Verificar detección correcta de conflictos de horario
- **Casos de prueba**:
  - Conflicto de grupo: Dos clases del mismo grupo en el mismo horario
  - Conflicto de profesor: Mismo profesor en dos clases simultáneas
  - Solapamiento parcial: Una clase comienza durante otra
  - Solapamiento completo: Una clase contenida dentro de otra
  - No conflicto: Clases consecutivas sin solapamiento

#### 2.2 Creación de Horarios Multi-Hora
- **Objetivo**: Validar creación de horarios con duración variable
- **Casos de prueba**:
  - Crear horario válido de 1 hora
  - Crear horario válido de múltiples horas
  - Rechazar horario con horaFin <= horaInicio
  - Rechazar horario con formato inválido

#### 2.3 Actualización de Horarios Multi-Hora
- **Objetivo**: Verificar actualización de duración y conflictos
- **Casos de prueba**:
  - Cambiar duración sin crear conflictos
  - Cambiar duración creando conflicto de grupo
  - Cambiar duración creando conflicto de profesor
  - Cambiar profesor creando conflicto

### 3. Pruebas de Integración

#### 3.1 Flujo Completo de Creación
- **Objetivo**: Validar el flujo completo desde UI hasta base de datos
- **Pasos**:
  1. Usuario selecciona grupo
  2. Click en celda vacía
  3. Selecciona materia y profesor
  4. Selecciona horaFin (multi-hora)
  5. Confirma creación
  6. Verifica visualización correcta
  7. Verifica persistencia en BD

#### 3.2 Flujo Completo de Edición
- **Objetivo**: Validar modificación completa de clases existentes
- **Pasos**:
  1. Usuario click en clase existente
  2. Modifica horaFin
  3. Cambia profesor opcionalmente
  4. Confirma cambios
  5. Verifica actualización visual
  6. Verifica persistencia en BD

#### 3.3 Manejo de Conflictos
- **Objetivo**: Validar manejo completo de errores de conflicto
- **Casos de prueba**:
  - Conflicto detectado: Mostrar diálogo con información detallada
  - Diálogo informativo: Mostrar IDs de horarios en conflicto
  - Sugerencias útiles: Proporcionar opciones de resolución
  - Recuperación: Permitir reintento después de corrección

### 4. Pruebas de Regresión

#### 4.1 Funcionalidad Existente
- **Objetivo**: Asegurar que cambios no rompan funcionalidad existente
- **Casos de prueba**:
  - Creación de clases de 1 hora (comportamiento anterior)
  - Edición de profesor (sin cambiar duración)
  - Eliminación de clases
  - Cambio de grupo/materia
  - Navegación entre grupos

#### 4.2 Rendimiento
- **Objetivo**: Verificar que cambios no afecten rendimiento
- **Casos de prueba**:
  - Carga inicial de horarios
  - Renderizado de calendario con muchas clases
  - Creación/edición rápida
  - Manejo de errores sin bloqueos

### 5. Pruebas de UI/UX

#### 5.1 Diseño Responsivo
- **Objetivo**: Verificar visualización correcta en diferentes tamaños
- **Casos de prueba**:
  - Pantalla móvil: Clases multi-hora legibles
  - Pantalla tablet: Espacio adecuado para información
  - Pantalla desktop: Información completa visible

#### 5.2 Accesibilidad
- **Objetivo**: Asegurar usabilidad para todos los usuarios
- **Casos de prueba**:
  - Contraste de colores en clases multi-hora
  - Texto legible en celdas expandidas
  - Navegación por teclado
  - Lectores de pantalla

### 6. Estrategia de Ejecución

#### 6.1 Fases de Prueba
1. **Fase 1 - Unitarias**: Pruebas individuales de métodos
2. **Fase 2 - Integración**: Pruebas de componentes combinados
3. **Fase 3 - Sistema**: Pruebas end-to-end completas
4. **Fase 4 - Regresión**: Validación de funcionalidad existente
5. **Fase 5 - Aceptación**: Pruebas con usuarios finales

#### 6.2 Entornos de Prueba
- **Desarrollo**: Pruebas unitarias y de integración
- **Staging**: Pruebas de sistema completas
- **Producción**: Pruebas de aceptación y monitoreo

#### 6.3 Herramientas de Prueba
- **Frontend**: Flutter integration tests, widget tests
- **Backend**: Jest, Supertest para APIs
- **E2E**: Flutter driver o similar para flujos completos
- **Base de datos**: Datos de prueba controlados

### 7. Criterios de Aceptación

#### 7.1 Requisitos Funcionales
- [ ] Las clases multi-hora se muestran ocupando múltiples celdas proporcionalmente
- [ ] La creación permite seleccionar duración variable (horaFin)
- [ ] La edición permite modificar duración de clases existentes
- [ ] Los conflictos se detectan correctamente para grupos y profesores
- [ ] Los diálogos de conflicto muestran información detallada y sugerencias

#### 7.2 Requisitos No Funcionales
- [ ] Rendimiento: No degradación en carga de horarios
- [ ] Usabilidad: Interfaz intuitiva para selección de duración
- [ ] Accesibilidad: Contraste y legibilidad adecuados
- [ ] Compatibilidad: Funciona en diferentes tamaños de pantalla

### 8. Riesgos y Mitigación

#### 8.1 Riesgos Identificados
- **Riesgo**: Lógica de ocupación de celdas compleja puede tener bugs
  - **Mitigación**: Pruebas exhaustivas de casos edge, code review
- **Riesgo**: Conflictos de validación pueden fallar en casos edge
  - **Mitigación**: Casos de prueba exhaustivos para solapamientos
- **Riesgo**: Rendimiento degradado con muchas clases multi-hora
  - **Mitigación**: Optimización de renderizado, pruebas de performance

#### 8.2 Plan de Contingencia
- Rollback plan: Revertir a versión anterior si bugs críticos
- Feature flags: Capacidad de desactivar funcionalidad si necesario
- Monitoreo: Logs detallados para debugging en producción

### 9. Métricas de Éxito

#### 9.1 Cobertura de Pruebas
- Cobertura de código: > 80%
- Casos de prueba ejecutados: 100%
- Defectos encontrados vs corregidos: Ratio < 0.1

#### 9.2 Calidad
- Tiempo de respuesta UI: < 100ms para interacciones
- Tasa de errores: < 1% en operaciones normales
- Satisfacción usuario: > 4.5/5 en pruebas de aceptación</content>
<parameter name="filePath">c:\Proyectos\DemoLife\PLAN_PRUEBAS_MULTI_HORA.md