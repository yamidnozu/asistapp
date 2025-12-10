import axios from 'axios';
import logger from '../../utils/logger';
import { normalizePhoneNumber } from '../../utils/phone.utils';

export interface NotificationMessage {
    to: string;
    body: string;
    // Parámetros para el template de fallback (cuando falla texto por ventana 24h)
    // Estos se usan automáticamente si hay un template configurado
    templateParams?: {
        guardianName?: string;    // {{1}} Nombre del acudiente
        studentName?: string;     // {{2}} Nombre del estudiante (para notificación individual)
        status?: string;          // {{3}} Estado (inasistencia, tardanza, etc.)
        subjectName?: string;     // {{4}} Nombre de la materia
        date?: string;            // {{5}} Fecha
        summary?: string;         // Para resumen consolidado (múltiples estudiantes)
    };
    template?: {
        name: string;
        language: {
            code: string;
        };
        components?: Array<{
            type: 'header' | 'body' | 'button';
            parameters?: Array<{
                type: 'text' | 'currency' | 'date_time' | 'image' | 'document' | 'video';
                text?: string;
                currency?: { fallback_value: string; code: string; amount_1000: number };
                date_time?: { fallback_value: string };
                image?: { link: string };
                document?: { link: string; filename?: string };
                video?: { link: string };
            }>;
            sub_type?: 'quick_reply' | 'url';
            index?: number;
        }>;
    };
}

export interface NotificationResult {
    success: boolean;
    messageId?: string;
    error?: string;
    provider: string;
    cost?: number;
    rawResponse?: Record<string, any>;
}

export interface INotificationAdapter {
    send(message: NotificationMessage): Promise<NotificationResult>;
    getProviderName(): string;
}

export class TwilioAdapter implements INotificationAdapter {
    private accountSid: string;
    private authToken: string;
    private fromNumber: string;

    constructor() {
        this.accountSid = process.env.TWILIO_ACCOUNT_SID || '';
        this.authToken = process.env.TWILIO_AUTH_TOKEN || '';
        this.fromNumber = process.env.TWILIO_FROM_NUMBER || '';
    }

    async send(message: NotificationMessage): Promise<NotificationResult> {
        logger.info(`[TwilioAdapter] Enviando SMS a ${message.to}: ${message.body.substring(0, 50)}...`);

        // Verificar configuración en producción
        if (process.env.NODE_ENV === 'production') {
            if (!this.accountSid || !this.authToken || !this.fromNumber) {
                logger.error('[TwilioAdapter] Configuración de Twilio incompleta en producción');
                return {
                    success: false,
                    error: 'Twilio no configurado correctamente',
                    provider: 'SMS'
                };
            }

            try {
                // Usar Twilio SDK en producción
                const twilio = require('twilio');
                const client = twilio(this.accountSid, this.authToken);
                const result = await client.messages.create({
                    body: message.body,
                    from: this.fromNumber,
                    to: message.to
                });

                logger.info(`[TwilioAdapter] SMS enviado exitosamente. SID: ${result.sid}`);
                return {
                    success: true,
                    messageId: result.sid,
                    provider: 'SMS',
                    cost: parseFloat(result.price || '0')
                };
            } catch (error: any) {
                logger.error(`[TwilioAdapter] Error enviando SMS: ${error.message}`);
                return {
                    success: false,
                    error: error.message,
                    provider: 'SMS'
                };
            }
        }

        // Simulación en desarrollo
        await new Promise(resolve => setTimeout(resolve, 300));

        // Simulate success
        return {
            success: true,
            messageId: `sms_${Date.now()}_${Math.random().toString(36).substring(7)}`,
            provider: 'SMS'
        };
    }

    getProviderName(): string {
        return 'SMS';
    }
}

export class EmailAdapter implements INotificationAdapter {
    private apiKey: string;
    private fromEmail: string;

    constructor() {
        this.apiKey = process.env.SENDGRID_API_KEY || '';
        this.fromEmail = process.env.FROM_EMAIL || 'noreply@asistapp.com';
    }

    async send(message: NotificationMessage): Promise<NotificationResult> {
        logger.info(`[EmailAdapter] Enviando email a ${message.to}: ${message.body.substring(0, 50)}...`);

        // Verificar configuración en producción
        if (process.env.NODE_ENV === 'production') {
            if (!this.apiKey) {
                logger.error('[EmailAdapter] API Key de SendGrid no configurada en producción');
                return {
                    success: false,
                    error: 'SendGrid no configurado correctamente',
                    provider: 'EMAIL'
                };
            }

            try {
                // Usar SendGrid en producción
                const sgMail = require('@sendgrid/mail');
                sgMail.setApiKey(this.apiKey);
                const msg = {
                    to: message.to,
                    from: this.fromEmail,
                    subject: 'Notificación de Asistencia - AsistApp',
                    text: message.body,
                    html: `<div style="font-family: Arial, sans-serif; padding: 20px;">
                        <h2 style="color: #2196F3;">AsistApp - Notificación de Asistencia</h2>
                        <p>${message.body.replace(/\n/g, '<br>')}</p>
                        <hr style="margin-top: 20px; border: none; border-top: 1px solid #ddd;">
                        <p style="color: #666; font-size: 12px;">Este mensaje fue enviado automáticamente por AsistApp.</p>
                    </div>`,
                };
                const result = await sgMail.send(msg);

                logger.info(`[EmailAdapter] Email enviado exitosamente`);
                return {
                    success: true,
                    messageId: result[0]?.headers?.['x-message-id'] || `email_${Date.now()}`,
                    provider: 'EMAIL'
                };
            } catch (error: any) {
                logger.error(`[EmailAdapter] Error enviando email: ${error.message}`);
                return {
                    success: false,
                    error: error.message,
                    provider: 'EMAIL'
                };
            }
        }

        // Simulación en desarrollo
        await new Promise(resolve => setTimeout(resolve, 200));

        // Simular éxito
        return {
            success: true,
            messageId: `email_${Date.now()}_${Math.random().toString(36).substring(7)}`,
            provider: 'EMAIL'
        };
    }

    getProviderName(): string {
        return 'EMAIL';
    }
}

export class ConsoleAdapter implements INotificationAdapter {
    async send(message: NotificationMessage): Promise<NotificationResult> {
        console.log(`[ConsoleAdapter] ---------------------------------------------------`);
        console.log(`[ConsoleAdapter] TO: ${message.to}`);
        console.log(`[ConsoleAdapter] BODY: ${message.body}`);
        if (message.template) {
            console.log(`[ConsoleAdapter] TEMPLATE: ${JSON.stringify(message.template)}`);
        }
        console.log(`[ConsoleAdapter] ---------------------------------------------------`);

        return {
            success: true,
            messageId: `console_${Date.now()}`,
            provider: 'CONSOLE'
        };
    }

    getProviderName(): string {
        return 'CONSOLE';
    }
}

export class WhatsAppAdapter implements INotificationAdapter {
    private token: string;
    private phoneNumberId: string;
    private apiUrl: string;
    private apiVersion: string = 'v22.0';

    // Template de fallback configurable (para cuando no hay ventana 24h)
    private fallbackTemplateName: string | null;
    private fallbackTemplateLanguage: string;

    constructor() {
        this.token = process.env.WHATSAPP_API_TOKEN || '';
        this.phoneNumberId = process.env.WHATSAPP_PHONE_NUMBER_ID || '';
        this.apiUrl = `https://graph.facebook.com/${this.apiVersion}/${this.phoneNumberId}/messages`;

        // Template de fallback (opcional) - debe estar aprobado en Meta
        // Ejemplo: WHATSAPP_FALLBACK_TEMPLATE=asistapp_notificacion
        this.fallbackTemplateName = process.env.WHATSAPP_FALLBACK_TEMPLATE || null;
        this.fallbackTemplateLanguage = process.env.WHATSAPP_FALLBACK_TEMPLATE_LANG || 'es_CO';

        if (!this.token || !this.phoneNumberId) {
            logger.warn('[WhatsAppAdapter] ⚠️ Missing WHATSAPP_API_TOKEN or WHATSAPP_PHONE_NUMBER_ID. WhatsApp notifications will fail.');
        } else {
            logger.info('[WhatsAppAdapter] ✅ Initialized with Phone Number ID: ' + this.phoneNumberId.substring(0, 6) + '***');
            if (this.fallbackTemplateName) {
                logger.info(`[WhatsAppAdapter] 📋 Fallback template configured: ${this.fallbackTemplateName} (${this.fallbackTemplateLanguage})`);
            } else {
                logger.info('[WhatsAppAdapter] ℹ️ No fallback template configured. Messages will fail if outside 24h window.');
            }
        }
    }

    /**
     * Envía un mensaje usando el template de fallback configurado
     * Solo se usa cuando el texto libre falla por ventana 24h
     */
    private async sendWithFallbackTemplate(
        formattedPhone: string,
        originalBody: string,
        templateParams?: NotificationMessage['templateParams']
    ): Promise<NotificationResult> {
        logger.debug('[WhatsAppAdapter] Entered sendWithFallbackTemplate. Params:', { formattedPhone, templateParams });

        if (!this.fallbackTemplateName) {
            logger.error(`[WhatsAppAdapter] ⚠️ No fallback template configured. Cannot send message to ${formattedPhone}.`);
            return {
                success: false,
                error: 'Mensaje no enviado: El destinatario no ha interactuado en las últimas 24 horas y no hay template de fallback configurado.',
                provider: 'WHATSAPP',
                rawResponse: {
                    errorCode: 131047,
                    reason: 'outside_24h_window_no_fallback',
                    originalMessage: originalBody
                }
            };
        }

        logger.info(`[WhatsAppAdapter] 🔄 Attempting fallback template sending for ${formattedPhone}. Template: ${this.fallbackTemplateName}`);

        // Construir payload con parámetros si están disponibles
        const payload: any = {
            messaging_product: 'whatsapp',
            recipient_type: 'individual',
            to: formattedPhone,
            type: 'template',
            template: {
                name: this.fallbackTemplateName,
                language: { code: this.fallbackTemplateLanguage }
            }
        };

        // Si hay parámetros, agregarlos al template
        // Dos formatos posibles:
        // 1. Individual: {{1}}=guardianName, {{2}}=studentName, {{3}}=status, {{4}}=subjectName, {{5}}=date
        // 2. Consolidado: {{1}}=guardianName, {{2}}=summary
        if (templateParams) {
            const parameters: Array<{ type: 'text'; text: string }> = [];

            if (templateParams.guardianName) {
                parameters.push({ type: 'text', text: templateParams.guardianName });
            }

            // Si hay summary, es un mensaje consolidado (múltiples estudiantes)
            if (templateParams.summary) {
                // Limitar a 1024 caracteres (límite de WhatsApp)
                const summaryText = templateParams.summary.length > 1000
                    ? templateParams.summary.substring(0, 997) + '...'
                    : templateParams.summary;
                parameters.push({ type: 'text', text: summaryText });
                logger.debug(`[WhatsAppAdapter] 📋 Building consolidated template with summary (${summaryText.length} chars)`);
            } else {
                // Mensaje individual: agregar resto de parámetros
                logger.debug('[WhatsAppAdapter] 📋 Building individual template with detailed params.');
                if (templateParams.studentName) {
                    parameters.push({ type: 'text', text: templateParams.studentName });
                }
                if (templateParams.status) {
                    parameters.push({ type: 'text', text: templateParams.status });
                }
                if (templateParams.subjectName) {
                    parameters.push({ type: 'text', text: templateParams.subjectName });
                }
                if (templateParams.date) {
                    parameters.push({ type: 'text', text: templateParams.date });
                }
            }

            if (parameters.length > 0) {
                payload.template.components = [{
                    type: 'body',
                    parameters: parameters
                }];
                logger.debug(`[WhatsAppAdapter] 📋 Final template params count: ${parameters.length}`);
            }
        }

        logger.debug('[WhatsAppAdapter] Attempting to send fallback template with payload:', JSON.stringify(payload, null, 2));

        try {
            const response = await axios.post(this.apiUrl, payload, {
                headers: {
                    'Authorization': `Bearer ${this.token}`,
                    'Content-Type': 'application/json'
                },
                timeout: 30000
            });

            const messageId = response.data.messages?.[0]?.id;
            logger.info(`[WhatsAppAdapter] ✅ Fallback template sent successfully to ${formattedPhone}. ID: ${messageId}`);

            return {
                success: true,
                messageId: messageId,
                provider: 'WHATSAPP',
                rawResponse: {
                    ...response.data,
                    fallbackUsed: true,
                    templateName: this.fallbackTemplateName,
                    originalMessage: originalBody
                }
            };
        } catch (fallbackError: any) {
            const errorData = fallbackError.response?.data?.error || fallbackError.message;
            logger.error(`[WhatsAppAdapter] ❌ Fallback template to ${formattedPhone} failed. Full error:`, errorData);

            return {
                success: false,
                error: `Template fallback failed: ${errorData?.message || fallbackError.message}`,
                provider: 'WHATSAPP',
                rawResponse: fallbackError.response?.data
            };
        }
    }


    async send(message: NotificationMessage): Promise<NotificationResult> {
        logger.debug('[WhatsAppAdapter] Received new send request.', { to: message.to, body: message.body.substring(0,30)+'...', template: message.template ? message.template.name : 'none' });
        
        // Si no hay configuración, usar modo mock en desarrollo
        if (!this.token || !this.phoneNumberId) {
            if (process.env.NODE_ENV !== 'production') {
                logger.warn(`[WhatsAppAdapter] 🔸 MOCK MODE - Would send to ${message.to}: ${message.body}`);
                return {
                    success: true,
                    messageId: `wa_mock_${Date.now()}_${Math.random().toString(36).substring(7)}`,
                    provider: 'WHATSAPP',
                    rawResponse: { mock: true, reason: 'Missing credentials in non-production' }
                };
            }
            logger.error('[WhatsAppAdapter] CRITICAL - Cannot send message, WhatsApp credentials not configured.');
            return {
                success: false,
                error: 'WhatsApp credentials not configured',
                provider: 'WHATSAPP'
            };
        }

        try {
            // Normalizar número de teléfono al formato E.164 (sin +)
            const formattedPhone = normalizePhoneNumber(message.to);
            logger.info(`[WhatsAppAdapter] 📤 Normalizing phone and preparing to send to ${formattedPhone}...`);

            // ===================================================================
            // ESTRATEGIA SIMPLIFICADA: Siempre intentar TEXTO LIBRE primero
            // Es más personalizado y flexible. Solo usa template como fallback.
            // ===================================================================

            // Paso 1: Intentar enviar como TEXTO LIBRE (más personalizado)
            const textPayload = {
                messaging_product: 'whatsapp',
                recipient_type: 'individual',
                to: formattedPhone,
                type: 'text',
                text: {
                    preview_url: false,
                    body: message.body
                }
            };

            logger.debug('[WhatsAppAdapter] 💬 STEP 1: Attempting to send text message with payload:', JSON.stringify(textPayload, null, 2));

            try {
                const response = await axios.post(this.apiUrl, textPayload, {
                    headers: {
                        'Authorization': `Bearer ${this.token}`,
                        'Content-Type': 'application/json'
                    },
                    timeout: 30000
                });

                const messageId = response.data.messages?.[0]?.id;
                logger.info(`[WhatsAppAdapter] ✅ SUCCESS: Text message sent successfully to ${formattedPhone}. ID: ${messageId}`);

                return {
                    success: true,
                    messageId: messageId,
                    provider: 'WHATSAPP',
                    rawResponse: { ...response.data, messageType: 'text' }
                };

            } catch (textError: any) {
                const errorCode = textError.response?.data?.error?.code;
                const errorMessage = textError.response?.data?.error?.message || textError.message;
                logger.warn(`[WhatsAppAdapter] ⚠️ INFO: Text message attempt to ${formattedPhone} failed.`, { error: textError.response?.data || textError.message });
                logger.info(`[WhatsAppAdapter] Detected error code: ${errorCode}`);

                // Error 131047: Re-engagement message (fuera de ventana 24h)
                // Intentar con template de fallback si está configurado
                if (errorCode === 131047) {
                    logger.warn(`[WhatsAppAdapter] ⚠️ Reason: Outside 24h window. STEP 2: Initiating fallback to template for ${formattedPhone}.`);
                    return await this.sendWithFallbackTemplate(formattedPhone, message.body, message.templateParams);
                }

                // Otros errores: propagar
                logger.error(`[WhatsAppAdapter] ❌ An unhandled error occurred during the text message attempt (not a 24h window error).`);
                throw textError;
            }

        } catch (error: any) {
            // Extraer información detallada del error de Meta API
            const errorData = error.response?.data?.error || error.response?.data || error.message;
            const statusCode = error.response?.status;

            logger.error(`[WhatsAppAdapter] ❌ FINAL ERROR: Unrecoverable error sending message (HTTP ${statusCode}):`, errorData);

            // Errores comunes de WhatsApp Cloud API:
            // - 131030: Recipient not in allowed list (sandbox)
            // - 131047: Re-engagement message (fuera de ventana 24h sin template)
            // - 131051: Invalid phone number
            // - 190: Invalid OAuth access token

            let friendlyError = 'Unknown error';
            if (typeof errorData === 'object') {
                friendlyError = errorData.message || errorData.error_user_msg || JSON.stringify(errorData);
            } else {
                friendlyError = String(errorData);
            }

            return {
                success: false,
                error: friendlyError,
                provider: 'WHATSAPP',
                rawResponse: error.response?.data
            };
        }
    }

    getProviderName(): string {
        return 'WHATSAPP';
    }
}
