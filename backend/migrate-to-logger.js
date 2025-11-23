#!/usr/bin/env node
/**
 * Script para migrar console.log/error/warn a logger
 * Uso: node migrate-to-logger.js
 */

const fs = require('fs');
const path = require('path');

// Archivos a procesar (servicios y controladores)
const files = [
  'src/services/admin-institucion.service.ts',
  'src/services/auth.service.ts',
  'src/services/grupo.service.ts',
  'src/services/user.service.ts',
  'src/services/periodo-academico.service.ts',
  'src/services/materia.service.ts',
  'src/services/institucion.service.ts',
  'src/services/horario.service.ts',
  'src/services/estudiante.service.ts',
  'src/services/asistencia.service.ts',
  'src/controllers/auth.controller.ts',
  'src/controllers/horario.controller.ts',
  'src/controllers/profesor.controller.ts',
  'src/controllers/estudiante.controller.ts',
];

let totalReplacements = 0;
let filesModified = 0;

files.forEach((file) => {
  const filePath = path.join(__dirname, file);
  
  if (!fs.existsSync(filePath)) {
    console.log(`⏭️  Skipping ${file} (no existe)`);
    return;
  }

  let content = fs.readFileSync(filePath, 'utf8');
  const originalContent = content;
  let replacements = 0;

  // 1. Reemplazar console.error por logger.error
  const errorCount = (content.match(/console\.error\(/g) || []).length;
  content = content.replace(/console\.error\(/g, 'logger.error(');
  replacements += errorCount;

  // 2. Reemplazar console.warn por logger.warn
  const warnCount = (content.match(/console\.warn\(/g) || []).length;
  content = content.replace(/console\.warn\(/g, 'logger.warn(');
  replacements += warnCount;

  // 3. Reemplazar console.log por logger.debug (solo si no es NODE_ENV check)
  // Excluir console.log dentro de if (config.nodeEnv === 'development')
  let logReplacements = 0;
  const lines = content.split('\n');
  const newLines = lines.map((line, index) => {
    // Si la línea contiene console.log
    if (line.includes('console.log(')) {
      // Verificar si las líneas anteriores tienen if (config.nodeEnv === 'development')
      let isDevelopmentGuarded = false;
      for (let i = Math.max(0, index - 3); i < index; i++) {
        if (lines[i].includes("config.nodeEnv === 'development'") ||
            lines[i].includes('config.nodeEnv === "development"')) {
          isDevelopmentGuarded = true;
          break;
        }
      }
      
      if (!isDevelopmentGuarded) {
        logReplacements++;
        return line.replace(/console\.log\(/g, 'logger.debug(');
      }
    }
    return line;
  });
  
  content = newLines.join('\n');
  replacements += logReplacements;

  // 4. Agregar import de logger si se hicieron cambios y no existe
  if (replacements > 0 && !content.includes("import logger from '../utils/logger'")) {
    // Encontrar la última línea de imports
    const importLines = content.split('\n');
    let lastImportIndex = -1;
    
    for (let i = 0; i < importLines.length; i++) {
      if (importLines[i].trim().startsWith('import ')) {
        lastImportIndex = i;
      }
      // Si ya pasamos los imports, salir
      if (lastImportIndex > -1 && !importLines[i].trim().startsWith('import ') && importLines[i].trim() !== '') {
        break;
      }
    }
    
    if (lastImportIndex > -1) {
      importLines.splice(lastImportIndex + 1, 0, "import logger from '../utils/logger';");
      content = importLines.join('\n');
      console.log(`  ➕ Agregado import de logger`);
    }
  }

  // Guardar si hubo cambios
  if (content !== originalContent) {
    fs.writeFileSync(filePath, content, 'utf8');
    filesModified++;
    totalReplacements += replacements;
    console.log(`✅ ${file}: ${replacements} reemplazos`);
    if (errorCount > 0) console.log(`   - console.error: ${errorCount}`);
    if (warnCount > 0) console.log(`   - console.warn: ${warnCount}`);
    if (logReplacements > 0) console.log(`   - console.log: ${logReplacements}`);
  } else {
    console.log(`⏭️  ${file}: sin cambios`);
  }
});

console.log(`\n📊 Resumen:`);
console.log(`   Archivos modificados: ${filesModified}`);
console.log(`   Total de reemplazos: ${totalReplacements}`);
