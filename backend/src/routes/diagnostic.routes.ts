/**
 * Rutas de Diagnóstico (Temporales)
 * Endpoints para realizar pruebas internas y verificar el estado del sistema.
 * ¡¡¡ATENCIÓN!!! Este archivo debe ser eliminado después de la depuración.
 */

import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import PushNotificationService from '../services/push-notification.service';
import { prisma } from '../config/database';

export async function diagnosticRoutes(fastify: FastifyInstance) {

    /**
     * GET /diag/test-fcm-registration
     * 1. Intenta registrar un dispositivo con un token falso.
     * 2. Lee y devuelve TODOS los dispositivos en la tabla DispositivoFCM.
     * Esto prueba el flujo completo de registro en la base de datos de forma aislada.
     */
    fastify.get('/test-fcm-registration', async (request: FastifyRequest, reply: FastifyReply) => {
        const testUserId = 'DIAGNOSTIC_USER'; // Usamos un ID de usuario falso para no afectar a usuarios reales
        const testToken = `FAKE_TOKEN_AT_${new Date().getTime()}`; // Token único para cada prueba
        let registrationResult = {};
        let readResult = {};
        let finalStatus = 'UNKNOWN';

        request.log.info(`<<<< INICIANDO TEST DE DIAGNÓSTICO DEFINITIVO >>>>`);

        try {
            // --- PASO 1: INTENTAR ESCRIBIR EN LA DB ---
            request.log.info({ userId: testUserId, token: testToken }, `<<<< DIAGNOSTICO: Intentando escribir en la tabla dispositivos_fcm...`);
            await PushNotificationService.registrarDispositivo({
                usuarioId: testUserId,
                token: testToken,
                plataforma: 'android',
                modelo: 'controlled-test',
            });
            request.log.info(`<<<< DIAGNOSTICO: La llamada a registrarDispositivo finalizó SIN errores.`);
            registrationResult = { status: 'SUCCESS', message: 'La función de Prisma (upsert) se ejecutó sin lanzar una excepción.' };
        } catch (error) {
            const err = error as Error;
            request.log.error(err, `<<<< DIAGNOSTICO: ERROR CATASTRÓFICO durante la escritura en la DB.`);
            registrationResult = { status: 'FAILED', message: 'La función de Prisma (upsert) LANZÓ una excepción.', error: err.message };
            finalStatus = 'FAILED_ON_WRITE';
        }

        try {
            // --- PASO 2: LEER DE LA DB PARA VERIFICAR ---
            request.log.info(`<<<< DIAGNOSTICO: Leyendo la tabla dispositivos_fcm para verificar la escritura...`);
            const devices = await prisma.dispositivoFCM.findMany();
            request.log.info({ deviceCount: devices.length, devices }, `<<<< DIAGNOSTICO: Se encontraron ${devices.length} dispositivos en la tabla.`);
            readResult = devices;

            // Verificar si nuestro token de prueba está presente
            const foundTestToken = devices.some(d => d.token === testToken);
            if (finalStatus !== 'FAILED_ON_WRITE') {
                finalStatus = foundTestToken ? 'SUCCESS' : 'FAILED_ON_READ_VERIFICATION';
            }

        } catch (error) {
            const err = error as Error;
            request.log.error(err, `<<<< DIAGNOSTICO: ERROR CATASTRÓFICO durante la lectura de la DB.`);
            readResult = { status: 'FAILED', message: 'La lectura con Prisma (findMany) LANZÓ una excepción.', error: err.message };
            if (finalStatus !== 'FAILED_ON_WRITE') {
                finalStatus = 'FAILED_ON_READ';
            }
        }

        // --- PASO 3: DEVOLVER RESULTADO ---
        return reply.send({
            testStatus: finalStatus,
            description: "Este test intenta escribir un token falso en la tabla 'dispositivos_fcm' y luego lee la tabla para verificar si la escritura fue exitosa.",
            results: {
                writeAttempt: registrationResult,
                readVerification: readResult,
            }
        });
    });
}

export default diagnosticRoutes;
