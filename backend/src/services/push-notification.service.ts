/**
 * Servicio de Notificaciones Push y In-App
 * Maneja el envío de notificaciones a usuarios (especialmente acudientes)
 * Usa Firebase Cloud Messaging para push notifications
 */

import { prisma } from '../config/database';
import { NotFoundError, ValidationError } from '../types';

// Tipos para las notificaciones
export interface CreateNotificacionInAppData {
    usuarioId: string;
    titulo: string;
    mensaje: string;
    tipo: 'ausencia' | 'tardanza' | 'justificado' | 'general' | 'sistema';
    estudianteId?: string;
    materiaId?: string;
    asistenciaId?: string;
    datos?: Record<string, unknown>;
}

export interface NotificacionResponse {
    id: string;
    titulo: string;
    mensaje: string;
    tipo: string;
    leida: boolean;
    estudianteId?: string;
    materiaId?: string;
    createdAt: Date;
    datos?: unknown;
}

export interface RegistrarDispositivoData {
    usuarioId: string;
    token: string;
    plataforma: 'android' | 'ios' | 'web';
    modelo?: string;
}

class PushNotificationService {
    /**
     * Crea una notificación in-app para un usuario
     */
    public static async crearNotificacionInApp(
        data: CreateNotificacionInAppData
    ): Promise<NotificacionResponse> {
        // Verificar que el usuario existe
        const usuario = await prisma.usuario.findUnique({
            where: { id: data.usuarioId },
        });

        if (!usuario) {
            throw new NotFoundError('Usuario no encontrado');
        }

        const notificacion = await prisma.notificacionInApp.create({
            data: {
                usuarioId: data.usuarioId,
                titulo: data.titulo,
                mensaje: data.mensaje,
                tipo: data.tipo,
                estudianteId: data.estudianteId,
                materiaId: data.materiaId,
                asistenciaId: data.asistenciaId,
                datos: data.datos ? JSON.parse(JSON.stringify(data.datos)) : undefined,
            },
        });

        return {
            id: notificacion.id,
            titulo: notificacion.titulo,
            mensaje: notificacion.mensaje,
            tipo: notificacion.tipo,
            leida: notificacion.leida,
            estudianteId: notificacion.estudianteId ?? undefined,
            materiaId: notificacion.materiaId ?? undefined,
            createdAt: notificacion.createdAt,
            datos: notificacion.datos,
        };
    }

    /**
     * Obtiene las notificaciones de un usuario con paginación
     */
    public static async obtenerNotificaciones(
        usuarioId: string,
        page: number = 1,
        limit: number = 20,
        soloNoLeidas: boolean = false
    ): Promise<{ notificaciones: NotificacionResponse[]; total: number; noLeidas: number }> {
        const where = {
            usuarioId,
            ...(soloNoLeidas ? { leida: false } : {}),
        };

        const [notificaciones, total, noLeidas] = await Promise.all([
            prisma.notificacionInApp.findMany({
                where,
                orderBy: { createdAt: 'desc' },
                skip: (page - 1) * limit,
                take: limit,
            }),
            prisma.notificacionInApp.count({ where }),
            prisma.notificacionInApp.count({
                where: { usuarioId, leida: false },
            }),
        ]);

        return {
            notificaciones: notificaciones.map((n) => ({
                id: n.id,
                titulo: n.titulo,
                mensaje: n.mensaje,
                tipo: n.tipo,
                leida: n.leida,
                estudianteId: n.estudianteId ?? undefined,
                materiaId: n.materiaId ?? undefined,
                createdAt: n.createdAt,
                datos: n.datos,
            })),
            total,
            noLeidas,
        };
    }

    /**
     * Marca una notificación como leída
     */
    public static async marcarComoLeida(
        notificacionId: string,
        usuarioId: string
    ): Promise<void> {
        const notificacion = await prisma.notificacionInApp.findFirst({
            where: { id: notificacionId, usuarioId },
        });

        if (!notificacion) {
            throw new NotFoundError('Notificación no encontrada');
        }

        await prisma.notificacionInApp.update({
            where: { id: notificacionId },
            data: { leida: true },
        });
    }

    /**
     * Marca todas las notificaciones de un usuario como leídas
     */
    public static async marcarTodasComoLeidas(usuarioId: string): Promise<number> {
        const result = await prisma.notificacionInApp.updateMany({
            where: { usuarioId, leida: false },
            data: { leida: true },
        });

        return result.count;
    }

    /**
     * Registra un dispositivo para recibir notificaciones push
     */
    public static async registrarDispositivo(
        data: RegistrarDispositivoData
    ): Promise<void> {
        if (!data.token || data.token.trim() === '') {
            throw new ValidationError('Token FCM es requerido');
        }

        // Verificar que el usuario existe
        const usuario = await prisma.usuario.findUnique({
            where: { id: data.usuarioId },
        });

        if (!usuario) {
            throw new NotFoundError('Usuario no encontrado');
        }

        // Upsert del dispositivo (actualizar si ya existe, crear si no)
        await prisma.dispositivoFCM.upsert({
            where: {
                usuarioId_token: {
                    usuarioId: data.usuarioId,
                    token: data.token,
                },
            },
            update: {
                plataforma: data.plataforma,
                modelo: data.modelo,
                activo: true,
                updatedAt: new Date(),
            },
            create: {
                usuarioId: data.usuarioId,
                token: data.token,
                plataforma: data.plataforma,
                modelo: data.modelo,
                activo: true,
            },
        });
    }

    /**
     * Elimina un dispositivo de las notificaciones push
     */
    public static async eliminarDispositivo(
        usuarioId: string,
        token: string
    ): Promise<void> {
        await prisma.dispositivoFCM.deleteMany({
            where: { usuarioId, token },
        });
    }

    /**
     * Desactiva todos los dispositivos de un usuario
     */
    public static async desactivarDispositivos(usuarioId: string): Promise<void> {
        await prisma.dispositivoFCM.updateMany({
            where: { usuarioId },
            data: { activo: false },
        });
    }

    /**
     * Obtiene los tokens FCM activos de un usuario
     */
    public static async obtenerTokensFCM(usuarioId: string): Promise<string[]> {
        const dispositivos = await prisma.dispositivoFCM.findMany({
            where: { usuarioId, activo: true },
            select: { token: true },
        });

        return dispositivos.map((d) => d.token);
    }

    /**
     * Envía notificación a todos los acudientes de un estudiante
     * Crea notificaciones in-app y prepara para push
     */
    public static async notificarAcudientes(
        estudianteId: string,
        tipo: 'ausencia' | 'tardanza' | 'justificado',
        datosAdicionales: {
            materiaNombre?: string;
            materiaId?: string;
            fecha?: string;
            hora?: string;
            asistenciaId?: string;
        }
    ): Promise<{ notificados: number; tokens: string[] }> {
        // Obtener el estudiante con sus acudientes
        const estudiante = await prisma.estudiante.findUnique({
            where: { id: estudianteId },
            include: {
                usuario: { select: { nombres: true, apellidos: true } },
                acudientes: {
                    where: { activo: true },
                    include: {
                        acudiente: {
                            select: { id: true, nombres: true },
                        },
                    },
                },
            },
        });

        if (!estudiante) {
            throw new NotFoundError('Estudiante no encontrado');
        }

        const nombreEstudiante = `${estudiante.usuario.nombres} ${estudiante.usuario.apellidos}`;

        // Construir mensaje según el tipo
        let titulo = '';
        let mensaje = '';

        switch (tipo) {
            case 'ausencia':
                titulo = `⚠️ Ausencia de ${estudiante.usuario.nombres}`;
                mensaje = `${nombreEstudiante} ha sido marcado como AUSENTE`;
                if (datosAdicionales.materiaNombre) {
                    mensaje += ` en la clase de ${datosAdicionales.materiaNombre}`;
                }
                if (datosAdicionales.hora) {
                    mensaje += ` a las ${datosAdicionales.hora}`;
                }
                break;
            case 'tardanza':
                titulo = `⏰ Tardanza de ${estudiante.usuario.nombres}`;
                mensaje = `${nombreEstudiante} llegó tarde`;
                if (datosAdicionales.materiaNombre) {
                    mensaje += ` a la clase de ${datosAdicionales.materiaNombre}`;
                }
                break;
            case 'justificado':
                titulo = `✅ Falta justificada de ${estudiante.usuario.nombres}`;
                mensaje = `La ausencia de ${nombreEstudiante} ha sido justificada`;
                if (datosAdicionales.materiaNombre) {
                    mensaje += ` en ${datosAdicionales.materiaNombre}`;
                }
                break;
        }

        if (datosAdicionales.fecha) {
            mensaje += ` (${datosAdicionales.fecha})`;
        }

        // Crear notificación para cada acudiente y recolectar tokens
        const tokens: string[] = [];
        let notificados = 0;

        for (const relacion of estudiante.acudientes) {
            try {
                // Crear notificación in-app
                await this.crearNotificacionInApp({
                    usuarioId: relacion.acudiente.id,
                    titulo,
                    mensaje,
                    tipo,
                    estudianteId,
                    materiaId: datosAdicionales.materiaId,
                    asistenciaId: datosAdicionales.asistenciaId,
                    datos: datosAdicionales,
                });

                // Obtener tokens FCM del acudiente
                const acudienteTokens = await this.obtenerTokensFCM(relacion.acudiente.id);
                tokens.push(...acudienteTokens);

                notificados++;
            } catch (error) {
                console.error(`Error notificando a acudiente ${relacion.acudiente.id}:`, error);
            }
        }

        return { notificados, tokens };
    }

    /**
     * Cuenta las notificaciones no leídas de un usuario
     */
    public static async contarNoLeidas(usuarioId: string): Promise<number> {
        return prisma.notificacionInApp.count({
            where: { usuarioId, leida: false },
        });
    }

    /**
     * Elimina notificaciones antiguas (limpieza)
     * Por defecto elimina notificaciones de más de 90 días
     */
    public static async limpiarNotificacionesAntiguas(
        diasAntiguedad: number = 90
    ): Promise<number> {
        const fechaLimite = new Date();
        fechaLimite.setDate(fechaLimite.getDate() - diasAntiguedad);

        const result = await prisma.notificacionInApp.deleteMany({
            where: {
                createdAt: { lt: fechaLimite },
                leida: true, // Solo eliminar las ya leídas
            },
        });

        return result.count;
    }
}

export default PushNotificationService;
