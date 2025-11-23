import { prisma } from '../../config/database';
import { ConflictError } from '../../types';
import { HorarioService } from '../horario.service';

// Mock prisma
jest.mock('../../config/database', () => ({
    prisma: {
        horario: {
            findFirst: jest.fn(),
            create: jest.fn(),
            count: jest.fn(),
            findMany: jest.fn(),
            findUnique: jest.fn(),
            update: jest.fn(),
            delete: jest.fn(),
        },
        periodoAcademico: {
            findFirst: jest.fn(),
        },
        grupo: {
            findFirst: jest.fn(),
        },
        materia: {
            findFirst: jest.fn(),
        },
        usuario: {
            findFirst: jest.fn(),
        },
        asistencia: {
            count: jest.fn(),
        },
        // Mock para $queryRawUnsafe (usado en validateHorarioConflict)
        $queryRawUnsafe: jest.fn(),
    },
}));

describe('HorarioService', () => {
    const mockDate = new Date();
    const validRequest = {
        periodoId: 'periodo-1',
        grupoId: 'grupo-1',
        materiaId: 'materia-1',
        profesorId: 'profesor-1',
        diaSemana: 1,
        horaInicio: '08:00',
        horaFin: '10:00',
        institucionId: 'inst-1',
    };

    beforeEach(() => {
        jest.clearAllMocks();
    });

    describe('createHorario', () => {
        // Setup common mocks for validation
        beforeEach(() => {
            (prisma.periodoAcademico.findFirst as jest.Mock).mockResolvedValue({ 
                id: 'periodo-1', 
                nombre: 'Periodo 1',
                activo: true 
            });
            (prisma.grupo.findFirst as jest.Mock).mockResolvedValue({ 
                id: 'grupo-1', 
                nombre: 'Grupo 1', 
                periodoId: 'periodo-1',
                institucionId: 'inst-1'
            });
            (prisma.materia.findFirst as jest.Mock).mockResolvedValue({ 
                id: 'materia-1', 
                nombre: 'Materia 1',
                institucionId: 'inst-1'
            });
            (prisma.usuario.findFirst as jest.Mock).mockResolvedValue({ 
                id: 'profesor-1', 
                nombres: 'Juan', 
                apellidos: 'Perez',
                rol: 'profesor',
                usuarioInstituciones: [{ institucionId: 'inst-1' }]
            });
        });

        it('should throw ConflictError when group has overlapping schedule', async () => {
            // Mock $queryRawUnsafe para simular conflicto de grupo
            // La query debe retornar un horario conflictivo del tipo 'grupo'
            (prisma.$queryRawUnsafe as jest.Mock).mockResolvedValue([
                { 
                    id: 'conflict-1', 
                    horaInicio: '09:00', 
                    horaFin: '11:00',
                    grupoId: 'grupo-1',
                    profesorId: 'profesor-1',
                    tipo: 'grupo'
                }
            ]);

            await expect(HorarioService.createHorario(validRequest))
                .rejects
                .toThrow(ConflictError);
            
            // Verificar que se llamó $queryRawUnsafe
            expect(prisma.$queryRawUnsafe).toHaveBeenCalled();
        });

        it('should throw ConflictError when professor has overlapping schedule', async () => {
            // Mock $queryRawUnsafe para simular conflicto de profesor
            (prisma.$queryRawUnsafe as jest.Mock).mockResolvedValue([
                { 
                    id: 'conflict-2', 
                    horaInicio: '07:00', 
                    horaFin: '09:00',
                    grupoId: 'grupo-1',
                    profesorId: 'profesor-1',
                    tipo: 'profesor'
                }
            ]);

            await expect(HorarioService.createHorario(validRequest))
                .rejects
                .toThrow(ConflictError);
            
            // Verificar que se llamó $queryRawUnsafe
            expect(prisma.$queryRawUnsafe).toHaveBeenCalled();
        });

        it('should create horario when no conflicts exist', async () => {
            // Mock $queryRawUnsafe sin conflictos
            (prisma.$queryRawUnsafe as jest.Mock).mockResolvedValue([]);
            
            // Mock creación exitosa
            (prisma.horario.create as jest.Mock).mockResolvedValue({
                ...validRequest,
                id: 'new-horario',
                createdAt: mockDate,
                periodoAcademico: { 
                    id: 'periodo-1', 
                    nombre: 'P1', 
                    fechaInicio: mockDate, 
                    fechaFin: mockDate, 
                    activo: true 
                },
                grupo: { 
                    id: 'grupo-1', 
                    nombre: 'G1', 
                    grado: '1', 
                    seccion: 'A', 
                    institucionId: 'inst-1', 
                    periodoId: 'periodo-1' 
                },
                materia: { 
                    id: 'materia-1', 
                    nombre: 'M1', 
                    codigo: 'M1' 
                },
                profesor: { 
                    id: 'profesor-1', 
                    nombres: 'Juan', 
                    apellidos: 'Perez' 
                },
                _count: { asistencias: 0 }
            });

            const result = await HorarioService.createHorario(validRequest);

            expect(result).toBeDefined();
            expect(result.id).toBe('new-horario');
            expect(prisma.$queryRawUnsafe).toHaveBeenCalled();
            expect(prisma.horario.create).toHaveBeenCalled();
        });

        it('should validate time format correctly', async () => {
            const invalidRequest = {
                ...validRequest,
                horaInicio: '25:00', // Hora inválida
            };

            // Mock sin conflictos para que llegue a la validación de formato
            (prisma.$queryRawUnsafe as jest.Mock).mockResolvedValue([]);

            await expect(HorarioService.createHorario(invalidRequest))
                .rejects
                .toThrow();
        });

        it('should validate that start time is before end time', async () => {
            const invalidRequest = {
                ...validRequest,
                horaInicio: '10:00',
                horaFin: '08:00', // Fin antes del inicio
            };

            // Mock sin conflictos para que llegue a la validación de orden
            (prisma.$queryRawUnsafe as jest.Mock).mockResolvedValue([]);

            await expect(HorarioService.createHorario(invalidRequest))
                .rejects
                .toThrow();
        });
    });
});
