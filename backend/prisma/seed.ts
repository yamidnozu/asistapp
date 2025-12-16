// backend/prisma/seed.ts
// Seed maestro completo para AsistApp - Secundaria con horarios perfectamente distribuidos
// Última actualización: Diciembre 2025

const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

// ============================================================================
// CONFIGURACIÓN DE MATERIAS DE SECUNDARIA
// ============================================================================
interface MateriaConfig {
  nombre: string;
  codigo: string;
  horasSemana: number; // Horas semanales requeridas
}

const MATERIAS_SECUNDARIA: MateriaConfig[] = [
  { nombre: 'Matemáticas', codigo: 'MAT', horasSemana: 5 },
  { nombre: 'Lengua Castellana', codigo: 'ESP', horasSemana: 4 },
  { nombre: 'Inglés', codigo: 'ING', horasSemana: 4 },
  { nombre: 'Ciencias Naturales', codigo: 'NAT', horasSemana: 4 },
  { nombre: 'Ciencias Sociales', codigo: 'SOC', horasSemana: 3 },
  { nombre: 'Educación Física', codigo: 'EFI', horasSemana: 2 },
  { nombre: 'Ética y Valores', codigo: 'ETI', horasSemana: 1 },
  { nombre: 'Educación Artística', codigo: 'ART', horasSemana: 2 },
  { nombre: 'Tecnología e Informática', codigo: 'TEC', horasSemana: 2 },
  { nombre: 'Educación Religiosa', codigo: 'REL', horasSemana: 1 },
  { nombre: 'Filosofía', codigo: 'FIL', horasSemana: 2 }, // Solo para 10° y 11°
];

// Total: 30 horas semanales (6 horas × 5 días)

// ============================================================================
// CONFIGURACIÓN DE BLOQUES HORARIOS
// ============================================================================
interface BloqueHorario {
  inicio: string;
  fin: string;
}

const BLOQUES_HORARIOS: BloqueHorario[] = [
  { inicio: '07:00', fin: '08:00' }, // Bloque 1
  { inicio: '08:00', fin: '09:00' }, // Bloque 2
  { inicio: '09:00', fin: '10:00' }, // Bloque 3
  // DESCANSO 10:00 - 10:30
  { inicio: '10:30', fin: '11:30' }, // Bloque 4
  { inicio: '11:30', fin: '12:30' }, // Bloque 5
  // ALMUERZO 12:30 - 14:00
  { inicio: '14:00', fin: '15:00' }, // Bloque 6
];

const DIAS_SEMANA = [1, 2, 3, 4, 5]; // Lunes a Viernes

// ============================================================================
// GRADOS DE SECUNDARIA
// ============================================================================
const GRADOS_SECUNDARIA = [
  { nombre: 'Sexto', grado: '6' },
  { nombre: 'Séptimo', grado: '7' },
  { nombre: 'Octavo', grado: '8' },
  { nombre: 'Noveno', grado: '9' },
  { nombre: 'Décimo', grado: '10' },
  { nombre: 'Once', grado: '11' },
];

const SECCIONES = ['A', 'B'];

// ============================================================================
// ALGORITMO DE DISTRIBUCIÓN DE HORARIOS
// ============================================================================

interface SlotOcupado {
  profesorId: string;
  grupoId: string;
  materiaId: string;
}

interface AsignacionProfesor {
  profesorId: string;
  materiaIds: string[];
}

interface HorarioParaCrear {
  grupoId: string;
  materiaId: string;
  profesorId: string;
  diaSemana: number;
  horaInicio: string;
  horaFin: string;
}

class GeneradorHorarios {
  private ocupacionGlobal: Map<string, SlotOcupado[]> = new Map(); // Clave: "dia-bloque"
  private horasAsignadasPorGrupoMateria: Map<string, number> = new Map(); // Clave: "grupoId-materiaId"
  private horasAsignadasPorGrupoMateriaDia: Map<string, number> = new Map(); // Clave: "grupoId-materiaId-dia"
  private diasMateriaGrupo: Map<string, Set<number>> = new Map(); // Clave: "grupoId-materiaId" -> set de días
  private horariosGenerados: HorarioParaCrear[] = [];

  constructor(
    private grupos: any[],
    private materias: any[],
    private profesoresPorMateria: Map<string, string[]>, // materiaId -> [profesorId1, profesorId2]
    private horasRequeridas: Map<string, number>, // materiaId -> horas semanales
  ) { }

  private getSlotKey(dia: number, bloqueIdx: number): string {
    return `${dia}-${bloqueIdx}`;
  }

  private getGrupoMateriaKey(grupoId: string, materiaId: string): string {
    return `${grupoId}-${materiaId}`;
  }

  private getGrupoMateriaDiaKey(grupoId: string, materiaId: string, dia: number): string {
    return `${grupoId}-${materiaId}-${dia}`;
  }

  private esSlotDisponibleParaProfesor(dia: number, bloqueIdx: number, profesorId: string): boolean {
    const slotKey = this.getSlotKey(dia, bloqueIdx);
    const ocupados = this.ocupacionGlobal.get(slotKey) || [];
    return !ocupados.some(o => o.profesorId === profesorId);
  }

  private esSlotDisponibleParaGrupo(dia: number, bloqueIdx: number, grupoId: string): boolean {
    const slotKey = this.getSlotKey(dia, bloqueIdx);
    const ocupados = this.ocupacionGlobal.get(slotKey) || [];
    return !ocupados.some(o => o.grupoId === grupoId);
  }

  private puedeAsignarMasHorasMateria(grupoId: string, materiaId: string, dia: number): boolean {
    // Verificar límite semanal
    const claveGM = this.getGrupoMateriaKey(grupoId, materiaId);
    const horasActuales = this.horasAsignadasPorGrupoMateria.get(claveGM) || 0;
    const horasRequeridas = this.horasRequeridas.get(materiaId) || 0;
    if (horasActuales >= horasRequeridas) return false;

    // Verificar máximo 2 horas por día (bloque de 2 horas máximo)
    const claveGMD = this.getGrupoMateriaDiaKey(grupoId, materiaId, dia);
    const horasDia = this.horasAsignadasPorGrupoMateriaDia.get(claveGMD) || 0;
    if (horasDia >= 2) return false;

    // Verificar que la materia se distribuya en máximo 3 días a la semana
    // (cada materia puede repetirse hasta 2 veces, así que repartir en varios días)
    const diasKey = this.getGrupoMateriaKey(grupoId, materiaId);
    const diasUsados = this.diasMateriaGrupo.get(diasKey) || new Set();

    // Si ya está en 3 días y este no es uno de ellos, no asignar más
    if (diasUsados.size >= 3 && !diasUsados.has(dia)) return false;

    return true;
  }

  private registrarAsignacion(
    grupoId: string,
    materiaId: string,
    profesorId: string,
    dia: number,
    bloqueIdx: number,
  ): void {
    const slotKey = this.getSlotKey(dia, bloqueIdx);
    if (!this.ocupacionGlobal.has(slotKey)) {
      this.ocupacionGlobal.set(slotKey, []);
    }
    this.ocupacionGlobal.get(slotKey)!.push({ profesorId, grupoId, materiaId });

    // Incrementar horas semanales
    const claveGM = this.getGrupoMateriaKey(grupoId, materiaId);
    this.horasAsignadasPorGrupoMateria.set(
      claveGM,
      (this.horasAsignadasPorGrupoMateria.get(claveGM) || 0) + 1
    );

    // Incrementar horas por día
    const claveGMD = this.getGrupoMateriaDiaKey(grupoId, materiaId, dia);
    this.horasAsignadasPorGrupoMateriaDia.set(
      claveGMD,
      (this.horasAsignadasPorGrupoMateriaDia.get(claveGMD) || 0) + 1
    );

    // Registrar día usado
    if (!this.diasMateriaGrupo.has(claveGM)) {
      this.diasMateriaGrupo.set(claveGM, new Set());
    }
    this.diasMateriaGrupo.get(claveGM)!.add(dia);
  }

  private buscarProfesorDisponible(materiaId: string, dia: number, bloqueIdx: number): string | null {
    const profesores = this.profesoresPorMateria.get(materiaId) || [];
    for (const profId of profesores) {
      if (this.esSlotDisponibleParaProfesor(dia, bloqueIdx, profId)) {
        return profId;
      }
    }
    return null;
  }

  generar(): HorarioParaCrear[] {
    console.log('\n📅 Generando horarios optimizados...');

    // Para cada grupo, asignar todas las materias con sus horas requeridas
    for (const grupo of this.grupos) {
      console.log(`   📚 Procesando grupo: ${grupo.nombre}`);

      // Crear lista de materias que aplican a este grupo
      // Filosofía solo para 10° y 11°
      const materiasGrupo = this.materias.filter(m => {
        if (m.codigo === 'FIL-101' || m.nombre === 'Filosofía') {
          return grupo.grado === '10' || grupo.grado === '11';
        }
        return true;
      });

      // Ordenar materias por horas requeridas (más horas primero para mejor distribución)
      const materiasOrdenadas = [...materiasGrupo].sort((a, b) => {
        const horasA = this.horasRequeridas.get(a.id) || 0;
        const horasB = this.horasRequeridas.get(b.id) || 0;
        return horasB - horasA;
      });

      // Iterar por días y bloques
      for (const dia of DIAS_SEMANA) {
        for (let bloqueIdx = 0; bloqueIdx < BLOQUES_HORARIOS.length; bloqueIdx++) {
          // Verificar si el slot está disponible para este grupo
          if (!this.esSlotDisponibleParaGrupo(dia, bloqueIdx, grupo.id)) {
            continue;
          }

          // Buscar materia que necesite más horas y pueda asignarse
          for (const materia of materiasOrdenadas) {
            if (!this.puedeAsignarMasHorasMateria(grupo.id, materia.id, dia)) {
              continue;
            }

            // Buscar profesor disponible
            const profesorId = this.buscarProfesorDisponible(materia.id, dia, bloqueIdx);
            if (!profesorId) {
              continue;
            }

            // Asignar horario
            this.registrarAsignacion(grupo.id, materia.id, profesorId, dia, bloqueIdx);

            this.horariosGenerados.push({
              grupoId: grupo.id,
              materiaId: materia.id,
              profesorId: profesorId,
              diaSemana: dia,
              horaInicio: BLOQUES_HORARIOS[bloqueIdx].inicio,
              horaFin: BLOQUES_HORARIOS[bloqueIdx].fin,
            });

            break; // Solo una materia por slot
          }
        }
      }
    }

    console.log(`   ✅ ${this.horariosGenerados.length} horarios generados`);
    return this.horariosGenerados;
  }

  verificarConflictos(): { conflictosProfesor: number; conflictosGrupo: number } {
    let conflictosProfesor = 0;
    let conflictosGrupo = 0;

    for (const [_slotKey, ocupados] of this.ocupacionGlobal) {
      // Verificar conflictos de profesores
      const profesores = ocupados.map(o => o.profesorId);
      const profesoresUnicos = new Set(profesores);
      if (profesoresUnicos.size < profesores.length) {
        conflictosProfesor += profesores.length - profesoresUnicos.size;
      }

      // Verificar conflictos de grupos
      const grupos = ocupados.map(o => o.grupoId);
      const gruposUnicos = new Set(grupos);
      if (gruposUnicos.size < grupos.length) {
        conflictosGrupo += grupos.length - gruposUnicos.size;
      }
    }

    return { conflictosProfesor, conflictosGrupo };
  }
}

// ============================================================================
// FUNCIÓN PRINCIPAL DEL SEED
// ============================================================================
async function main() {
  console.log('🚀 Iniciando seed maestro para AsistApp - Secundaria...');
  console.log('📅 Fecha de ejecución:', new Date().toISOString());

  // ============================================================================
  // 1. LIMPIEZA COMPLETA DE LA BASE DE DATOS
  // ============================================================================
  console.log('\n🧹 Limpiando base de datos...');
  await prisma.notificacionInApp.deleteMany();
  await prisma.dispositivoFCM.deleteMany();
  await prisma.acudienteEstudiante.deleteMany();
  await prisma.logNotificacion.deleteMany();
  await prisma.colaNotificacion.deleteMany();
  await prisma.asistencia.deleteMany();
  await prisma.horario.deleteMany();
  await prisma.estudianteGrupo.deleteMany();
  await prisma.materia.deleteMany();
  await prisma.grupo.deleteMany();
  await prisma.periodoAcademico.deleteMany();
  await prisma.usuarioInstitucion.deleteMany();
  await prisma.refreshToken.deleteMany();
  await prisma.estudiante.deleteMany();
  await prisma.usuario.deleteMany();
  await prisma.configuracion.deleteMany();
  await prisma.institucion.deleteMany();
  console.log('✅ Base de datos limpia.');

  const hashPassword = (password: string) => bcrypt.hashSync(password, 10);
  const TELEFONO_1 = '+573103816321'; // Para pruebas WhatsApp
  const TELEFONO_2 = '+573217645654'; // Alternativo

  // ============================================================================
  // 2. CREAR INSTITUCIONES
  // ============================================================================
  console.log('\n🏫 Creando instituciones...');

  const colegioSanJose = await prisma.institucion.create({
    data: {
      nombre: 'Colegio San José',
      direccion: 'Carrera 12 #45-67, Bogotá',
      telefono: '+573215551234',
      email: 'contacto@sanjose.edu.co',
      activa: true,
    },
  });

  const liceoSantander = await prisma.institucion.create({
    data: {
      nombre: 'Liceo Santander',
      direccion: 'Calle 9 #10-20, Bucaramanga',
      telefono: '+573215551235',
      email: 'contacto@santander.edu.co',
      activa: true,
    },
  });

  const colegioBolivar = await prisma.institucion.create({
    data: {
      nombre: 'Colegio Simón Bolívar',
      direccion: 'Avenida Principal #100-50, Medellín',
      telefono: '+573215551237',
      email: 'contacto@bolivar.edu.co',
      activa: true,
    },
  });

  console.log('✅ 3 instituciones creadas');

  // ============================================================================
  // 3. CONFIGURACIONES DE NOTIFICACIONES
  // ============================================================================
  console.log('\n⚙️ Configurando notificaciones...');

  await prisma.configuracion.createMany({
    data: [
      {
        institucionId: colegioSanJose.id,
        notificacionesActivas: true,
        canalNotificacion: 'WHATSAPP',
        modoNotificacionAsistencia: 'INSTANT',
        horaDisparoNotificacion: '18:00:00',
        notificarAusenciaTotalDiaria: true,
      },
      {
        institucionId: liceoSantander.id,
        notificacionesActivas: true,
        canalNotificacion: 'BOTH',
        modoNotificacionAsistencia: 'MANUAL_ONLY',
        horaDisparoNotificacion: '17:00:00',
        notificarAusenciaTotalDiaria: false,
      },
      {
        institucionId: colegioBolivar.id,
        notificacionesActivas: true,
        canalNotificacion: 'PUSH',
        modoNotificacionAsistencia: 'END_OF_DAY',
        horaDisparoNotificacion: '16:00:00',
        notificarAusenciaTotalDiaria: true,
      },
    ],
  });

  console.log('✅ Configuraciones creadas');

  // ============================================================================
  // 4. CREAR USUARIOS - MANTENER LOS DEL LOGIN
  // ============================================================================
  console.log('\n👥 Creando usuarios del login...');

  // ==================== SUPER ADMIN ====================
  const superAdmin = await prisma.usuario.create({
    data: {
      email: 'superadmin@asistapp.com',
      passwordHash: hashPassword('Admin123!'),
      nombres: 'Super',
      apellidos: 'Administrador',
      identificacion: 'SA-001',
      rol: 'super_admin',
      activo: true,
      telefono: '+573001234567',
    },
  });
  console.log('   ✅ Super Admin: superadmin@asistapp.com / Admin123!');

  // ==================== ADMINS DE INSTITUCIÓN ====================
  const adminSanJose = await prisma.usuario.create({
    data: {
      email: 'admin@sanjose.edu',
      passwordHash: hashPassword('SanJose123!'),
      nombres: 'Administrador',
      apellidos: 'San José',
      identificacion: 'ADM-SJ-001',
      rol: 'admin_institucion',
      activo: true,
      telefono: '+573300123456',
    },
  });
  console.log('   ✅ Admin San José: admin@sanjose.edu / SanJose123!');

  const adminSantander = await prisma.usuario.create({
    data: {
      email: 'admin@santander.edu',
      passwordHash: hashPassword('Santander123!'),
      nombres: 'Administrador',
      apellidos: 'Santander',
      identificacion: 'ADM-ST-001',
      rol: 'admin_institucion',
      activo: true,
      telefono: '+573300123457',
    },
  });
  console.log('   ✅ Admin Santander: admin@santander.edu / Santander123!');

  const adminMultiSede = await prisma.usuario.create({
    data: {
      email: 'multiadmin@asistapp.com',
      passwordHash: hashPassword('Multi123!'),
      nombres: 'Admin',
      apellidos: 'Multi-Sede',
      identificacion: 'ADM-MULTI-001',
      rol: 'admin_institucion',
      activo: true,
      telefono: '+573300123458',
    },
  });
  console.log('   ✅ Admin Multi-Sede: multiadmin@asistapp.com / Multi123!');

  // ============================================================================
  // 5. CREAR PROFESORES
  // ============================================================================
  console.log('\n👨‍🏫 Creando profesores...');

  // Profesores del login (existentes)
  const profesorJuan = await prisma.usuario.create({
    data: {
      email: 'juan.perez@sanjose.edu',
      passwordHash: hashPassword('Prof123!'),
      nombres: 'Juan',
      apellidos: 'Pérez',
      identificacion: 'PROF-JP-001',
      titulo: 'Licenciado en Matemáticas',
      especialidad: 'Matemáticas, Física',
      rol: 'profesor',
      activo: true,
      telefono: '+573101234567',
    },
  });

  const profesorLaura = await prisma.usuario.create({
    data: {
      email: 'laura.gomez@sanjose.edu',
      passwordHash: hashPassword('Prof123!'),
      nombres: 'Laura',
      apellidos: 'Gómez',
      identificacion: 'PROF-LG-001',
      titulo: 'Licenciada en Ciencias Naturales',
      especialidad: 'Ciencias Naturales, Química',
      rol: 'profesor',
      activo: true,
      telefono: '+573101234568',
    },
  });

  const profesorVacio = await prisma.usuario.create({
    data: {
      email: 'vacio.profe@sanjose.edu',
      passwordHash: hashPassword('Prof123!'),
      nombres: 'Pedro',
      apellidos: 'Sin Clases',
      identificacion: 'PROF-SC-001',
      titulo: 'Licenciado en Educación',
      especialidad: 'Sin asignación',
      rol: 'profesor',
      activo: true,
      telefono: '+573101234569',
    },
  });

  const profesorCarlos = await prisma.usuario.create({
    data: {
      email: 'carlos.diaz@santander.edu',
      passwordHash: hashPassword('Prof123!'),
      nombres: 'Carlos',
      apellidos: 'Díaz',
      identificacion: 'PROF-CD-001',
      titulo: 'Licenciado en Ciencias Sociales',
      especialidad: 'Ciencias Sociales, Historia',
      rol: 'profesor',
      activo: true,
      telefono: '+573101234570',
    },
  });

  console.log('   ✅ 4 profesores del login creados');

  // Crear profesores adicionales (2 por cada materia, pueden impartir 2-3 materias)
  // Necesitamos 11 materias × 2 profesores = 22 posiciones, pero con profesores compartidos
  // serán aproximadamente 15-18 profesores únicos

  const profesoresData = [
    { nombres: 'Roberto', apellidos: 'Martínez', materias: ['Matemáticas', 'Tecnología e Informática'] },
    { nombres: 'Claudia', apellidos: 'Rodríguez', materias: ['Lengua Castellana', 'Ética y Valores'] },
    { nombres: 'Andrés', apellidos: 'García', materias: ['Lengua Castellana', 'Educación Religiosa'] },
    { nombres: 'Beatriz', apellidos: 'López', materias: ['Inglés', 'Lengua Castellana'] },
    { nombres: 'Javier', apellidos: 'Hernández', materias: ['Inglés', 'Ética y Valores'] },
    { nombres: 'Diana', apellidos: 'Moreno', materias: ['Ciencias Naturales', 'Educación Religiosa'] },
    { nombres: 'Alberto', apellidos: 'Torres', materias: ['Ciencias Sociales', 'Filosofía', 'Ética y Valores'] },
    { nombres: 'Mónica', apellidos: 'Ramírez', materias: ['Ciencias Sociales', 'Filosofía'] },
    { nombres: 'Rafael', apellidos: 'Sánchez', materias: ['Educación Física', 'Educación Artística'] },
    { nombres: 'Patricia', apellidos: 'Vargas', materias: ['Educación Física', 'Ética y Valores'] },
    { nombres: 'Jorge', apellidos: 'Castro', materias: ['Educación Artística', 'Tecnología e Informática'] },
    { nombres: 'Isabel', apellidos: 'Mendoza', materias: ['Tecnología e Informática', 'Matemáticas'] },
    { nombres: 'Fernando', apellidos: 'Ruiz', materias: ['Matemáticas', 'Física'] },
    { nombres: 'Gloria', apellidos: 'Ortiz', materias: ['Ciencias Naturales', 'Química'] },
    { nombres: 'Miguel', apellidos: 'Pineda', materias: ['Inglés', 'Tecnología e Informática'] },
    { nombres: 'Carmen', apellidos: 'Reyes', materias: ['Educación Religiosa', 'Ética y Valores'] },
  ];

  const profesoresAdicionales: any[] = [];
  for (let i = 0; i < profesoresData.length; i++) {
    const data = profesoresData[i];
    const prof = await prisma.usuario.create({
      data: {
        email: `profesor${i + 5}@sanjose.edu`,
        passwordHash: hashPassword('Prof123!'),
        nombres: data.nombres,
        apellidos: data.apellidos,
        identificacion: `PROF-${String(i + 5).padStart(3, '0')}`,
        titulo: 'Licenciado/a en Educación',
        especialidad: data.materias.join(', '),
        rol: 'profesor',
        activo: true,
        telefono: `+57310${String(1234571 + i).slice(-7)}`,
      },
    });
    profesoresAdicionales.push({ ...prof, materias: data.materias });
  }

  // Todos los profesores (incluyendo los del login con sus materias)
  const todosProfesores = [
    { ...profesorJuan, materias: ['Matemáticas', 'Tecnología e Informática'] },
    { ...profesorLaura, materias: ['Ciencias Naturales'] },
    { ...profesorCarlos, materias: ['Ciencias Sociales', 'Filosofía'] },
    ...profesoresAdicionales,
  ];

  console.log(`   ✅ ${profesoresAdicionales.length} profesores adicionales creados (total: ${todosProfesores.length + 1})`);

  // ============================================================================
  // 6. CREAR ESTUDIANTES DEL LOGIN
  // ============================================================================
  console.log('\n🎓 Creando estudiantes del login...');

  const estudianteSantiago = await prisma.usuario.create({
    data: {
      email: 'santiago.mendoza@sanjose.edu',
      passwordHash: hashPassword('Est123!'),
      nombres: 'Santiago',
      apellidos: 'Mendoza',
      identificacion: 'EST-SM-001',
      rol: 'estudiante',
      activo: true,
    },
  });

  const estudianteMateo = await prisma.usuario.create({
    data: {
      email: 'mateo.castro@sanjose.edu',
      passwordHash: hashPassword('Est123!'),
      nombres: 'Mateo',
      apellidos: 'Castro',
      identificacion: 'EST-MC-001',
      rol: 'estudiante',
      activo: true,
    },
  });

  const estudianteValentina = await prisma.usuario.create({
    data: {
      email: 'valentina.rojas@sanjose.edu',
      passwordHash: hashPassword('Est123!'),
      nombres: 'Valentina',
      apellidos: 'Rojas',
      identificacion: 'EST-VR-001',
      rol: 'estudiante',
      activo: true,
    },
  });

  // Estudiante Andrés (para Carmen López como acudiente)
  const estudianteAndres = await prisma.usuario.create({
    data: {
      email: 'andres.lopez@sanjose.edu',
      passwordHash: hashPassword('Est123!'),
      nombres: 'Andrés',
      apellidos: 'López',
      identificacion: 'EST-AL-001',
      rol: 'estudiante',
      activo: true,
    },
  });

  const estudianteSofia = await prisma.usuario.create({
    data: {
      email: 'sofia.nunez@santander.edu',
      passwordHash: hashPassword('Est123!'),
      nombres: 'Sofía',
      apellidos: 'Núñez',
      identificacion: 'EST-SN-001',
      rol: 'estudiante',
      activo: true,
    },
  });

  console.log('   ✅ 5 estudiantes del login creados');

  // ============================================================================
  // 7. CREAR ACUDIENTES DEL LOGIN
  // ============================================================================
  console.log('\n👨‍👩‍👧 Creando acudientes del login...');

  const acudienteMaria = await prisma.usuario.create({
    data: {
      email: 'maria.mendoza@email.com',
      passwordHash: hashPassword('Acu123!'),
      nombres: 'María',
      apellidos: 'Mendoza',
      identificacion: 'ACU-MM-001',
      rol: 'acudiente',
      activo: true,
      telefono: TELEFONO_1,
    },
  });

  const acudientePatricia = await prisma.usuario.create({
    data: {
      email: 'patricia.castro@email.com',
      passwordHash: hashPassword('Acu123!'),
      nombres: 'Patricia',
      apellidos: 'Castro',
      identificacion: 'ACU-PC-001',
      rol: 'acudiente',
      activo: true,
      telefono: TELEFONO_1,
    },
  });

  const acudienteCarmen = await prisma.usuario.create({
    data: {
      email: 'carmen.lopez@email.com',
      passwordHash: hashPassword('Acu123!'),
      nombres: 'Carmen',
      apellidos: 'López',
      identificacion: 'ACU-CL-001',
      rol: 'acudiente',
      activo: true,
      telefono: TELEFONO_2,
    },
  });

  const acudienteCarlosN = await prisma.usuario.create({
    data: {
      email: 'carlos.nunez@email.com',
      passwordHash: hashPassword('Acu123!'),
      nombres: 'Carlos',
      apellidos: 'Núñez',
      identificacion: 'ACU-CN-001',
      rol: 'acudiente',
      activo: true,
      telefono: TELEFONO_2,
    },
  });

  console.log('   ✅ 4 acudientes del login creados');

  // ============================================================================
  // 8. VINCULAR USUARIOS A INSTITUCIONES
  // ============================================================================
  console.log('\n🔗 Vinculando usuarios a instituciones...');

  await prisma.usuarioInstitucion.createMany({
    data: [
      // Admins
      { usuarioId: adminSanJose.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'admin' },
      { usuarioId: adminSantander.id, institucionId: liceoSantander.id, rolEnInstitucion: 'admin' },
      { usuarioId: adminMultiSede.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'admin' },
      { usuarioId: adminMultiSede.id, institucionId: liceoSantander.id, rolEnInstitucion: 'admin' },
      { usuarioId: adminMultiSede.id, institucionId: colegioBolivar.id, rolEnInstitucion: 'admin' },

      // Profesores (todos a San José excepto profesorCarlos que es de Santander pero también lo añadimos a San José para horarios)
      ...todosProfesores.map(p => ({ usuarioId: p.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'profesor' })),
      { usuarioId: profesorVacio.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'profesor' },
      { usuarioId: profesorCarlos.id, institucionId: liceoSantander.id, rolEnInstitucion: 'profesor' },

      // Estudiantes
      { usuarioId: estudianteSantiago.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estudianteMateo.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estudianteValentina.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estudianteAndres.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estudianteSofia.id, institucionId: liceoSantander.id, rolEnInstitucion: 'estudiante' },

      // Acudientes
      { usuarioId: acudienteMaria.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'acudiente' },
      { usuarioId: acudientePatricia.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'acudiente' },
      { usuarioId: acudienteCarmen.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'acudiente' },
      { usuarioId: acudienteCarlosN.id, institucionId: liceoSantander.id, rolEnInstitucion: 'acudiente' },
    ],
  });

  console.log('✅ Vínculos usuario-institución creados');

  // ============================================================================
  // 9. PERÍODOS ACADÉMICOS
  // ============================================================================
  console.log('\n📚 Creando períodos académicos...');

  const currentYear = new Date().getFullYear();

  const periodoSanJose = await prisma.periodoAcademico.create({
    data: {
      nombre: `Año Lectivo ${currentYear}`,
      fechaInicio: new Date(`${currentYear}-02-01`),
      fechaFin: new Date(`${currentYear}-11-30`),
      activo: true,
      institucionId: colegioSanJose.id,
    },
  });

  const periodoSantander = await prisma.periodoAcademico.create({
    data: {
      nombre: `Año Lectivo ${currentYear}`,
      fechaInicio: new Date(`${currentYear}-02-01`),
      fechaFin: new Date(`${currentYear}-11-30`),
      activo: true,
      institucionId: liceoSantander.id,
    },
  });

  console.log(`✅ 2 períodos académicos creados (${currentYear})`);

  // ============================================================================
  // 10. MATERIAS DE SECUNDARIA
  // ============================================================================
  console.log('\n📖 Creando materias de secundaria...');

  const materiasSanJose: any[] = [];
  const horasRequeridas = new Map<string, number>();

  for (const matConfig of MATERIAS_SECUNDARIA) {
    const materia = await prisma.materia.create({
      data: {
        nombre: matConfig.nombre,
        codigo: `${matConfig.codigo}-101`,
        institucionId: colegioSanJose.id,
      },
    });
    materiasSanJose.push(materia);
    horasRequeridas.set(materia.id, matConfig.horasSemana);
  }

  console.log(`✅ ${materiasSanJose.length} materias de secundaria creadas`);

  // ============================================================================
  // 11. GRUPOS (6° a 11°, secciones A y B = 12 grupos)
  // ============================================================================
  console.log('\n👥 Creando grupos de secundaria...');

  const grupos: any[] = [];

  for (const gradoInfo of GRADOS_SECUNDARIA) {
    for (const seccion of SECCIONES) {
      const grupo = await prisma.grupo.create({
        data: {
          nombre: `${gradoInfo.nombre} ${seccion}`,
          grado: gradoInfo.grado,
          seccion: seccion,
          periodoId: periodoSanJose.id,
          institucionId: colegioSanJose.id,
        },
      });
      grupos.push(grupo);
    }
  }

  console.log(`✅ ${grupos.length} grupos creados (6° a 11°, secciones A y B)`);

  // Grupo para Sofía en Liceo Santander
  const grupoSofia = await prisma.grupo.create({
    data: {
      nombre: 'Sexto 1',
      grado: '6',
      seccion: '1',
      periodoId: periodoSantander.id,
      institucionId: liceoSantander.id,
    },
  });

  // ============================================================================
  // 12. CREAR PERFILES DE ESTUDIANTES
  // ============================================================================
  console.log('\n🎓 Creando perfiles de estudiantes del login...');

  // Encontrar grupos específicos:
  // - Santiago y Valentina: 10-A (hermanos)
  // - Mateo: 11-B
  // - Andrés: 9-A
  const grupo10A = grupos.find(g => g.grado === '10' && g.seccion === 'A');
  const grupo11B = grupos.find(g => g.grado === '11' && g.seccion === 'B');
  const grupo9A = grupos.find(g => g.grado === '9' && g.seccion === 'A');

  const perfilSantiago = await prisma.estudiante.create({
    data: {
      usuarioId: estudianteSantiago.id,
      identificacion: 'TI-1001234567',
      codigoQr: 'QR-SANTIAGO-001',
      nombreResponsable: 'María Mendoza',
      telefonoResponsable: TELEFONO_1,
      telefonoResponsableVerificado: true,
      aceptaNotificaciones: true,
    },
  });

  const perfilMateo = await prisma.estudiante.create({
    data: {
      usuarioId: estudianteMateo.id,
      identificacion: 'TI-1001234568',
      codigoQr: 'QR-MATEO-002',
      nombreResponsable: 'Patricia Castro',
      telefonoResponsable: TELEFONO_1,
      telefonoResponsableVerificado: true,
      aceptaNotificaciones: true,
    },
  });

  const perfilValentina = await prisma.estudiante.create({
    data: {
      usuarioId: estudianteValentina.id,
      identificacion: 'TI-1001234569',
      codigoQr: 'QR-VALENTINA-003',
      nombreResponsable: 'María Mendoza',
      telefonoResponsable: TELEFONO_1,
      telefonoResponsableVerificado: true,
      aceptaNotificaciones: true,
    },
  });

  const perfilAndres = await prisma.estudiante.create({
    data: {
      usuarioId: estudianteAndres.id,
      identificacion: 'TI-1001234500',
      codigoQr: 'QR-ANDRES-004',
      nombreResponsable: 'Carmen López',
      telefonoResponsable: TELEFONO_2,
      telefonoResponsableVerificado: true,
      aceptaNotificaciones: true,
    },
  });

  const perfilSofia = await prisma.estudiante.create({
    data: {
      usuarioId: estudianteSofia.id,
      identificacion: 'TI-2001234567',
      codigoQr: 'QR-SOFIA-005',
      nombreResponsable: 'Carlos Núñez',
      telefonoResponsable: TELEFONO_2,
      telefonoResponsableVerificado: true,
      aceptaNotificaciones: true,
    },
  });

  // Asignar estudiantes a grupos
  await prisma.estudianteGrupo.createMany({
    data: [
      { estudianteId: perfilSantiago.id, grupoId: grupo10A.id }, // Santiago: 10-A
      { estudianteId: perfilValentina.id, grupoId: grupo10A.id }, // Valentina: 10-A (hermana)
      { estudianteId: perfilMateo.id, grupoId: grupo11B.id }, // Mateo: 11-B
      { estudianteId: perfilAndres.id, grupoId: grupo9A.id }, // Andrés: 9-A
      { estudianteId: perfilSofia.id, grupoId: grupoSofia.id }, // Sofía: 6-1 (Santander)
    ],
  });

  // Vincular acudientes con estudiantes
  await prisma.acudienteEstudiante.createMany({
    data: [
      { acudienteId: acudienteMaria.id, estudianteId: perfilSantiago.id, parentesco: 'madre', esPrincipal: true, activo: true },
      { acudienteId: acudienteMaria.id, estudianteId: perfilValentina.id, parentesco: 'madre', esPrincipal: true, activo: true },
      { acudienteId: acudientePatricia.id, estudianteId: perfilMateo.id, parentesco: 'madre', esPrincipal: true, activo: true },
      { acudienteId: acudienteCarmen.id, estudianteId: perfilAndres.id, parentesco: 'madre', esPrincipal: true, activo: true },
      { acudienteId: acudienteCarlosN.id, estudianteId: perfilSofia.id, parentesco: 'padre', esPrincipal: true, activo: true },
    ],
  });

  console.log('✅ 5 perfiles de estudiantes del login creados y asignados');

  // ============================================================================
  // 13. CREAR ESTUDIANTES ADICIONALES (~25 por grupo)
  // ============================================================================
  console.log('\n🎓 Creando estudiantes adicionales...');

  const nombresEst = ['Alejandro', 'Sofía', 'Mateo', 'Valentina', 'Santiago', 'Isabella', 'Sebastián', 'Camila',
    'Nicolás', 'Mariana', 'Daniel', 'Daniela', 'Diego', 'Gabriela', 'Juan', 'María', 'Andrés', 'Paula',
    'Felipe', 'Sara', 'Julián', 'Lucía', 'Samuel', 'Emma', 'Tomás'];

  let estudianteIdx = 10;
  const todosEstudiantes = [perfilSantiago, perfilMateo, perfilValentina, perfilAndres, perfilSofia];

  for (const grupo of grupos) {
    const numEstudiantes = 23 + Math.floor(Math.random() * 5); // 23-27 estudiantes por grupo

    for (let i = 0; i < numEstudiantes; i++) {
      const nombre = nombresEst[Math.floor(Math.random() * nombresEst.length)];
      const usaTelefono1 = estudianteIdx % 2 === 0;

      const usuario = await prisma.usuario.create({
        data: {
          email: `estudiante${estudianteIdx}@sanjose.edu`,
          passwordHash: hashPassword('Est123!'),
          nombres: nombre,
          apellidos: `Apellido ${estudianteIdx}`,
          identificacion: `EST-${String(estudianteIdx).padStart(4, '0')}`,
          rol: 'estudiante',
          activo: true,
        },
      });

      const estudiante = await prisma.estudiante.create({
        data: {
          usuarioId: usuario.id,
          identificacion: `TI-${String(1000000000 + estudianteIdx)}`,
          codigoQr: `QR-EST-${String(estudianteIdx).padStart(4, '0')}`,
          nombreResponsable: `Acudiente ${estudianteIdx}`,
          telefonoResponsable: usaTelefono1 ? TELEFONO_1 : TELEFONO_2,
          telefonoResponsableVerificado: true,
          aceptaNotificaciones: true,
        },
      });

      await prisma.estudianteGrupo.create({
        data: {
          estudianteId: estudiante.id,
          grupoId: grupo.id,
        },
      });

      await prisma.usuarioInstitucion.create({
        data: {
          usuarioId: usuario.id,
          institucionId: colegioSanJose.id,
          rolEnInstitucion: 'estudiante',
        },
      });

      todosEstudiantes.push(estudiante);
      estudianteIdx++;
    }
  }

  console.log(`✅ ${estudianteIdx - 10} estudiantes adicionales creados`);

  // ============================================================================
  // 14. GENERAR HORARIOS SIN CONFLICTOS
  // ============================================================================
  console.log('\n📅 Generando horarios optimizados...');

  // Crear mapa de profesores por materia (2 profesores por materia)
  const profesoresPorMateria = new Map<string, string[]>();

  for (const materia of materiasSanJose) {
    const profesoresParaMateria: string[] = [];

    // Buscar profesores que enseñan esta materia
    for (const prof of todosProfesores) {
      if (prof.materias && prof.materias.includes(materia.nombre)) {
        profesoresParaMateria.push(prof.id);
      }
    }

    // Si no hay suficientes profesores, agregar algunos genéricos
    while (profesoresParaMateria.length < 2) {
      // Buscar un profesor con menos asignaciones
      for (const prof of todosProfesores) {
        if (!profesoresParaMateria.includes(prof.id)) {
          profesoresParaMateria.push(prof.id);
          break;
        }
      }
      if (profesoresParaMateria.length === 0) break;
    }

    profesoresPorMateria.set(materia.id, profesoresParaMateria);
  }

  // Generar horarios
  const generador = new GeneradorHorarios(
    grupos,
    materiasSanJose,
    profesoresPorMateria,
    horasRequeridas,
  );

  const horariosGenerados = generador.generar();
  const conflictos = generador.verificarConflictos();

  console.log(`   📊 Conflictos de profesores: ${conflictos.conflictosProfesor}`);
  console.log(`   📊 Conflictos de grupos: ${conflictos.conflictosGrupo}`);

  // Insertar horarios en la base de datos
  let insertados = 0;
  for (const h of horariosGenerados) {
    await prisma.horario.create({
      data: {
        grupoId: h.grupoId,
        materiaId: h.materiaId,
        profesorId: h.profesorId,
        institucionId: colegioSanJose.id,
        periodoId: periodoSanJose.id,
        diaSemana: h.diaSemana,
        horaInicio: h.horaInicio,
        horaFin: h.horaFin,
      },
    });
    insertados++;
  }

  console.log(`✅ ${insertados} horarios creados sin conflictos`);

  // ============================================================================
  // 15. ESTADÍSTICAS DE DISTRIBUCIÓN
  // ============================================================================
  console.log('\n📊 Estadísticas de distribución de horarios:');

  // Contar clases por profesor
  const clasesPorProfesor = new Map<string, number>();
  for (const h of horariosGenerados) {
    clasesPorProfesor.set(h.profesorId, (clasesPorProfesor.get(h.profesorId) || 0) + 1);
  }

  const clasesArray = Array.from(clasesPorProfesor.values());
  const minClases = Math.min(...clasesArray);
  const maxClases = Math.max(...clasesArray);
  const avgClases = clasesArray.reduce((a, b) => a + b, 0) / clasesArray.length;

  console.log(`   👨‍🏫 Clases por profesor: min=${minClases}, max=${maxClases}, promedio=${avgClases.toFixed(1)}`);

  // Contar clases por grupo
  const clasesPorGrupo = new Map<string, number>();
  for (const h of horariosGenerados) {
    clasesPorGrupo.set(h.grupoId, (clasesPorGrupo.get(h.grupoId) || 0) + 1);
  }

  const clasesGrupoArray = Array.from(clasesPorGrupo.values());
  console.log(`   📚 Clases por grupo: min=${Math.min(...clasesGrupoArray)}, max=${Math.max(...clasesGrupoArray)}`);

  // ============================================================================
  // RESUMEN FINAL
  // ============================================================================
  console.log('\n\n═══════════════════════════════════════════════════════════════');
  console.log('✅ SEED COMPLETADO EXITOSAMENTE');
  console.log('═══════════════════════════════════════════════════════════════');
  console.log('\n📊 RESUMEN:');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`🏫 Instituciones: 3 (San José, Santander, Bolívar)`);
  console.log(`📚 Períodos: 2 (${currentYear})`);
  console.log(`📖 Materias: ${materiasSanJose.length} materias de secundaria`);
  console.log(`👥 Grupos: ${grupos.length} (6° a 11°, secciones A y B)`);
  console.log(`👨‍🏫 Profesores: ${todosProfesores.length + 1} (+ 1 sin asignación)`);
  console.log(`🎓 Estudiantes: ${todosEstudiantes.length}`);
  console.log(`📅 Horarios: ${insertados} (sin conflictos)`);
  console.log(`📱 Teléfonos: ${TELEFONO_1} y ${TELEFONO_2}`);
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('\n🔐 CREDENCIALES (coinciden con pantalla de login):');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('👑 Super Admin: superadmin@asistapp.com / Admin123!');
  console.log('🏫 Admin San José: admin@sanjose.edu / SanJose123!');
  console.log('🏫 Admin Santander: admin@santander.edu / Santander123!');
  console.log('🏫 Admin Multi-Sede: multiadmin@asistapp.com / Multi123!');
  console.log('👨‍🏫 Juan Pérez: juan.perez@sanjose.edu / Prof123!');
  console.log('👨‍🏫 Laura Gómez: laura.gomez@sanjose.edu / Prof123!');
  console.log('👨‍🏫 Pedro Sin Clases: vacio.profe@sanjose.edu / Prof123!');
  console.log('👨‍🏫 Carlos Díaz: carlos.diaz@santander.edu / Prof123!');
  console.log('🎓 Santiago Mendoza: santiago.mendoza@sanjose.edu / Est123! (10-A)');
  console.log('🎓 Mateo Castro: mateo.castro@sanjose.edu / Est123! (11-B)');
  console.log('🎓 Valentina Rojas: valentina.rojas@sanjose.edu / Est123! (10-A)');
  console.log('🎓 Andrés López: andres.lopez@sanjose.edu / Est123! (9-A)');
  console.log('🎓 Sofía Núñez: sofia.nunez@santander.edu / Est123! (6-1)');
  console.log('👨‍👩‍👧 María Mendoza: maria.mendoza@email.com / Acu123! (Madre de Santiago y Valentina)');
  console.log('👨‍👩‍👧 Patricia Castro: patricia.castro@email.com / Acu123! (Madre de Mateo)');
  console.log('👨‍👩‍👧 Carmen López: carmen.lopez@email.com / Acu123! (Madre de Andrés)');
  console.log('👨‍👩‍👧 Carlos Núñez: carlos.nunez@email.com / Acu123! (Padre de Sofía)');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('\n✨ Horarios distribuidos correctamente sin conflictos!\n');
}

main()
  .catch((e) => {
    console.error('❌ Error durante el seed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
