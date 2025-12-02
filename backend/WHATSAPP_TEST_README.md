# 🧪 Script de Prueba WhatsApp API

Este script permite probar el envío de mensajes de WhatsApp usando la API v22.0 de Meta.

## 🚀 Uso Rápido

### Mensaje de Prueba (a tu número)
```bash
cd backend
node test-whatsapp.js
```

### Mensaje Personalizado
```bash
# Con mensaje por defecto
node test-whatsapp.js +573103816321

# Con mensaje personalizado
node test-whatsapp.js +573103816321 "¡Hola! Este es mi mensaje personalizado"
```

## 📋 Funcionalidades

- ✅ **API v22.0**: Usa la versión más reciente de la API de WhatsApp
- ✅ **Mensajes de texto**: Envío de mensajes de texto con formato
- ✅ **Logging detallado**: Muestra el progreso y resultados
- ✅ **Manejo de errores**: Informa claramente si hay problemas
- ✅ **Modo interactivo**: Ejecuta sin parámetros para mensaje de prueba

## 🔧 Configuración

El script usa las credenciales configuradas en el archivo `.env`:
- `WHATSAPP_API_TOKEN`
- `WHATSAPP_PHONE_NUMBER_ID`

## 📱 Limitaciones

- Solo funciona con números registrados como testers en Meta
- Requiere que el número receptor haya iniciado conversación primero
- Para producción, necesitas templates aprobados por Meta

## 🎯 Ejemplos de Uso

```bash
# Prueba básica
node test-whatsapp.js

# A otro número
node test-whatsapp.js +573001112233

# Mensaje personalizado
node test-whatsapp.js +573103816321 "Sistema funcionando correctamente ✅"
```

## 📊 Respuesta Exitosa

Cuando el mensaje se envía correctamente, verás:
```
✅ Mensaje enviado exitosamente!
📋 ID del mensaje: wamid.HBgMNTczMTAzODE2MzIxFQIAERgS...
📱 Número de destino: 573103816321
💬 Mensaje: 🎓 *AsistApp - Prueba Interactiva*...
```