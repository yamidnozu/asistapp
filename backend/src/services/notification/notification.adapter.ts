export interface NotificationMessage {
    to: string;
    body: string;
    template?: {
        name: string;
        language: string;
        components?: any[];
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
    private apiKey: string;
    private phoneNumberId: string;

    constructor() {
        this.apiKey = process.env.WHATSAPP_API_KEY || 'mock_key';
        this.phoneNumberId = process.env.WHATSAPP_PHONE_NUMBER_ID || 'mock_phone_id';
    }

    async send(message: NotificationMessage): Promise<NotificationResult> {
        console.log(`[WhatsAppAdapter] Sending WhatsApp to ${message.to}: ${message.body}`);

        // Mock implementation for development
        if (process.env.NODE_ENV === 'production') {
            // In production, use WhatsApp Business API
            // const response = await fetch(`https://graph.facebook.com/v17.0/${this.phoneNumberId}/messages`, {
            //     method: 'POST',
            //     headers: {
            //         'Authorization': `Bearer ${this.apiKey}`,
            //         'Content-Type': 'application/json'
            //     },
            //     body: JSON.stringify({
            //         messaging_product: 'whatsapp',
            //         to: message.to,
            //         type: message.template ? 'template' : 'text',
            //         ...(message.template ? { template: message.template } : { text: { body: message.body } })
            //     })
            // });
            // const data = await response.json();
            // return {
            //     success: response.ok,
            //     messageId: data.messages?.[0]?.id,
            //     provider: 'WHATSAPP',
            //     rawResponse: data
            // };
        }

        // Simulate network delay
        await new Promise(resolve => setTimeout(resolve, 250));

        // Simulate success
        return {
            success: true,
            messageId: `wa_${Date.now()}_${Math.random().toString(36).substring(7)}`,
            provider: 'WHATSAPP',
            rawResponse: { mock: true }
        };
    }

    getProviderName(): string {
        return 'WHATSAPP';
    }
}
