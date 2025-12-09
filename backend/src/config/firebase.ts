/**
 * Configuración de Firebase Admin SDK
 * Este módulo inicializa Firebase Admin para enviar notificaciones push reales
 */

import * as admin from 'firebase-admin';
import * as fs from 'fs';
import * as path from 'path';

let firebaseInitialized = false;

/**
 * Inicializa Firebase Admin SDK
 * Busca las credenciales en el siguiente orden:
 * 1. Variable de entorno GOOGLE_APPLICATION_CREDENTIALS (ruta al archivo JSON)
 * 2. Variable de entorno FIREBASE_SERVICE_ACCOUNT_JSON (contenido JSON directo)
 * 3. Archivo firebase-service-account.json en el directorio del proyecto
 */
export function initializeFirebase(): boolean {
    if (firebaseInitialized) {
        return true;
    }

    try {
        let credential: admin.credential.Credential | undefined;

        // Opción 1: GOOGLE_APPLICATION_CREDENTIALS apunta a un archivo
        const credentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
        if (credentialsPath && fs.existsSync(credentialsPath)) {
            console.log('🔥 Firebase: Usando credenciales desde GOOGLE_APPLICATION_CREDENTIALS');
            credential = admin.credential.applicationDefault();
        }
        // Opción 2: FIREBASE_SERVICE_ACCOUNT_JSON contiene el JSON directamente
        else if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
            console.log('🔥 Firebase: Usando credenciales desde FIREBASE_SERVICE_ACCOUNT_JSON');
            const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
            credential = admin.credential.cert(serviceAccount);
        }
        // Opción 3: Buscar archivo en la raíz del backend o en /opt/asistapp
        else {
            const possiblePaths = [
                path.join(__dirname, '../../firebase-service-account.json'),
                path.join(process.cwd(), 'firebase-service-account.json'),
                '/opt/asistapp/firebase-service-account.json',
                '/app/firebase-service-account.json',
            ];

            for (const p of possiblePaths) {
                if (fs.existsSync(p)) {
                    console.log(`🔥 Firebase: Usando credenciales desde ${p}`);
                    const serviceAccount = JSON.parse(fs.readFileSync(p, 'utf8'));
                    credential = admin.credential.cert(serviceAccount);
                    break;
                }
            }
        }

        if (!credential) {
            console.warn('⚠️ Firebase: No se encontraron credenciales. Las notificaciones push no funcionarán.');
            console.warn('   Configure GOOGLE_APPLICATION_CREDENTIALS, FIREBASE_SERVICE_ACCOUNT_JSON,');
            console.warn('   o coloque firebase-service-account.json en el directorio del proyecto.');
            return false;
        }

        admin.initializeApp({
            credential,
            projectId: process.env.FIREBASE_PROJECT_ID,
        });

        firebaseInitialized = true;
        console.log('✅ Firebase Admin SDK inicializado correctamente');
        return true;

    } catch (error) {
        console.error('❌ Error inicializando Firebase Admin SDK:', error);
        return false;
    }
}

/**
 * Verifica si Firebase está inicializado y listo para usar
 */
export function isFirebaseReady(): boolean {
    return firebaseInitialized;
}

/**
 * Obtiene la instancia de Firebase Messaging
 * Retorna null si Firebase no está inicializado
 */
export function getMessaging(): admin.messaging.Messaging | null {
    if (!firebaseInitialized) {
        return null;
    }
    return admin.messaging();
}

export default admin;
