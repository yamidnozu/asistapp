// backend/prisma/seed.ts

const { PrismaClient } = require('@prisma/client');
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('🚀 Iniciando seed maestro v2 para AsistApp...');

  // 1. Limpieza de datos en orden de dependencia
  console.log('🧹 Limpiando base de datos...');
  await prisma.asistencia.deleteMany();
  await prisma.horario.deleteMany();
  await prisma.estudianteGrupo.deleteMany();
  await prisma.materia.deleteMany();
  await prisma.grupo.deleteMany();
  await prisma.periodoAcademico.deleteMany();
  await prisma.usuarioInstitucion.deleteMany();
  await prisma.estudiante.deleteMany();
  await prisma.usuario.deleteMany();
  await prisma.institucion.deleteMany();
  console.log('✅ Base de datos limpia.');

  // 2. Creación de Instituciones
  console.log('🏫 Creando instituciones...');
  const sanJose = await prisma.institucion.create({
    data: {
      nombre: 'Colegio San José',
      activa: true,
    },
  });

  const santander = await prisma.institucion.create({
    data: {
      nombre: 'IE Santander',
      activa: true,
    },
  });

  const inactiva = await prisma.institucion.create({
    data: {
      nombre: 'Liceo del Pasado (Inactivo)',
      activa: false,
    },
  });
  console.log('✅ Instituciones creadas.');

  // 3. Creación de Periodos Académicos
  console.log('📅 Creando periodos académicos...');
  const periodoSanJose = await prisma.periodoAcademico.create({
    data: {
      nombre: 'Año Lectivo 2025',
      fechaInicio: new Date('2025-01-20'),
      fechaFin: new Date('2025-11-28'),
      activo: true,
      institucionId: sanJose.id,
    },
  });

  const periodoSantander = await prisma.periodoAcademico.create({
    data: {
      nombre: 'Semestre 2025-1',
      fechaInicio: new Date('2025-02-01'),
      fechaFin: new Date('2025-06-15'),
      activo: true,
      institucionId: santander.id,
    },
  });
  console.log('✅ Periodos académicos creados.');

  // 4. Creación de Usuarios
  console.log('👥 Creando usuarios (admins, profesores, estudiantes)...');
  const hash = (pass: string) => bcrypt.hashSync(pass, 10);

  const usuarios = await prisma.usuario.createMany({
    data: [
      // Admins
      { email: 'superadmin@asistapp.com', passwordHash: hash('Admin123!'), nombres: 'Super', apellidos: 'Admin', rol: 'super_admin', activo: true },
      { email: 'admin@sanjose.edu', passwordHash: hash('SanJose123!'), nombres: 'Ana', apellidos: 'López', rol: 'admin_institucion', activo: true },
      { email: 'admin@santander.edu', passwordHash: hash('Santander123!'), nombres: 'Luis', apellidos: 'Rojas', rol: 'admin_institucion', activo: true },
      { email: 'multiadmin@asistapp.com', passwordHash: hash('Multi123!'), nombres: 'Pedro', apellidos: 'Páramo', rol: 'admin_institucion', activo: true },
      // Profesores San José
      { email: 'juan.perez@sanjose.edu', passwordHash: hash('Prof123!'), nombres: 'Juan', apellidos: 'Pérez', rol: 'profesor', activo: true },
      { email: 'laura.gomez@sanjose.edu', passwordHash: hash('Prof123!'), nombres: 'Laura', apellidos: 'Gómez', rol: 'profesor', activo: true },
      { email: 'vacio.profe@sanjose.edu', passwordHash: hash('Prof123!'), nombres: 'Profe', apellidos: 'Sin Clases', rol: 'profesor', activo: true },
      // Profesores Santander
      { email: 'carlos.diaz@santander.edu', passwordHash: hash('Prof123!'), nombres: 'Carlos', apellidos: 'Díaz', rol: 'profesor', activo: true },
      // Estudiantes San José
      { email: 'santiago.mendoza@sanjose.edu', passwordHash: hash('Est123!'), nombres: 'Santiago', apellidos: 'Mendoza', rol: 'estudiante', activo: true },
      { email: 'valentina.rojas@sanjose.edu', passwordHash: hash('Est123!'), nombres: 'Valentina', apellidos: 'Rojas', rol: 'estudiante', activo: true },
      { email: 'mateo.castro@sanjose.edu', passwordHash: hash('Est123!'), nombres: 'Mateo', apellidos: 'Castro', rol: 'estudiante', activo: true },
      { email: 'camila.ortiz@sanjose.edu', passwordHash: hash('Est123!'), nombres: 'Camila', apellidos: 'Ortiz', rol: 'estudiante', activo: true },
      { email: 'lucas.martinez@sanjose.edu', passwordHash: hash('Est123!'), nombres: 'Lucas', apellidos: 'Martínez', rol: 'estudiante', activo: true },
      { email: 'isabella.lopez@sanjose.edu', passwordHash: hash('Est123!'), nombres: 'Isabella', apellidos: 'López', rol: 'estudiante', activo: true },
      { email: 'sebastian.garcia@sanjose.edu', passwordHash: hash('Est123!'), nombres: 'Sebastián', apellidos: 'García', rol: 'estudiante', activo: true },
      { email: 'maria.fernandez@sanjose.edu', passwordHash: hash('Est123!'), nombres: 'María', apellidos: 'Fernández', rol: 'estudiante', activo: true },
      { email: 'diego.ramirez@sanjose.edu', passwordHash: hash('Est123!'), nombres: 'Diego', apellidos: 'Ramírez', rol: 'estudiante', activo: true },
      { email: 'sofia.torres@sanjose.edu', passwordHash: hash('Est123!'), nombres: 'Sofía', apellidos: 'Torres', rol: 'estudiante', activo: true },
      { email: 'andres.moreno@sanjose.edu', passwordHash: hash('Est123!'), nombres: 'Andrés', apellidos: 'Moreno', rol: 'estudiante', activo: true },
      { email: 'laura.sanchez@sanjose.edu', passwordHash: hash('Est123!'), nombres: 'Laura', apellidos: 'Sánchez', rol: 'estudiante', activo: true },
      { email: 'nicolas.vargas@sanjose.edu', passwordHash: hash('Est123!'), nombres: 'Nicolás', apellidos: 'Vargas', rol: 'estudiante', activo: true },
      { email: 'mariana.cruz@sanjose.edu', passwordHash: hash('Est123!'), nombres: 'Mariana', apellidos: 'Cruz', rol: 'estudiante', activo: true },
      { email: 'felipe.herrera@sanjose.edu', passwordHash: hash('Est123!'), nombres: 'Felipe', apellidos: 'Herrera', rol: 'estudiante', activo: true },
      // Estudiantes Santander
      { email: 'sofia.nunez@santander.edu', passwordHash: hash('Est123!'), nombres: 'Sofía', apellidos: 'Núñez', rol: 'estudiante', activo: true },
      { email: 'daniel.ruiz@santander.edu', passwordHash: hash('Est123!'), nombres: 'Daniel', apellidos: 'Ruiz', rol: 'estudiante', activo: true },
      { email: 'paula.mendez@santander.edu', passwordHash: hash('Est123!'), nombres: 'Paula', apellidos: 'Méndez', rol: 'estudiante', activo: true },
    ],
  });
  console.log(`✅ ${usuarios.count} usuarios creados.`);

  // Mapeo para fácil acceso
  const findUser = async (email: string) => (await prisma.usuario.findUnique({ where: { email } }))!;

  const superAdmin = await findUser('superadmin@asistapp.com');
  const adminSanJose = await findUser('admin@sanjose.edu');
  const adminSantander = await findUser('admin@santander.edu');
  const multiAdmin = await findUser('multiadmin@asistapp.com');
  const profJuan = await findUser('juan.perez@sanjose.edu');
  const profLaura = await findUser('laura.gomez@sanjose.edu');
  const profVacio = await findUser('vacio.profe@sanjose.edu');
  const profCarlos = await findUser('carlos.diaz@santander.edu');
  const estSantiago = await findUser('santiago.mendoza@sanjose.edu');
  const estValentina = await findUser('valentina.rojas@sanjose.edu');
  const estMateo = await findUser('mateo.castro@sanjose.edu');
  const estCamila = await findUser('camila.ortiz@sanjose.edu');
  const estLucas = await findUser('lucas.martinez@sanjose.edu');
  const estIsabella = await findUser('isabella.lopez@sanjose.edu');
  const estSebastian = await findUser('sebastian.garcia@sanjose.edu');
  const estMaria = await findUser('maria.fernandez@sanjose.edu');
  const estDiego = await findUser('diego.ramirez@sanjose.edu');
  const estSofiaT = await findUser('sofia.torres@sanjose.edu');
  const estAndres = await findUser('andres.moreno@sanjose.edu');
  const estLaura = await findUser('laura.sanchez@sanjose.edu');
  const estNicolas = await findUser('nicolas.vargas@sanjose.edu');
  const estMariana = await findUser('mariana.cruz@sanjose.edu');
  const estFelipe = await findUser('felipe.herrera@sanjose.edu');
  const estSofia = await findUser('sofia.nunez@santander.edu');
  const estDaniel = await findUser('daniel.ruiz@santander.edu');
  const estPaula = await findUser('paula.mendez@santander.edu');

  // 5. Vinculación Usuario-Institución
  console.log('🔗 Vinculando usuarios a instituciones...');
  await prisma.usuarioInstitucion.createMany({
    data: [
      { usuarioId: adminSanJose.id, institucionId: sanJose.id, rolEnInstitucion: 'admin' },
      { usuarioId: adminSantander.id, institucionId: santander.id, rolEnInstitucion: 'admin' },
      { usuarioId: multiAdmin.id, institucionId: sanJose.id, rolEnInstitucion: 'admin' },
      { usuarioId: multiAdmin.id, institucionId: santander.id, rolEnInstitucion: 'admin' },
      { usuarioId: profJuan.id, institucionId: sanJose.id, rolEnInstitucion: 'profesor' },
      { usuarioId: profLaura.id, institucionId: sanJose.id, rolEnInstitucion: 'profesor' },
      { usuarioId: profVacio.id, institucionId: sanJose.id, rolEnInstitucion: 'profesor' },
      { usuarioId: profCarlos.id, institucionId: santander.id, rolEnInstitucion: 'profesor' },
      { usuarioId: estSantiago.id, institucionId: sanJose.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estValentina.id, institucionId: sanJose.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estMateo.id, institucionId: sanJose.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estCamila.id, institucionId: sanJose.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estLucas.id, institucionId: sanJose.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estIsabella.id, institucionId: sanJose.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estSebastian.id, institucionId: sanJose.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estMaria.id, institucionId: sanJose.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estDiego.id, institucionId: sanJose.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estSofiaT.id, institucionId: sanJose.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estAndres.id, institucionId: sanJose.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estLaura.id, institucionId: sanJose.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estNicolas.id, institucionId: sanJose.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estMariana.id, institucionId: sanJose.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estFelipe.id, institucionId: sanJose.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estSofia.id, institucionId: santander.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estDaniel.id, institucionId: santander.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estPaula.id, institucionId: santander.id, rolEnInstitucion: 'estudiante' },
    ],
  });
  console.log('✅ Vínculos creados.');

  // 6. Creación de datos de Estudiantes
  console.log('👨‍🎓 Creando perfiles de estudiante...');
  const estudiantes = await prisma.estudiante.createMany({
    data: [
      { usuarioId: estSantiago.id, identificacion: '1001', codigoQr: 'QR-SANTIAGO', nombreResponsable: 'Ana Mendoza', telefonoResponsable: '+573001234567' },
      { usuarioId: estValentina.id, identificacion: '1002', codigoQr: 'QR-VALENTINA', nombreResponsable: 'Carlos Rojas', telefonoResponsable: '+573001234568' },
      { usuarioId: estMateo.id, identificacion: '1003', codigoQr: 'QR-MATEO', nombreResponsable: 'Patricia Castro', telefonoResponsable: '+573001234569' },
      { usuarioId: estCamila.id, identificacion: '1004', codigoQr: 'QR-CAMILA', nombreResponsable: 'Roberto Ortiz', telefonoResponsable: '+573001234570' },
      { usuarioId: estLucas.id, identificacion: '1005', codigoQr: 'QR-LUCAS', nombreResponsable: 'Diana Martínez', telefonoResponsable: '+573001234571' },
      { usuarioId: estIsabella.id, identificacion: '1006', codigoQr: 'QR-ISABELLA', nombreResponsable: 'Jorge López', telefonoResponsable: '+573001234572' },
      { usuarioId: estSebastian.id, identificacion: '1007', codigoQr: 'QR-SEBASTIAN', nombreResponsable: 'Marta García', telefonoResponsable: '+573001234573' },
      { usuarioId: estMaria.id, identificacion: '1008', codigoQr: 'QR-MARIA', nombreResponsable: 'Luis Fernández', telefonoResponsable: '+573001234574' },
      { usuarioId: estDiego.id, identificacion: '1009', codigoQr: 'QR-DIEGO', nombreResponsable: 'Sandra Ramírez', telefonoResponsable: '+573001234575' },
      { usuarioId: estSofiaT.id, identificacion: '1010', codigoQr: 'QR-SOFIA-T', nombreResponsable: 'Pedro Torres', telefonoResponsable: '+573001234576' },
      { usuarioId: estAndres.id, identificacion: '1011', codigoQr: 'QR-ANDRES', nombreResponsable: 'Gloria Moreno', telefonoResponsable: '+573001234577' },
      { usuarioId: estLaura.id, identificacion: '1012', codigoQr: 'QR-LAURA', nombreResponsable: 'Miguel Sánchez', telefonoResponsable: '+573001234578' },
      { usuarioId: estNicolas.id, identificacion: '1013', codigoQr: 'QR-NICOLAS', nombreResponsable: 'Carmen Vargas', telefonoResponsable: '+573001234579' },
      { usuarioId: estMariana.id, identificacion: '1014', codigoQr: 'QR-MARIANA', nombreResponsable: 'Ricardo Cruz', telefonoResponsable: '+573001234580' },
      { usuarioId: estFelipe.id, identificacion: '1015', codigoQr: 'QR-FELIPE', nombreResponsable: 'Elena Herrera', telefonoResponsable: '+573001234581' },
      { usuarioId: estSofia.id, identificacion: '2001', codigoQr: 'QR-SOFIA', nombreResponsable: 'Antonio Núñez', telefonoResponsable: '+573002234567' },
      { usuarioId: estDaniel.id, identificacion: '2002', codigoQr: 'QR-DANIEL', nombreResponsable: 'Isabel Ruiz', telefonoResponsable: '+573002234568' },
      { usuarioId: estPaula.id, identificacion: '2003', codigoQr: 'QR-PAULA', nombreResponsable: 'Fernando Méndez', telefonoResponsable: '+573002234569' },
    ],
  });
  console.log(`✅ ${estudiantes.count} perfiles de estudiante creados.`);
  const santiago = (await prisma.estudiante.findUnique({where: {usuarioId: estSantiago.id}}))!;
  const valentina = (await prisma.estudiante.findUnique({where: {usuarioId: estValentina.id}}))!;
  const mateo = (await prisma.estudiante.findUnique({where: {usuarioId: estMateo.id}}))!;
  const camila = (await prisma.estudiante.findUnique({where: {usuarioId: estCamila.id}}))!;
  const lucas = (await prisma.estudiante.findUnique({where: {usuarioId: estLucas.id}}))!;
  const isabella = (await prisma.estudiante.findUnique({where: {usuarioId: estIsabella.id}}))!;
  const sebastian = (await prisma.estudiante.findUnique({where: {usuarioId: estSebastian.id}}))!;
  const maria = (await prisma.estudiante.findUnique({where: {usuarioId: estMaria.id}}))!;
  const diego = (await prisma.estudiante.findUnique({where: {usuarioId: estDiego.id}}))!;
  const sofiaT = (await prisma.estudiante.findUnique({where: {usuarioId: estSofiaT.id}}))!;
  const andres = (await prisma.estudiante.findUnique({where: {usuarioId: estAndres.id}}))!;
  const lauraEst = (await prisma.estudiante.findUnique({where: {usuarioId: estLaura.id}}))!;
  const nicolas = (await prisma.estudiante.findUnique({where: {usuarioId: estNicolas.id}}))!;
  const mariana = (await prisma.estudiante.findUnique({where: {usuarioId: estMariana.id}}))!;
  const felipe = (await prisma.estudiante.findUnique({where: {usuarioId: estFelipe.id}}))!;
  const sofia = (await prisma.estudiante.findUnique({where: {usuarioId: estSofia.id}}))!;
  const daniel = (await prisma.estudiante.findUnique({where: {usuarioId: estDaniel.id}}))!;
  const paula = (await prisma.estudiante.findUnique({where: {usuarioId: estPaula.id}}))!;

  // 7. Creación de Grupos y Materias
  console.log('📚 Creando grupos y materias...');
  const grupo10A = await prisma.grupo.create({ data: { nombre: 'Décimo A', grado: '10', seccion: 'A', periodoId: periodoSanJose.id, institucionId: sanJose.id } });
  const grupo11B = await prisma.grupo.create({ data: { nombre: 'Once B', grado: '11', seccion: 'B', periodoId: periodoSanJose.id, institucionId: sanJose.id } });
  const grupo9C = await prisma.grupo.create({ data: { nombre: 'Noveno C', grado: '9', seccion: 'C', periodoId: periodoSanJose.id, institucionId: sanJose.id } });
  const grupo6_1 = await prisma.grupo.create({ data: { nombre: 'Sexto Uno', grado: '6', seccion: '1', periodoId: periodoSantander.id, institucionId: santander.id } });

  // Materias San José (más variedad)
  const mat = await prisma.materia.create({ data: { nombre: 'Matemáticas', codigo: 'MAT-001', institucionId: sanJose.id } });
  const fis = await prisma.materia.create({ data: { nombre: 'Física', codigo: 'FIS-001', institucionId: sanJose.id } });
  const qui = await prisma.materia.create({ data: { nombre: 'Química', codigo: 'QUI-001', institucionId: sanJose.id } });
  const bio = await prisma.materia.create({ data: { nombre: 'Biología', codigo: 'BIO-001', institucionId: sanJose.id } });
  const espSJ = await prisma.materia.create({ data: { nombre: 'Español', codigo: 'ESP-001', institucionId: sanJose.id } });
  const ingSJ = await prisma.materia.create({ data: { nombre: 'Inglés', codigo: 'ING-001', institucionId: sanJose.id } });
  const socSJ = await prisma.materia.create({ data: { nombre: 'Ciencias Sociales', codigo: 'SOC-001', institucionId: sanJose.id } });
  const artSJ = await prisma.materia.create({ data: { nombre: 'Educación Artística', codigo: 'ART-001', institucionId: sanJose.id } });
  const edFisSJ = await prisma.materia.create({ data: { nombre: 'Educación Física', codigo: 'EDF-001', institucionId: sanJose.id } });
  const infSJ = await prisma.materia.create({ data: { nombre: 'Informática', codigo: 'INF-001', institucionId: sanJose.id } });
  
  // Materias Santander
  const esp = await prisma.materia.create({ data: { nombre: 'Español', codigo: 'ESP-S001', institucionId: santander.id } });
  const ing = await prisma.materia.create({ data: { nombre: 'Inglés', codigo: 'ING-S001', institucionId: santander.id } });
  const matS = await prisma.materia.create({ data: { nombre: 'Matemáticas', codigo: 'MAT-S001', institucionId: santander.id } });
  console.log('✅ Grupos y materias creados.');

  // 8. Asignación de Estudiantes a Grupos
  console.log('🔗 Asignando estudiantes a grupos...');
  await prisma.estudianteGrupo.createMany({
    data: [
      // Grupo 10-A (6 estudiantes)
      { estudianteId: santiago.id, grupoId: grupo10A.id },
      { estudianteId: valentina.id, grupoId: grupo10A.id },
      { estudianteId: lucas.id, grupoId: grupo10A.id },
      { estudianteId: isabella.id, grupoId: grupo10A.id },
      { estudianteId: sebastian.id, grupoId: grupo10A.id },
      { estudianteId: maria.id, grupoId: grupo10A.id },
      // Grupo 11-B (5 estudiantes)
      { estudianteId: mateo.id, grupoId: grupo11B.id },
      { estudianteId: camila.id, grupoId: grupo11B.id },
      { estudianteId: diego.id, grupoId: grupo11B.id },
      { estudianteId: sofiaT.id, grupoId: grupo11B.id },
      { estudianteId: andres.id, grupoId: grupo11B.id },
      // Grupo 9-C (4 estudiantes)
      { estudianteId: lauraEst.id, grupoId: grupo9C.id },
      { estudianteId: nicolas.id, grupoId: grupo9C.id },
      { estudianteId: mariana.id, grupoId: grupo9C.id },
      { estudianteId: felipe.id, grupoId: grupo9C.id },
      // Grupo 6-1 Santander (3 estudiantes)
      { estudianteId: sofia.id, grupoId: grupo6_1.id },
      { estudianteId: daniel.id, grupoId: grupo6_1.id },
      { estudianteId: paula.id, grupoId: grupo6_1.id },
    ],
  });
  console.log('✅ Estudiantes asignados.');

  // 9. Creación de Horarios
  console.log('📅 Creando horarios...');
  const horariosData = await prisma.horario.createMany({
    data: [
      // ========== GRUPO 10-A (San José) - Horario Completo Semana ==========
      // LUNES
      { diaSemana: 1, horaInicio: '07:00', horaFin: '08:00', materiaId: mat.id, profesorId: profJuan.id, grupoId: grupo10A.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 1, horaInicio: '08:00', horaFin: '09:00', materiaId: fis.id, profesorId: profLaura.id, grupoId: grupo10A.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 1, horaInicio: '09:00', horaFin: '10:00', materiaId: espSJ.id, profesorId: profJuan.id, grupoId: grupo10A.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 1, horaInicio: '10:30', horaFin: '11:30', materiaId: ingSJ.id, profesorId: profLaura.id, grupoId: grupo10A.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 1, horaInicio: '11:30', horaFin: '12:30', materiaId: socSJ.id, profesorId: profJuan.id, grupoId: grupo10A.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      
      // MARTES
      { diaSemana: 2, horaInicio: '07:00', horaFin: '08:00', materiaId: qui.id, profesorId: profLaura.id, grupoId: grupo10A.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 2, horaInicio: '08:00', horaFin: '09:00', materiaId: bio.id, profesorId: profLaura.id, grupoId: grupo10A.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 2, horaInicio: '09:00', horaFin: '10:00', materiaId: mat.id, profesorId: profJuan.id, grupoId: grupo10A.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 2, horaInicio: '10:30', horaFin: '11:30', materiaId: infSJ.id, profesorId: profJuan.id, grupoId: grupo10A.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 2, horaInicio: '11:30', horaFin: '12:30', materiaId: artSJ.id, profesorId: profLaura.id, grupoId: grupo10A.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      
      // MIÉRCOLES
      { diaSemana: 3, horaInicio: '07:00', horaFin: '08:00', materiaId: mat.id, profesorId: profJuan.id, grupoId: grupo10A.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 3, horaInicio: '08:00', horaFin: '09:00', materiaId: fis.id, profesorId: profLaura.id, grupoId: grupo10A.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 3, horaInicio: '09:00', horaFin: '10:00', materiaId: ingSJ.id, profesorId: profLaura.id, grupoId: grupo10A.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 3, horaInicio: '10:30', horaFin: '11:30', materiaId: edFisSJ.id, profesorId: profJuan.id, grupoId: grupo10A.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 3, horaInicio: '11:30', horaFin: '12:30', materiaId: espSJ.id, profesorId: profJuan.id, grupoId: grupo10A.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      
      // JUEVES
      { diaSemana: 4, horaInicio: '07:00', horaFin: '08:00', materiaId: qui.id, profesorId: profLaura.id, grupoId: grupo10A.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 4, horaInicio: '08:00', horaFin: '09:00', materiaId: mat.id, profesorId: profJuan.id, grupoId: grupo10A.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 4, horaInicio: '09:00', horaFin: '10:00', materiaId: socSJ.id, profesorId: profJuan.id, grupoId: grupo10A.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 4, horaInicio: '10:30', horaFin: '11:30', materiaId: bio.id, profesorId: profLaura.id, grupoId: grupo10A.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 4, horaInicio: '11:30', horaFin: '12:30', materiaId: infSJ.id, profesorId: profJuan.id, grupoId: grupo10A.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      
      // VIERNES
      { diaSemana: 5, horaInicio: '07:00', horaFin: '08:00', materiaId: fis.id, profesorId: profLaura.id, grupoId: grupo10A.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 5, horaInicio: '08:00', horaFin: '09:00', materiaId: ingSJ.id, profesorId: profLaura.id, grupoId: grupo10A.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 5, horaInicio: '09:00', horaFin: '10:00', materiaId: espSJ.id, profesorId: profJuan.id, grupoId: grupo10A.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 5, horaInicio: '10:30', horaFin: '11:30', materiaId: artSJ.id, profesorId: profLaura.id, grupoId: grupo10A.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 5, horaInicio: '11:30', horaFin: '12:30', materiaId: edFisSJ.id, profesorId: profJuan.id, grupoId: grupo10A.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },

      // ========== GRUPO 11-B (San José) - Horario Completo Semana ==========
      // LUNES
      { diaSemana: 1, horaInicio: '07:00', horaFin: '08:00', materiaId: qui.id, profesorId: profLaura.id, grupoId: grupo11B.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 1, horaInicio: '08:00', horaFin: '09:00', materiaId: mat.id, profesorId: profJuan.id, grupoId: grupo11B.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 1, horaInicio: '09:00', horaFin: '10:00', materiaId: fis.id, profesorId: profLaura.id, grupoId: grupo11B.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 1, horaInicio: '10:30', horaFin: '11:30', materiaId: espSJ.id, profesorId: profJuan.id, grupoId: grupo11B.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      
      // MARTES
      { diaSemana: 2, horaInicio: '07:00', horaFin: '08:00', materiaId: bio.id, profesorId: profLaura.id, grupoId: grupo11B.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 2, horaInicio: '09:00', horaFin: '10:00', materiaId: ingSJ.id, profesorId: profLaura.id, grupoId: grupo11B.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 2, horaInicio: '10:30', horaFin: '11:30', materiaId: socSJ.id, profesorId: profJuan.id, grupoId: grupo11B.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      
      // MIÉRCOLES
      { diaSemana: 3, horaInicio: '07:00', horaFin: '08:00', materiaId: mat.id, profesorId: profJuan.id, grupoId: grupo11B.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 3, horaInicio: '08:00', horaFin: '09:00', materiaId: qui.id, profesorId: profLaura.id, grupoId: grupo11B.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 3, horaInicio: '09:00', horaFin: '10:00', materiaId: infSJ.id, profesorId: profJuan.id, grupoId: grupo11B.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      
      // JUEVES
      { diaSemana: 4, horaInicio: '08:00', horaFin: '09:00', materiaId: fis.id, profesorId: profLaura.id, grupoId: grupo11B.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 4, horaInicio: '09:00', horaFin: '10:00', materiaId: edFisSJ.id, profesorId: profJuan.id, grupoId: grupo11B.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 4, horaInicio: '10:30', horaFin: '11:30', materiaId: artSJ.id, profesorId: profLaura.id, grupoId: grupo11B.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      
      // VIERNES
      { diaSemana: 5, horaInicio: '07:00', horaFin: '08:00', materiaId: ingSJ.id, profesorId: profLaura.id, grupoId: grupo11B.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 5, horaInicio: '08:00', horaFin: '09:00', materiaId: espSJ.id, profesorId: profJuan.id, grupoId: grupo11B.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 5, horaInicio: '09:00', horaFin: '10:00', materiaId: bio.id, profesorId: profLaura.id, grupoId: grupo11B.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },

      // ========== GRUPO 9-C (San José) - Horario Completo Semana ==========
      // LUNES
      { diaSemana: 1, horaInicio: '07:00', horaFin: '08:00', materiaId: mat.id, profesorId: profJuan.id, grupoId: grupo9C.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 1, horaInicio: '08:00', horaFin: '09:00', materiaId: espSJ.id, profesorId: profJuan.id, grupoId: grupo9C.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 1, horaInicio: '09:00', horaFin: '10:00', materiaId: bio.id, profesorId: profLaura.id, grupoId: grupo9C.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      
      // MARTES
      { diaSemana: 2, horaInicio: '07:00', horaFin: '08:00', materiaId: ingSJ.id, profesorId: profLaura.id, grupoId: grupo9C.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 2, horaInicio: '08:00', horaFin: '09:00', materiaId: socSJ.id, profesorId: profJuan.id, grupoId: grupo9C.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 2, horaInicio: '10:30', horaFin: '11:30', materiaId: artSJ.id, profesorId: profLaura.id, grupoId: grupo9C.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      
      // MIÉRCOLES
      { diaSemana: 3, horaInicio: '07:00', horaFin: '08:00', materiaId: mat.id, profesorId: profJuan.id, grupoId: grupo9C.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 3, horaInicio: '09:00', horaFin: '10:00', materiaId: infSJ.id, profesorId: profJuan.id, grupoId: grupo9C.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      
      // JUEVES
      { diaSemana: 4, horaInicio: '08:00', horaFin: '09:00', materiaId: edFisSJ.id, profesorId: profJuan.id, grupoId: grupo9C.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 4, horaInicio: '09:00', horaFin: '10:00', materiaId: ingSJ.id, profesorId: profLaura.id, grupoId: grupo9C.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      
      // VIERNES
      { diaSemana: 5, horaInicio: '07:00', horaFin: '08:00', materiaId: espSJ.id, profesorId: profJuan.id, grupoId: grupo9C.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 5, horaInicio: '08:00', horaFin: '09:00', materiaId: bio.id, profesorId: profLaura.id, grupoId: grupo9C.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },

      // ========== GRUPO 6-1 (Santander) - Horario Completo Semana ==========
      // LUNES
      { diaSemana: 1, horaInicio: '07:00', horaFin: '08:00', materiaId: matS.id, profesorId: profCarlos.id, grupoId: grupo6_1.id, periodoId: periodoSantander.id, institucionId: santander.id },
      { diaSemana: 1, horaInicio: '08:00', horaFin: '09:00', materiaId: esp.id, profesorId: profCarlos.id, grupoId: grupo6_1.id, periodoId: periodoSantander.id, institucionId: santander.id },
      
      // MARTES
      { diaSemana: 2, horaInicio: '09:00', horaFin: '10:00', materiaId: ing.id, profesorId: profCarlos.id, grupoId: grupo6_1.id, periodoId: periodoSantander.id, institucionId: santander.id },
      { diaSemana: 2, horaInicio: '10:30', horaFin: '11:30', materiaId: matS.id, profesorId: profCarlos.id, grupoId: grupo6_1.id, periodoId: periodoSantander.id, institucionId: santander.id },
      
      // MIÉRCOLES
      { diaSemana: 3, horaInicio: '07:00', horaFin: '08:00', materiaId: esp.id, profesorId: profCarlos.id, grupoId: grupo6_1.id, periodoId: periodoSantander.id, institucionId: santander.id },
      { diaSemana: 3, horaInicio: '08:00', horaFin: '09:00', materiaId: ing.id, profesorId: profCarlos.id, grupoId: grupo6_1.id, periodoId: periodoSantander.id, institucionId: santander.id },
      
      // JUEVES
      { diaSemana: 4, horaInicio: '09:00', horaFin: '10:00', materiaId: matS.id, profesorId: profCarlos.id, grupoId: grupo6_1.id, periodoId: periodoSantander.id, institucionId: santander.id },
      { diaSemana: 4, horaInicio: '11:00', horaFin: '12:00', materiaId: esp.id, profesorId: profCarlos.id, grupoId: grupo6_1.id, periodoId: periodoSantander.id, institucionId: santander.id },
      
      // VIERNES
      { diaSemana: 5, horaInicio: '08:00', horaFin: '09:00', materiaId: ing.id, profesorId: profCarlos.id, grupoId: grupo6_1.id, periodoId: periodoSantander.id, institucionId: santander.id },
      { diaSemana: 5, horaInicio: '11:00', horaFin: '12:00', materiaId: matS.id, profesorId: profCarlos.id, grupoId: grupo6_1.id, periodoId: periodoSantander.id, institucionId: santander.id },
    ],
  });
  console.log(`✅ ${horariosData.count} horarios creados.`);

  // 10. Obtener algunos horarios para crear registros de asistencia
  console.log('📋 Creando registros de asistencia históricos...');
  const horarios = await prisma.horario.findMany({
    where: { institucionId: sanJose.id },
    take: 10,
  });

  // Crear asistencias de días pasados (hace 3 días y hace 1 día)
  const hace3Dias = new Date();
  hace3Dias.setDate(hace3Dias.getDate() - 3);
  hace3Dias.setHours(0, 0, 0, 0);

  const hace1Dia = new Date();
  hace1Dia.setDate(hace1Dia.getDate() - 1);
  hace1Dia.setHours(0, 0, 0, 0);

  const asistenciasHistoricas = [];
  
  // Para el primer horario (10-A Matemáticas Lunes 7am)
  if (horarios[0]) {
    // Hace 3 días - algunos presentes, algunos ausentes
    asistenciasHistoricas.push(
      { fecha: hace3Dias, estado: 'PRESENTE', horarioId: horarios[0].id, estudianteId: santiago.id, profesorId: profJuan.id, institucionId: sanJose.id, tipoRegistro: 'QR' },
      { fecha: hace3Dias, estado: 'PRESENTE', horarioId: horarios[0].id, estudianteId: valentina.id, profesorId: profJuan.id, institucionId: sanJose.id, tipoRegistro: 'QR' },
      { fecha: hace3Dias, estado: 'TARDANZA', horarioId: horarios[0].id, estudianteId: lucas.id, profesorId: profJuan.id, institucionId: sanJose.id, tipoRegistro: 'MANUAL' },
      { fecha: hace3Dias, estado: 'AUSENTE', horarioId: horarios[0].id, estudianteId: isabella.id, profesorId: profJuan.id, institucionId: sanJose.id, tipoRegistro: 'MANUAL' },
      { fecha: hace3Dias, estado: 'PRESENTE', horarioId: horarios[0].id, estudianteId: sebastian.id, profesorId: profJuan.id, institucionId: sanJose.id, tipoRegistro: 'QR' },
      { fecha: hace3Dias, estado: 'PRESENTE', horarioId: horarios[0].id, estudianteId: maria.id, profesorId: profJuan.id, institucionId: sanJose.id, tipoRegistro: 'QR' },
      
      // Hace 1 día - diferentes asistencias
      { fecha: hace1Dia, estado: 'PRESENTE', horarioId: horarios[0].id, estudianteId: santiago.id, profesorId: profJuan.id, institucionId: sanJose.id, tipoRegistro: 'QR' },
      { fecha: hace1Dia, estado: 'AUSENTE', horarioId: horarios[0].id, estudianteId: valentina.id, profesorId: profJuan.id, institucionId: sanJose.id, tipoRegistro: 'MANUAL' },
      { fecha: hace1Dia, estado: 'PRESENTE', horarioId: horarios[0].id, estudianteId: lucas.id, profesorId: profJuan.id, institucionId: sanJose.id, tipoRegistro: 'QR' },
      { fecha: hace1Dia, estado: 'JUSTIFICADO', horarioId: horarios[0].id, estudianteId: isabella.id, profesorId: profJuan.id, institucionId: sanJose.id, tipoRegistro: 'MANUAL', observaciones: 'Excusa médica presentada' },
      { fecha: hace1Dia, estado: 'PRESENTE', horarioId: horarios[0].id, estudianteId: sebastian.id, profesorId: profJuan.id, institucionId: sanJose.id, tipoRegistro: 'QR' },
      { fecha: hace1Dia, estado: 'TARDANZA', horarioId: horarios[0].id, estudianteId: maria.id, profesorId: profJuan.id, institucionId: sanJose.id, tipoRegistro: 'MANUAL' },
    );
  }

  // Para el segundo horario (10-A Física Lunes 8am)
  if (horarios[1]) {
    asistenciasHistoricas.push(
      { fecha: hace3Dias, estado: 'PRESENTE', horarioId: horarios[1].id, estudianteId: santiago.id, profesorId: profLaura.id, institucionId: sanJose.id, tipoRegistro: 'QR' },
      { fecha: hace3Dias, estado: 'PRESENTE', horarioId: horarios[1].id, estudianteId: valentina.id, profesorId: profLaura.id, institucionId: sanJose.id, tipoRegistro: 'QR' },
      { fecha: hace3Dias, estado: 'PRESENTE', horarioId: horarios[1].id, estudianteId: lucas.id, profesorId: profLaura.id, institucionId: sanJose.id, tipoRegistro: 'QR' },
      { fecha: hace3Dias, estado: 'AUSENTE', horarioId: horarios[1].id, estudianteId: isabella.id, profesorId: profLaura.id, institucionId: sanJose.id, tipoRegistro: 'MANUAL' },
      { fecha: hace3Dias, estado: 'PRESENTE', horarioId: horarios[1].id, estudianteId: sebastian.id, profesorId: profLaura.id, institucionId: sanJose.id, tipoRegistro: 'QR' },
      { fecha: hace3Dias, estado: 'PRESENTE', horarioId: horarios[1].id, estudianteId: maria.id, profesorId: profLaura.id, institucionId: sanJose.id, tipoRegistro: 'QR' },
    );
  }

  if (asistenciasHistoricas.length > 0) {
    await prisma.asistencia.createMany({ data: asistenciasHistoricas });
    console.log(`✅ ${asistenciasHistoricas.length} registros de asistencia históricos creados.`);
  }

  console.log('\n🎉 Seed maestro completado exitosamente!');
}

main()
  .catch((e) => {
    console.error('❌ Error durante el seed:', e);
    throw e;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
