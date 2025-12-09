/**
 * Servicio de Acudiente
 * Maneja todas las operaciones relacionadas con los acudientes (padres/tutores)
 * Incluye gestión de hijos, historial de asistencias y estadísticas
 */

import { prisma } from '../config/database';
import { UserRole } from '../constants/roles';
import { NotFoundError, ValidationError, AuthorizationError } from '../types';

// Tipos para las respuestas
export interface HijoResponse {
    id: string;
    usuarioId: string;
    nombres: string;
    apellidos: string;
    identificacion: string;
    parentesco: string;
    esPrincipal: boolean;
    grupo?: {
        id: string;
        nombre: string;
        grado: string;
        seccion?: string;
    };
    estadisticasResumen: {
        totalClases: number;
        presentes: number;
        ausentes: number;
        tardanzas: number;
        justificados: number;
        porcentajeAsistencia: number;
    };
}

export interface AsistenciaHistorialItem {
    id: string;
    fecha: Date;
    estado: string;
    horaRegistro: Date;
    tipoRegistro: string;
    observaciones?: string;
    materia: {
        id: string;
        nombre: string;
    };
    profesor: {
        id: string;
        nombres: string;
        apellidos: string;
    };
    horario: {
        horaInicio: string;
        horaFin: string;
    };
}

export interface EstadisticasCompletas {
    resumen: {
        totalClases: number;
        presentes: number;
        ausentes: number;
        tardanzas: number;
        justificados: number;
        porcentajeAsistencia: number;
    };
    porMateria: Array<{
        materiaId: string;
        materiaNombre: string;
        totalClases: number;
        ausentes: number;
        tardanzas: number;
        porcentajeAsistencia: number;
    }>;
    tendenciaSemanal: Array<{
        semana: string;
        presentes: number;
        ausentes: number;
        tardanzas: number;
    }>;
    ultimasFaltas: AsistenciaHistorialItem[];
}

export interface VincularEstudianteData {
    acudienteId: string;
    estudianteId: string;
    parentesco: string;
    esPrincipal?: boolean;
}

class AcudienteService {
    /**
     * Obtiene la lista de hijos vinculados a un acudiente
     */
    public static async getHijos(acudienteId: string): Promise<HijoResponse[]> {
        // Verificar que el usuario es acudiente
        const acudiente = await prisma.usuario.findUnique({
            where: { id: acudienteId },
        });

        if (!acudiente || acudiente.rol !== UserRole.ACUDIENTE) {
            throw new AuthorizationError('Solo los acudientes pueden acceder a esta información');
        }

        // Obtener relaciones con estudiantes
        const relaciones = await prisma.acudienteEstudiante.findMany({
            where: { acudienteId, activo: true },
            include: {
                estudiante: {
                    include: {
                        usuario: {
                            select: {
                                id: true,
                                nombres: true,
                                apellidos: true,
                            },
                        },
                        estudiantesGrupos: {
                            include: {
                                grupo: {
                                    select: {
                                        id: true,
                                        nombre: true,
                                        grado: true,
                                        seccion: true,
                                    },
                                },
                            },
                            take: 1, // Solo el grupo actual
                        },
                    },
                },
            },
        });

        // Para cada estudiante, obtener estadísticas resumidas
        const hijos: HijoResponse[] = [];

        for (const relacion of relaciones) {
            const estudiante = relacion.estudiante;
            const estadisticas = await this.getEstadisticasResumen(estudiante.id);

            hijos.push({
                id: estudiante.id,
                usuarioId: estudiante.usuario.id,
                nombres: estudiante.usuario.nombres,
                apellidos: estudiante.usuario.apellidos,
                identificacion: estudiante.identificacion,
                parentesco: relacion.parentesco,
                esPrincipal: relacion.esPrincipal,
                grupo: estudiante.estudiantesGrupos[0]?.grupo
                    ? {
                        id: estudiante.estudiantesGrupos[0].grupo.id,
                        nombre: estudiante.estudiantesGrupos[0].grupo.nombre,
                        grado: estudiante.estudiantesGrupos[0].grupo.grado,
                        seccion: estudiante.estudiantesGrupos[0].grupo.seccion ?? undefined,
                    }
                    : undefined,
                estadisticasResumen: estadisticas,
            });
        }

        return hijos;
    }

    /**
     * Obtiene el detalle de un hijo específico
     */
    public static async getHijoDetalle(
        acudienteId: string,
        estudianteId: string
    ): Promise<HijoResponse> {
        // Verificar la relación acudiente-estudiante
        const relacion = await prisma.acudienteEstudiante.findFirst({
            where: { acudienteId, estudianteId, activo: true },
            include: {
                estudiante: {
                    include: {
                        usuario: {
                            select: {
                                id: true,
                                nombres: true,
                                apellidos: true,
                            },
                        },
                        estudiantesGrupos: {
                            include: {
                                grupo: {
                                    select: {
                                        id: true,
                                        nombre: true,
                                        grado: true,
                                        seccion: true,
                                    },
                                },
                            },
                        },
                    },
                },
            },
        });

        if (!relacion) {
            throw new NotFoundError('Estudiante no encontrado o no está vinculado a este acudiente');
        }

        const estadisticas = await this.getEstadisticasResumen(estudianteId);

        return {
            id: relacion.estudiante.id,
            usuarioId: relacion.estudiante.usuario.id,
            nombres: relacion.estudiante.usuario.nombres,
            apellidos: relacion.estudiante.usuario.apellidos,
            identificacion: relacion.estudiante.identificacion,
            parentesco: relacion.parentesco,
            esPrincipal: relacion.esPrincipal,
            grupo: relacion.estudiante.estudiantesGrupos[0]?.grupo
                ? {
                    id: relacion.estudiante.estudiantesGrupos[0].grupo.id,
                    nombre: relacion.estudiante.estudiantesGrupos[0].grupo.nombre,
                    grado: relacion.estudiante.estudiantesGrupos[0].grupo.grado,
                    seccion: relacion.estudiante.estudiantesGrupos[0].grupo.seccion ?? undefined,
                }
                : undefined,
            estadisticasResumen: estadisticas,
        };
    }

    /**
     * Obtiene el historial de asistencias de un estudiante
     */
    public static async getHistorialAsistencias(
        acudienteId: string,
        estudianteId: string,
        page: number = 1,
        limit: number = 20,
        fechaInicio?: Date,
        fechaFin?: Date,
        estado?: string
    ): Promise<{ asistencias: AsistenciaHistorialItem[]; total: number }> {
        // Verificar la relación
        const relacion = await prisma.acudienteEstudiante.findFirst({
            where: { acudienteId, estudianteId, activo: true },
        });

        if (!relacion) {
            throw new AuthorizationError('No tienes acceso a la información de este estudiante');
        }

        const where = {
            estudianteId,
            ...(fechaInicio && fechaFin
                ? { fecha: { gte: fechaInicio, lte: fechaFin } }
                : {}),
            ...(estado ? { estado } : {}),
        };

        const [asistencias, total] = await Promise.all([
            prisma.asistencia.findMany({
                where,
                orderBy: { fecha: 'desc' },
                skip: (page - 1) * limit,
                take: limit,
                include: {
                    horario: {
                        include: {
                            materia: { select: { id: true, nombre: true } },
                            profesor: { select: { id: true, nombres: true, apellidos: true } },
                        },
                    },
                },
            }),
            prisma.asistencia.count({ where }),
        ]);

        return {
            asistencias: asistencias.map((a: typeof asistencias[0]) => ({
                id: a.id,
                fecha: a.fecha,
                estado: a.estado,
                horaRegistro: a.horaRegistro,
                tipoRegistro: a.tipoRegistro,
                observaciones: a.observaciones ?? undefined,
                materia: {
                    id: a.horario.materia.id,
                    nombre: a.horario.materia.nombre,
                },
                profesor: {
                    id: a.horario.profesor?.id ?? '',
                    nombres: a.horario.profesor?.nombres ?? 'Sin asignar',
                    apellidos: a.horario.profesor?.apellidos ?? '',
                },
                horario: {
                    horaInicio: a.horario.horaInicio,
                    horaFin: a.horario.horaFin,
                },
            })),
            total,
        };
    }

    /**
     * Obtiene estadísticas completas de un estudiante
     */
    public static async getEstadisticasCompletas(
        acudienteId: string,
        estudianteId: string
    ): Promise<EstadisticasCompletas> {
        // Verificar la relación
        const relacion = await prisma.acudienteEstudiante.findFirst({
            where: { acudienteId, estudianteId, activo: true },
        });

        if (!relacion) {
            throw new AuthorizationError('No tienes acceso a la información de este estudiante');
        }

        // Obtener todas las asistencias
        const asistencias = await prisma.asistencia.findMany({
            where: { estudianteId },
            include: {
                horario: {
                    include: {
                        materia: { select: { id: true, nombre: true } },
                    },
                },
            },
        });

        // Calcular resumen general
        const resumen = {
            totalClases: asistencias.length,
            presentes: asistencias.filter((a: typeof asistencias[0]) => a.estado === 'PRESENTE').length,
            ausentes: asistencias.filter((a: typeof asistencias[0]) => a.estado === 'AUSENTE').length,
            tardanzas: asistencias.filter((a: typeof asistencias[0]) => a.estado === 'TARDANZA').length,
            justificados: asistencias.filter((a: typeof asistencias[0]) => a.estado === 'JUSTIFICADO').length,
            porcentajeAsistencia: 0,
        };
        resumen.porcentajeAsistencia =
            resumen.totalClases > 0
                ? Math.round(((resumen.presentes + resumen.justificados) / resumen.totalClases) * 100)
                : 100;

        // Estadísticas por materia
        const materiaMap = new Map<string, { id: string; nombre: string; total: number; ausentes: number; tardanzas: number }>();

        for (const asistencia of asistencias) {
            const materiaId = asistencia.horario.materia.id;
            const materiaNombre = asistencia.horario.materia.nombre;

            if (!materiaMap.has(materiaId)) {
                materiaMap.set(materiaId, { id: materiaId, nombre: materiaNombre, total: 0, ausentes: 0, tardanzas: 0 });
            }

            const stats = materiaMap.get(materiaId)!;
            stats.total++;
            if (asistencia.estado === 'AUSENTE') stats.ausentes++;
            if (asistencia.estado === 'TARDANZA') stats.tardanzas++;
        }

        const porMateria = Array.from(materiaMap.values())
            .map((m: { id: string; nombre: string; total: number; ausentes: number; tardanzas: number }) => ({
                materiaId: m.id,
                materiaNombre: m.nombre,
                totalClases: m.total,
                ausentes: m.ausentes,
                tardanzas: m.tardanzas,
                porcentajeAsistencia: m.total > 0 ? Math.round(((m.total - m.ausentes) / m.total) * 100) : 100,
            }))
            .sort((a: { porcentajeAsistencia: number }, b: { porcentajeAsistencia: number }) => a.porcentajeAsistencia - b.porcentajeAsistencia); // Ordenar por peor asistencia

        // Tendencia semanal (últimas 4 semanas)
        const tendenciaSemanal: Array<{ semana: string; presentes: number; ausentes: number; tardanzas: number }> = [];
        const ahora = new Date();

        for (let i = 3; i >= 0; i--) {
            const inicioSemana = new Date(ahora);
            inicioSemana.setDate(ahora.getDate() - (ahora.getDay() + 7 * i));
            inicioSemana.setHours(0, 0, 0, 0);

            const finSemana = new Date(inicioSemana);
            finSemana.setDate(inicioSemana.getDate() + 6);
            finSemana.setHours(23, 59, 59, 999);

            const asistenciasSemana = asistencias.filter(
                (a: typeof asistencias[0]) => a.fecha >= inicioSemana && a.fecha <= finSemana
            );

            tendenciaSemanal.push({
                semana: `Semana ${inicioSemana.toLocaleDateString('es', { day: '2-digit', month: 'short' })}`,
                presentes: asistenciasSemana.filter((a: typeof asistencias[0]) => a.estado === 'PRESENTE').length,
                ausentes: asistenciasSemana.filter((a: typeof asistencias[0]) => a.estado === 'AUSENTE').length,
                tardanzas: asistenciasSemana.filter((a: typeof asistencias[0]) => a.estado === 'TARDANZA').length,
            });
        }

        // Últimas 5 faltas
        const ultimasFaltas = asistencias
            .filter((a: typeof asistencias[0]) => a.estado === 'AUSENTE' || a.estado === 'TARDANZA')
            .sort((a: typeof asistencias[0], b: typeof asistencias[0]) => b.fecha.getTime() - a.fecha.getTime())
            .slice(0, 5)
            .map((a: typeof asistencias[0]) => ({
                id: a.id,
                fecha: a.fecha,
                estado: a.estado,
                horaRegistro: a.horaRegistro,
                tipoRegistro: a.tipoRegistro,
                observaciones: a.observaciones ?? undefined,
                materia: {
                    id: a.horario.materia.id,
                    nombre: a.horario.materia.nombre,
                },
                profesor: {
                    id: '',
                    nombres: '',
                    apellidos: '',
                },
                horario: {
                    horaInicio: a.horario.horaInicio,
                    horaFin: a.horario.horaFin,
                },
            }));

        return {
            resumen,
            porMateria,
            tendenciaSemanal,
            ultimasFaltas,
        };
    }

    /**
     * Vincula un estudiante a un acudiente
     */
    public static async vincularEstudiante(
        acudienteId: string,
        estudianteId: string,
        parentesco: string,
        esPrincipal: boolean = false
    ): Promise<void> {
        // Verificar que el acudiente existe y tiene el rol correcto
        const acudiente = await prisma.usuario.findUnique({
            where: { id: acudienteId },
        });

        if (!acudiente || acudiente.rol !== UserRole.ACUDIENTE) {
            throw new ValidationError('El usuario no es un acudiente válido');
        }

        // Verificar que el estudiante existe
        const estudiante = await prisma.estudiante.findUnique({
            where: { id: estudianteId },
        });

        if (!estudiante) {
            throw new NotFoundError('Estudiante no encontrado');
        }

        // Verificar parentesco válido
        const parentescosValidos = ['padre', 'madre', 'tutor', 'abuelo', 'abuela', 'tio', 'tia', 'hermano', 'otro'];
        if (!parentescosValidos.includes(parentesco.toLowerCase())) {
            throw new ValidationError(`Parentesco no válido. Valores permitidos: ${parentescosValidos.join(', ')}`);
        }

        // Crear o actualizar la relación
        await prisma.acudienteEstudiante.upsert({
            where: {
                acudienteId_estudianteId: {
                    acudienteId,
                    estudianteId,
                },
            },
            update: {
                parentesco: parentesco.toLowerCase(),
                esPrincipal,
                activo: true,
            },
            create: {
                acudienteId,
                estudianteId,
                parentesco: parentesco.toLowerCase(),
                esPrincipal,
                activo: true,
            },
        });
    }

    /**
     * Desvincula un estudiante de un acudiente
     */
    public static async desvincularEstudiante(
        acudienteId: string,
        estudianteId: string
    ): Promise<void> {
        await prisma.acudienteEstudiante.updateMany({
            where: { acudienteId, estudianteId },
            data: { activo: false },
        });
    }

    /**
     * Obtiene los acudientes de un estudiante (para administradores)
     */
    public static async getAcudientesDeEstudiante(
        estudianteId: string
    ): Promise<Array<{ id: string; nombres: string; apellidos: string; email: string; telefono?: string; parentesco: string; esPrincipal: boolean }>> {
        const relaciones = await prisma.acudienteEstudiante.findMany({
            where: { estudianteId, activo: true },
            include: {
                acudiente: {
                    select: {
                        id: true,
                        nombres: true,
                        apellidos: true,
                        email: true,
                        telefono: true,
                    },
                },
            },
        });

        return relaciones.map((r: typeof relaciones[0]) => ({
            id: r.acudiente.id,
            nombres: r.acudiente.nombres,
            apellidos: r.acudiente.apellidos,
            email: r.acudiente.email,
            telefono: r.acudiente.telefono ?? undefined,
            parentesco: r.parentesco,
            esPrincipal: r.esPrincipal,
        }));
    }

    /**
     * Helper: Obtiene estadísticas resumidas de un estudiante
     */
    private static async getEstadisticasResumen(
        estudianteId: string
    ): Promise<{
        totalClases: number;
        presentes: number;
        ausentes: number;
        tardanzas: number;
        justificados: number;
        porcentajeAsistencia: number;
    }> {
        const [total, presentes, ausentes, tardanzas, justificados] = await Promise.all([
            prisma.asistencia.count({ where: { estudianteId } }),
            prisma.asistencia.count({ where: { estudianteId, estado: 'PRESENTE' } }),
            prisma.asistencia.count({ where: { estudianteId, estado: 'AUSENTE' } }),
            prisma.asistencia.count({ where: { estudianteId, estado: 'TARDANZA' } }),
            prisma.asistencia.count({ where: { estudianteId, estado: 'JUSTIFICADO' } }),
        ]);

        const porcentajeAsistencia =
            total > 0 ? Math.round(((presentes + justificados) / total) * 100) : 100;

        return {
            totalClases: total,
            presentes,
            ausentes,
            tardanzas,
            justificados,
            porcentajeAsistencia,
        };
    }
}

export default AcudienteService;
