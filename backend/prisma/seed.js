// backend/prisma/seed.ts

const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

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
      // Estudiantes Santander
      { email: 'sofia.nunez@santander.edu', passwordHash: hash('Est123!'), nombres: 'Sofía', apellidos: 'Núñez', rol: 'estudiante', activo: true },
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
  const estSofia = await findUser('sofia.nunez@santander.edu');

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
      { usuarioId: estSofia.id, institucionId: santander.id, rolEnInstitucion: 'estudiante' },
    ],
  });
  console.log('✅ Vínculos creados.');

  // 6. Creación de datos de Estudiantes
  console.log('👨‍🎓 Creando perfiles de estudiante...');
  const estudiantes = await prisma.estudiante.createMany({
    data: [
      { usuarioId: estSantiago.id, identificacion: '1001', codigoQr: 'QR-SANTIAGO' },
      { usuarioId: estValentina.id, identificacion: '1002', codigoQr: 'QR-VALENTINA' },
      { usuarioId: estMateo.id, identificacion: '1003', codigoQr: 'QR-MATEO' },
      { usuarioId: estCamila.id, identificacion: '1004', codigoQr: 'QR-CAMILA' },
      { usuarioId: estSofia.id, identificacion: '2001', codigoQr: 'QR-SOFIA' },
    ],
  });
  console.log(`✅ ${estudiantes.count} perfiles de estudiante creados.`);
  const santiago = (await prisma.estudiante.findUnique({where: {usuarioId: estSantiago.id}}))!;
  const valentina = (await prisma.estudiante.findUnique({where: {usuarioId: estValentina.id}}))!;
  const mateo = (await prisma.estudiante.findUnique({where: {usuarioId: estMateo.id}}))!;
  const camila = (await prisma.estudiante.findUnique({where: {usuarioId: estCamila.id}}))!;
  const sofia = (await prisma.estudiante.findUnique({where: {usuarioId: estSofia.id}}))!;

  // 7. Creación de Grupos y Materias
  console.log('📚 Creando grupos y materias...');
  const grupo10A = await prisma.grupo.create({ data: { nombre: 'Décimo A', grado: '10', seccion: 'A', periodoId: periodoSanJose.id, institucionId: sanJose.id } });
  const grupo11B = await prisma.grupo.create({ data: { nombre: 'Once B', grado: '11', seccion: 'B', periodoId: periodoSanJose.id, institucionId: sanJose.id } });
  const grupo6_1 = await prisma.grupo.create({ data: { nombre: 'Sexto Uno', grado: '6', seccion: '1', periodoId: periodoSantander.id, institucionId: santander.id } });

  const mat = await prisma.materia.create({ data: { nombre: 'Matemáticas', institucionId: sanJose.id } });
  const fis = await prisma.materia.create({ data: { nombre: 'Física', institucionId: sanJose.id } });
  const qui = await prisma.materia.create({ data: { nombre: 'Química', institucionId: sanJose.id } });
  const esp = await prisma.materia.create({ data: { nombre: 'Español', institucionId: santander.id } });
  const ing = await prisma.materia.create({ data: { nombre: 'Inglés', institucionId: santander.id } });
  console.log('✅ Grupos y materias creados.');

  // 8. Asignación de Estudiantes a Grupos
  console.log('🔗 Asignando estudiantes a grupos...');
  await prisma.estudianteGrupo.createMany({
    data: [
      { estudianteId: santiago.id, grupoId: grupo10A.id },
      { estudianteId: valentina.id, grupoId: grupo10A.id },
      { estudianteId: mateo.id, grupoId: grupo11B.id },
      { estudianteId: camila.id, grupoId: grupo11B.id },
      { estudianteId: sofia.id, grupoId: grupo6_1.id },
    ],
  });
  console.log('✅ Estudiantes asignados.');

  // 9. Creación de Horarios
  console.log('📅 Creando horarios...');
  await prisma.horario.createMany({
    data: [
      // Horario San José - Grupo 10-A
      { diaSemana: 1, horaInicio: '07:00', horaFin: '08:00', materiaId: mat.id, profesorId: profJuan.id, grupoId: grupo10A.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 1, horaInicio: '08:00', horaFin: '09:00', materiaId: fis.id, profesorId: profLaura.id, grupoId: grupo10A.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      { diaSemana: 3, horaInicio: '10:00', horaFin: '11:00', materiaId: mat.id, profesorId: profJuan.id, grupoId: grupo10A.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      // Horario San José - Grupo 11-B
      { diaSemana: 2, horaInicio: '09:00', horaFin: '10:00', materiaId: qui.id, profesorId: profLaura.id, grupoId: grupo11B.id, periodoId: periodoSanJose.id, institucionId: sanJose.id },
      // Horario Santander - Grupo 6-1
      { diaSemana: 4, horaInicio: '11:00', horaFin: '12:00', materiaId: esp.id, profesorId: profCarlos.id, grupoId: grupo6_1.id, periodoId: periodoSantander.id, institucionId: santander.id },
      { diaSemana: 5, horaInicio: '11:00', horaFin: '12:00', materiaId: ing.id, profesorId: profCarlos.id, grupoId: grupo6_1.id, periodoId: periodoSantander.id, institucionId: santander.id },
    ],
  });
  console.log('✅ Horarios creados.');

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
