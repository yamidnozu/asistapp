import { FastifyInstance } from 'fastify';
import { NotificationController } from '../controllers/notification.controller';
import { authenticate } from '../middleware/auth';

export default async function notificationRoutes(fastify: FastifyInstance) {
    fastify.post('/notifications/manual-trigger', {
        preValidation: [authenticate]
    }, NotificationController.triggerManual);

    fastify.put('/institutions/:institutionId/notification-config', {
        preValidation: [authenticate]
    }, NotificationController.updateConfig);
}
