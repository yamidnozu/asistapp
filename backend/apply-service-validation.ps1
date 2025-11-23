# PowerShell script to add time validation to horario.service.ts

$filePath = ".\src\services\horario.service.ts"
$content = Get-Content $filePath -Raw -Encoding UTF8

# 1. Add import for validateTimeFormat at the top (after existing imports, line 3)
$oldImports = @"
import { prisma } from '../config/database';
import { ConflictError, Not FoundError, PaginatedResponse, PaginationParams, ValidationError } from '../types';

export interface HorarioFilters {
"@

$newImports = @"
import { prisma } from '../config/database';
import { ConflictError, NotFoundError, PaginatedResponse, PaginationParams, ValidationError } from '../types';
import { validateTimeFormat } from '../utils/time-validation';

export interface HorarioFilters {
"@

$content = $content.Replace($oldImports, $newImports)

# 2. Add time validation in createHorario (after line 598, before validating periodo)
# We'll insert after the stringify log and before the periodo comment
$marker1 = "      console.log('🔍 DEBUG: Iniciando createHorario con data:', JSON.stringify(data, null, 2));"
$replacement1 = @"
      console.log('🔍 DEBUG: Iniciando createHorario con data:', JSON.stringify(data, null, 2));

      // Validar formato de horas (HH:MM con padding de ceros)
      validateTimeFormat(data.horaInicio, data.horaFin);
"@

$content = $content.Replace($marker1, $replacement1)

# 3. Add time validation in updateHorario (after line 801, before grupo validation)
$marker2 = @"
      const horaInicio = data.horaInicio || existingHorario.horaInicio;
      const horaFin = data.horaFin || existingHorario.horaFin;

      // Si se está cambiando el grupo, validar que existe
"@

$replacement2 = @"
      const horaInicio = data.horaInicio || existingHorario.horaInicio;
      const horaFin = data.horaFin || existingHorario.horaFin;

      // Validar formato de horas (HH:MM con padding de ceros)
      validateTimeFormat(horaInicio, horaFin);

      // Si se está cambiando el grupo, validar que existe
"@

$content = $content.Replace($marker2, $replacement2)

# Write the modified content back
Set-Content -Path $filePath -Value $content -Encoding UTF8

Write-Host "Time validation added to horario.service.ts successfully!"
