import { FastifyInstance } from 'fastify';
import { NotificationController } from '../controllers/notification.controller';
import { authenticate } from '../middleware/auth';

export default async function notificationRoutes(fastify: FastifyInstance) {
    // Disparar notificaciones manualmente
    fastify.post('/notifications/manual-trigger', {
        preValidation: [authenticate]
    }, NotificationController.triggerManual);

    // Actualizar configuración de notificaciones de una institución
    fastify.put('/institutions/:institutionId/notification-config', {
        preValidation: [authenticate]
    }, NotificationController.updateConfig);

    // 🧪 Enviar mensaje de prueba (solo super_admin)
    fastify.post('/notifications/test', {
        preValidation: [authenticate]
    }, NotificationController.sendTestMessage);

    // 📊 Obtener estadísticas de la cola
    fastify.get('/notifications/queue/stats', {
        preValidation: [authenticate]
    }, NotificationController.getQueueStats);

    // 🔄 Reintentar notificaciones fallidas (DEAD_LETTER)
    fastify.post('/notifications/queue/retry-dead-letter', {
        preValidation: [authenticate]
    }, NotificationController.retryDeadLetter);

    // 📜 Obtener historial de notificaciones
    fastify.get('/notifications/logs', {
        preValidation: [authenticate]
    }, NotificationController.getNotificationLogs);
}
