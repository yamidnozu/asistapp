#!/usr/bin/env node

/**
 * Script de prueba para WhatsApp API v22.0
 * Uso: node test-whatsapp.js [numero] [mensaje]
 */

const axios = require('axios');

// Configuración de WhatsApp
const WHATSAPP_API_TOKEN = 'EAATWH2LvOj8BQDBrZAZCLhGveuRyecvyi0VL9LTPwhkfZBVQeDqeIZA2bSDIJqCIqkbEsSk333ycSLlGo7ccgUCKH5CeD9Bhr97lCSp3CfCUgaECUN9kzXZC06WpYqQIaxpXnBEV0TGCdm6Rv9MUjCylR7oyeOUgV5WqTNiqBv3gQfLZCCTwjQpOj2BPDiGoR5yLOXDT2NLQCNeRhd5zEqG1HSH1ytbjgZCWeG03cwUIkcV1vZCcGutY1i9tD0Fz528IbjKs0O56K4wSpROhWmtoe0UkL5cUkoyZCggZDZD';
const WHATSAPP_PHONE_NUMBER_ID = '947537288440449';

async function sendWhatsAppMessage(to, message) {
  try {
    console.log(`📤 Enviando mensaje a ${to}...`);

    const response = await axios.post(
      `https://graph.facebook.com/v22.0/${WHATSAPP_PHONE_NUMBER_ID}/messages`,
      {
        messaging_product: 'whatsapp',
        to: to,
        type: 'text',
        text: { body: message }
      },
      {
        headers: {
          'Authorization': `Bearer ${WHATSAPP_API_TOKEN}`,
          'Content-Type': 'application/json'
        }
      }
    );

    console.log('✅ Mensaje enviado exitosamente!');
    console.log('📋 ID del mensaje:', response.data.messages[0].id);
    console.log('📱 Número de destino:', to);
    console.log('💬 Mensaje:', message.substring(0, 50) + (message.length > 50 ? '...' : ''));

    return response.data;
  } catch (error) {
    console.error('❌ Error al enviar mensaje:');
    if (error.response) {
      console.error('   Código de estado:', error.response.status);
      console.error('   Respuesta:', JSON.stringify(error.response.data, null, 2));
    } else {
      console.error('   Error:', error.message);
    }
    throw error;
  }
}

// Función principal
async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    // Modo interactivo - mensaje de prueba
    const testNumber = '573103816321';
    const testMessage = `🎓 *AsistApp - Prueba Interactiva*\n\n¡Hola! Este es un mensaje de prueba enviado desde el script de Node.js.\n\n📅 Fecha: ${new Date().toLocaleString('es-CO')}\n⏰ Hora: ${new Date().toLocaleTimeString('es-CO')}\n\n✅ API WhatsApp v22.0 funcionando correctamente\n📱 Script: test-whatsapp.js\n\n🚀 ¡AsistApp listo para producción!`;

    console.log('🚀 Enviando mensaje de prueba a:', testNumber);
    await sendWhatsAppMessage(testNumber, testMessage);

  } else if (args.length === 1) {
    // Solo número - mensaje por defecto
    const phoneNumber = args[0];
    const defaultMessage = `🎓 *AsistApp - Mensaje Personalizado*\n\n¡Hola! Este mensaje fue enviado específicamente a tu número.\n\n📱 Número: ${phoneNumber}\n📅 Fecha: ${new Date().toLocaleString('es-CO')}\n\n✅ WhatsApp API funcionando correctamente`;

    await sendWhatsAppMessage(phoneNumber, defaultMessage);

  } else if (args.length >= 2) {
    // Número y mensaje personalizado
    const phoneNumber = args[0];
    const customMessage = args.slice(1).join(' ');

    await sendWhatsAppMessage(phoneNumber, customMessage);

  } else {
    console.log('📖 Uso del script:');
    console.log('  node test-whatsapp.js                    # Enviar mensaje de prueba');
    console.log('  node test-whatsapp.js +573103816321      # Enviar mensaje por defecto');
    console.log('  node test-whatsapp.js +573103816321 "Hola mundo"  # Mensaje personalizado');
    process.exit(1);
  }
}

// Ejecutar si se llama directamente
if (require.main === module) {
  main().catch(error => {
    console.error('💥 Error fatal:', error.message);
    process.exit(1);
  });
}

module.exports = { sendWhatsAppMessage };