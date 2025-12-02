// @ts-ignore
import cron from 'node-cron';
import { notificationQueueService } from './notification-queue.service';
import logger from '../utils/logger';

export class CronService {
    public static init() {
        logger.info('[CronService] Initializing cron jobs...');

        // Run every 15 minutes
        cron.schedule('*/15 * * * *', async () => {
            logger.info('[CronService] Running scheduled notification queue processing...');
            await notificationQueueService.processPendingNotifications();
        });

        logger.info('[CronService] Cron jobs initialized.');
    }
}
