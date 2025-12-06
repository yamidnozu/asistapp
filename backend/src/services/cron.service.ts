// @ts-ignore
import cron from 'node-cron';
import logger from '../utils/logger';
import { notificationQueueService } from './notification-queue.service';
import { notificationService } from './notification.service';

export class CronService {
    public static init() {
        logger.info('[CronService] Initializing cron jobs...');

        // Run every 15 minutes
        cron.schedule('*/15 * * * *', async () => {
            logger.info('[CronService] Running scheduled notification queue processing...');
            await notificationQueueService.processPendingNotifications();
        });

        // Run daily at 20:00 (8 PM) for total absence check
        cron.schedule('0 20 * * *', async () => {
            logger.info('[CronService] Running daily total absence check...');
            await notificationService.processDailyTotalAbsenceNotifications();
        });

        logger.info('[CronService] Cron jobs initialized.');
    }
}
