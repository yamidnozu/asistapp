// @ts-ignore
import cron from 'node-cron';
import logger from '../utils/logger';
import { notificationQueueService } from './notification-queue.service';
import { notificationService } from './notification.service';

export class CronService {
    public static init() {
        logger.info('[CronService] Initializing cron jobs...');

        // Run every 15 minutes - procesa la cola de notificaciones pendientes
        cron.schedule('*/15 * * * *', async () => {
            logger.info('[CronService] Running scheduled notification queue processing...');
            await notificationQueueService.processPendingNotifications();
        });

        // Run daily at 6 PM Colombia time for end-of-day summary/alerts
        // Configuramos timezone para evitar confusión con UTC del servidor
        cron.schedule('0 18 * * *', async () => {
            logger.info('[CronService] Running daily total absence check (6 PM Colombia)...');
            await notificationService.processDailyTotalAbsenceNotifications();
        }, {
            scheduled: true,
            timezone: 'America/Bogota'
        });

        logger.info('[CronService] Cron jobs initialized.');
        logger.info('[CronService] - Notification queue: every 15 minutes');
        logger.info('[CronService] - Daily summary: 6:00 PM America/Bogota');
    }
}
