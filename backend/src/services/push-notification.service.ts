/**
 * Servicio de Notificaciones Push y In-App
 * Maneja el envío de notificaciones a usuarios (especialmente acudientes)
 * Usa Firebase Cloud Messaging para push notifications
 */

import { prisma } from '../config/database';
import { NotFoundError, ValidationError } from '../types';
import { getMessaging, isFirebaseReady } from '../config/firebase';

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

export interface PushNotificationData {
    titulo: string;
    mensaje: string;
    tipo: string;
    datos?: Record<string, string>;
}

export interface PushNotificationResult {
    enviados: number;
    fallidos: number;
    tokensInvalidos: string[];
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
            notificaciones: notificaciones.map((n: typeof notificaciones[0]) => ({
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

        // --- NUEVA LÓGICA: Asegurar que este token de dispositivo solo esté activo para el usuario actual ---
        await prisma.dispositivoFCM.updateMany({
            where: {
                token: data.token, // El mismo token de dispositivo físico
                NOT: {
                    usuarioId: data.usuarioId // Pero para un usuario diferente
                }
            },
            data: {
                activo: false,
                updatedAt: new Date()
            }
        });
        // --- FIN NUEVA LÓGICA ---

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

        return dispositivos.map((d: typeof dispositivos[0]) => d.token);
    }

    /**
     * Envía notificación a todos los acudientes de un estudiante
     * Crea notificaciones in-app y envía push notifications reales
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
    ): Promise<{ notificados: number; tokens: string[]; pushEnviados: number; pushFallidos: number }> {
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

        // 🚀 ENVIAR NOTIFICACIONES PUSH REALES
        // Este es el paso crítico que hace que el teléfono vibre/suene
        let pushResult: PushNotificationResult = { enviados: 0, fallidos: 0, tokensInvalidos: [] };
        if (tokens.length > 0) {
            pushResult = await this.enviarPushNotification(tokens, {
                titulo,
                mensaje,
                tipo,
                datos: {
                    estudianteId,
                    ...(datosAdicionales.materiaId ? { materiaId: datosAdicionales.materiaId } : {}),
                    ...(datosAdicionales.asistenciaId ? { asistenciaId: datosAdicionales.asistenciaId } : {}),
                },
            });
        }

        return {
            notificados,
            tokens,
            pushEnviados: pushResult.enviados,
            pushFallidos: pushResult.fallidos,
        };
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
     * Envía notificaciones push reales a través de Firebase Cloud Messaging
     * Este es el método que realmente hace que el teléfono vibre/suene
     * 
     * @param tokens - Lista de tokens FCM a los que enviar
     * @param data - Datos de la notificación (título, mensaje, tipo)
     * @returns Resultado del envío con conteo de enviados/fallidos
     */
    public static async enviarPushNotification(
        tokens: string[],
        data: PushNotificationData
    ): Promise<PushNotificationResult> {
        const result: PushNotificationResult = {
            enviados: 0,
            fallidos: 0,
            tokensInvalidos: [],
        };

        if (tokens.length === 0) {
            console.log('📱 Push: No hay tokens para enviar notificaciones');
            return result;
        }

        // Verificar si Firebase está listo
        if (!isFirebaseReady()) {
            console.warn('⚠️ Push: Firebase no está inicializado. Las notificaciones push no se enviarán.');
            console.warn('   Configure las credenciales de Firebase para habilitar push notifications.');
            result.fallidos = tokens.length;
            return result;
        }

        const messaging = getMessaging();
        if (!messaging) {
            console.error('❌ Push: No se pudo obtener instancia de Firebase Messaging');
            result.fallidos = tokens.length;
            return result;
        }

        try {
            console.log(`📱 Push: Enviando notificación a ${tokens.length} dispositivo(s)...`);
            console.log(`   Título: ${data.titulo}`);
            console.log(`   Mensaje: ${data.mensaje}`);

            // Preparar el mensaje para múltiples dispositivos
            const message = {
                tokens: tokens,
                notification: {
                    title: data.titulo,
                    body: data.mensaje,
                },
                data: {
                    tipo: data.tipo,
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                    ...(data.datos || {}),
                },
                android: {
                    priority: 'high' as const,
                    notification: {
                        channelId: 'asistapp_notifications',
                        priority: 'high' as const,
                        defaultSound: true,
                        defaultVibrateTimings: true,
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            alert: {
                                title: data.titulo,
                                body: data.mensaje,
                            },
                            sound: 'default',
                            badge: 1,
                        },
                    },
                },
            };

            // Enviar a múltiples dispositivos
            const response = await messaging.sendEachForMulticast(message);

            result.enviados = response.successCount;
            result.fallidos = response.failureCount;

            console.log(`✅ Push: ${response.successCount} enviados, ${response.failureCount} fallidos`);

            // Procesar tokens inválidos para desactivarlos
            response.responses.forEach((resp: { success: boolean; error?: { code: string; message: string } }, idx: number) => {
                if (!resp.success && resp.error) {
                    const errorCode = resp.error.code;
                    // Estos códigos indican que el token ya no es válido
                    if (
                        errorCode === 'messaging/invalid-registration-token' ||
                        errorCode === 'messaging/registration-token-not-registered' ||
                        errorCode === 'messaging/invalid-argument'
                    ) {
                        result.tokensInvalidos.push(tokens[idx]);
                        console.warn(`⚠️ Push: Token inválido detectado: ${tokens[idx].substring(0, 20)}...`);
                    } else {
                        console.error(`❌ Push: Error enviando a token ${idx}:`, resp.error.message);
                    }
                }
            });

            // Desactivar tokens inválidos en la base de datos
            if (result.tokensInvalidos.length > 0) {
                await this.desactivarTokensInvalidos(result.tokensInvalidos);
            }

        } catch (error) {
            console.error('❌ Push: Error general enviando notificaciones:', error);
            result.fallidos = tokens.length;
        }

        return result;
    }

    /**
     * Desactiva tokens FCM que ya no son válidos
     */
    private static async desactivarTokensInvalidos(tokens: string[]): Promise<void> {
        if (tokens.length === 0) return;

        try {
            const updated = await prisma.dispositivoFCM.updateMany({
                where: { token: { in: tokens } },
                data: { activo: false },
            });
            console.log(`🗑️ Push: ${updated.count} token(s) inválido(s) desactivado(s)`);
        } catch (error) {
            console.error('Error desactivando tokens inválidos:', error);
        }
    }

    /**
     * Envía notificación push a un usuario específico
     * Combina crear notificación in-app + enviar push real
     */
    public static async enviarNotificacionCompleta(
        usuarioId: string,
        data: PushNotificationData
    ): Promise<{ inApp: NotificacionResponse; push: PushNotificationResult }> {
        // 1. Crear notificación in-app
        const inApp = await this.crearNotificacionInApp({
            usuarioId,
            titulo: data.titulo,
            mensaje: data.mensaje,
            tipo: data.tipo as 'ausencia' | 'tardanza' | 'justificado' | 'general' | 'sistema',
            datos: data.datos as Record<string, unknown>,
        });

        // 2. Obtener tokens del usuario
        const tokens = await this.obtenerTokensFCM(usuarioId);

        // 3. Enviar push real
        const push = await this.enviarPushNotification(tokens, data);

        return { inApp, push };
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
