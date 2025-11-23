const fs = require('fs');
const path = require('path');

const routesDir = path.join(__dirname, 'src', 'routes');

// Mapa de reemplazos (orden importa: más específicos primero)
const replacements = [
  // Arrays de 2 elementos
  { from: "authorize(['super_admin', 'admin_institucion'])", to: "authorize([UserRole.SUPER_ADMIN, UserRole.ADMIN_INSTITUCION])" },
  { from: "authorize(['admin_institucion', 'super_admin'])", to: "authorize([UserRole.ADMIN_INSTITUCION, UserRole.SUPER_ADMIN])" },
  { from: "authorize(['profesor', 'admin_institucion'])", to: "authorize([UserRole.PROFESOR, UserRole.ADMIN_INSTITUCION])" },
  { from: "authorize(['admin_institucion', 'profesor'])", to: "authorize([UserRole.ADMIN_INSTITUCION, UserRole.PROFESOR])" },
  // Arrays de 1 elemento
  { from: "authorize(['super_admin'])", to: "authorize([UserRole.SUPER_ADMIN])" },
  { from: "authorize(['admin_institucion'])", to: "authorize([UserRole.ADMIN_INSTITUCION])" },
  { from: "authorize(['profesor'])", to: "authorize([UserRole.PROFESOR])" },
  { from: "authorize(['estudiante'])", to: "authorize([UserRole.ESTUDIANTE])" },
];

// Importación a agregar
const importLine = "import { UserRole } from '../constants/roles';";

// Procesar archivos
const files = fs.readdirSync(routesDir).filter(f => f.endsWith('.ts'));

let totalReplacements = 0;
let filesModified = 0;

files.forEach(file => {
  const filePath = path.join(routesDir, file);
  let content = fs.readFileSync(filePath, 'utf-8');
  
  let modified = false;
  
  // Verificar si necesita el import
  if (!content.includes("import { UserRole }") && content.includes("authorize([")) {
    // Agregar import después del primer import
    const firstImportEnd = content.indexOf('\n', content.indexOf('import '));
    if (firstImportEnd !== -1) {
      content = content.slice(0, firstImportEnd + 1) + importLine + '\n' + content.slice(firstImportEnd + 1);
      modified = true;
    }
  }
  
  // Aplicar reemplazos
  replacements.forEach(({ from, to }) => {
    const regex = new RegExp(from.replace(/[()[\]]/g, '\\$&'), 'g');
    const matches = content.match(regex);
    if (matches) {
      content = content.replace(regex, to);
      totalReplacements += matches.length;
      modified = true;
    }
  });
  
  if (modified) {
    // Crear backup
    fs.writeFileSync(filePath + '.bak', fs.readFileSync(filePath));
    // Escribir nuevo contenido
    fs.writeFileSync(filePath, content);
    filesModified++;
    console.log(`✅ ${file}: ${modified ? 'modificado' : 'sin cambios'}`);
  }
});

console.log(`\n📊 Resumen:`);
console.log(`   • Archivos modificados: ${filesModified}`);
console.log(`   • Reemplazos totales: ${totalReplacements}`);
