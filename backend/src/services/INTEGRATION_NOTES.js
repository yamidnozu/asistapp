// Script para integrar validación de horas en horario.service.ts
// Aplicar manualmente estos cambios

// 1. AGREGAR IMPORT (línea 3, después de los otros imports)
// import { validateTimeFormat } from '../utils/time-validation';

// 2. EN createHorario (buscar "public static async createHorario", aproximadamente línea 481)
// Agregar DESPUÉS de las validaciones iniciales y ANTES de validateHorarioConflict:

// Validar formato de horas
validateTimeFormat(data.horaInicio, data.horaFin);

// 3. EN updateHorario (buscar "public static async updateHorario", aproximadamente línea 742)
// Agregar DESPUÉS de obtener el horario actual:

const newHoraInicio = data.horaInicio ?? horarioActual.horaInicio;
const newHoraFin = data.horaFin ?? horarioActual.horaFin;
validateTimeFormat(newHoraInicio, newHoraFin);

// LISTO! Esos son los únicos 3 cambios necesarios.
