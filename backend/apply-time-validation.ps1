# PowerShell script to add time validation to horario.controller.ts

$filePath = ".\src\controllers\horario.controller.ts"
$content = Get-Content $filePath -Raw

# 1. Add import for validateTimeFormat
$oldImport = "import { NotFoundError, ValidationError } from '../types';"
$newImport = "import { NotFoundError, ValidationError } from '../types';`nimport { validateTimeFormat } from '../utils/time-validation';"
$content = $content.Replace($oldImport, $newImport)

# 2. Add time validation in create method (after profesorId validation, before data object creation)
$oldPattern = "      }

      const data = {"
$newPattern = "      }

      // Validar formato de horas
      try {
        validateTimeFormat(request.body.horaInicio, request.body.horaFin);
      } catch (error) {
        return reply.code(400).send({
          success: false,
          error: (error as Error).message,
          code: 'VALIDATION_ERROR'
        });
      }

      const data = {"
$content = $content.Replace($oldPattern, $newPattern)

# 3. Add time validation in update method
$oldUpdate = "      if (usuarioInstitucion && existingHorario.institucionId !== usuarioInstitucion.institucionId) {
        return reply.code(403).send({
          success: false,
          error: 'No tienes permisos para modificar este horario',
        });
      }

      const horario = await HorarioService.updateHorario(id, data);"

$newUpdate = "      if (usuarioInstitucion && existingHorario.institucionId !== usuarioInstitucion.institucionId) {
        return reply.code(403).send({
          success: false,
          error: 'No tienes permisos para modificar este horario',
        });
      }

      // Validar formato de horas si se proporcionan
      if (data.horaInicio || data.horaFin) {
        const horaInicio = data.horaInicio || existingHorario.horaInicio;
        const horaFin = data.horaFin || existingHorario.horaFin;
        try {
          validateTimeFormat(horaInicio, horaFin);
        } catch (error) {
          return reply.code(400).send({
            success: false,
            error: (error as Error).message,
            code: 'VALIDATION_ERROR'
          });
        }
      }

      const horario = await HorarioService.updateHorario(id, data);"
$content = $content.Replace($oldUpdate, $newUpdate)

# Write the modified content back
Set-Content -Path $filePath -Value $content

Write-Host "✅ Time validation added to horario.controller.ts successfully!"
