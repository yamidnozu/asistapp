import axios from 'axios';
import { normalizePhoneNumber } from '../../utils/phone.utils';
import logger from '../../utils/logger';

export interface NotificationMessage {
    to: string;
    body: string;
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
        this.accountSid = process.env.TWILIO_ACCOUNT_SID || 'mock_sid';
        this.authToken = process.env.TWILIO_AUTH_TOKEN || 'mock_token';
        this.fromNumber = process.env.TWILIO_FROM_NUMBER || '+1234567890';
    }

    async send(message: NotificationMessage): Promise<NotificationResult> {
        console.log(`[TwilioAdapter] Sending SMS to ${message.to}: ${message.body}`);

        // Mock implementation for development
        if (process.env.NODE_ENV === 'production') {
            // In production, use Twilio SDK
            // const client = require('twilio')(this.accountSid, this.authToken);
            // const result = await client.messages.create({
            //     body: message.body,
            //     from: this.fromNumber,
            //     to: message.to
            // });
            // return {
            //     success: true,
            //     messageId: result.sid,
            //     provider: 'SMS',
            //     cost: parseFloat(result.price || '0')
            // };
        }

        // Simulate network delay
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
        this.apiKey = process.env.SENDGRID_API_KEY || 'mock_key';
        this.fromEmail = process.env.FROM_EMAIL || 'noreply@asistapp.com';
    }

    async send(message: NotificationMessage): Promise<NotificationResult> {
        console.log(`[EmailAdapter] Sending email to ${message.to}: ${message.body}`);

        // Mock implementation for development
        if (process.env.NODE_ENV === 'production') {
            // In production, use SendGrid or similar
            // const sgMail = require('@sendgrid/mail');
            // sgMail.setApiKey(this.apiKey);
            // const msg = {
            //     to: message.to,
            //     from: this.fromEmail,
            //     subject: 'Notificación de Asistencia',
            //     text: message.body,
            // };
            // const result = await sgMail.send(msg);
            // return {
            //     success: true,
            //     messageId: result[0].headers['x-message-id'],
            //     provider: 'EMAIL'
            // };
        }

        // Simulate network delay
        await new Promise(resolve => setTimeout(resolve, 200));

        // Simulate success
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
    private apiVersion: string = 'v17.0';

    constructor() {
        this.token = process.env.WHATSAPP_API_TOKEN || '';
        this.phoneNumberId = process.env.WHATSAPP_PHONE_NUMBER_ID || '';
        this.apiUrl = `https://graph.facebook.com/${this.apiVersion}/${this.phoneNumberId}/messages`;

        if (!this.token || !this.phoneNumberId) {
            logger.warn('[WhatsAppAdapter] ⚠️ Missing WHATSAPP_API_TOKEN or WHATSAPP_PHONE_NUMBER_ID. WhatsApp notifications will fail.');
        } else {
            logger.info('[WhatsAppAdapter] ✅ Initialized with Phone Number ID: ' + this.phoneNumberId.substring(0, 6) + '***');
        }
    }

    async send(message: NotificationMessage): Promise<NotificationResult> {
        // Si no hay configuración, usar modo mock en desarrollo
        if (!this.token || !this.phoneNumberId) {
            if (process.env.NODE_ENV !== 'production') {
                logger.info(`[WhatsAppAdapter] 🔸 MOCK MODE - Would send to ${message.to}: ${message.body}`);
                return {
                    success: true,
                    messageId: `wa_mock_${Date.now()}_${Math.random().toString(36).substring(7)}`,
                    provider: 'WHATSAPP',
                    rawResponse: { mock: true, reason: 'Missing credentials in non-production' }
                };
            }
            return {
                success: false,
                error: 'WhatsApp credentials not configured',
                provider: 'WHATSAPP'
            };
        }

        try {
            // Normalizar número de teléfono al formato E.164 (sin +)
            const formattedPhone = normalizePhoneNumber(message.to);
            logger.info(`[WhatsAppAdapter] 📤 Sending to ${formattedPhone}...`);

            // Estructura base del payload según WhatsApp Cloud API
            let payload: Record<string, any> = {
                messaging_product: 'whatsapp',
                recipient_type: 'individual',
                to: formattedPhone,
            };

            // Decidir si es Template o Texto libre
            if (message.template) {
                // Template messages: Requerido para iniciar conversaciones
                // o enviar mensajes fuera de la ventana de 24h
                payload.type = 'template';
                payload.template = {
                    name: message.template.name,
                    language: message.template.language,
                    ...(message.template.components && { components: message.template.components })
                };
                logger.info(`[WhatsAppAdapter] 📋 Using template: ${message.template.name}`);
            } else {
                // Texto libre: Solo funciona si el usuario escribió en las últimas 24h
                // (ventana de conversación activa)
                payload.type = 'text';
                payload.text = { 
                    preview_url: false,
                    body: message.body 
                };
                logger.info(`[WhatsAppAdapter] 💬 Sending text message (requires 24h window)`);
            }

            const response = await axios.post(this.apiUrl, payload, {
                headers: {
                    'Authorization': `Bearer ${this.token}`,
                    'Content-Type': 'application/json'
                },
                timeout: 30000 // 30 segundos timeout
            });

            const messageId = response.data.messages?.[0]?.id;
            logger.info(`[WhatsAppAdapter] ✅ Message sent successfully. ID: ${messageId}`);

            return {
                success: true,
                messageId: messageId,
                provider: 'WHATSAPP',
                rawResponse: response.data
            };

        } catch (error: any) {
            // Extraer información detallada del error de Meta API
            const errorData = error.response?.data?.error || error.response?.data || error.message;
            const statusCode = error.response?.status;
            
            logger.error(`[WhatsAppAdapter] ❌ Error sending message (HTTP ${statusCode}):`, errorData);

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
