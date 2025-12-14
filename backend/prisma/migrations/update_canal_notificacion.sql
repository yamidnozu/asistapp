-- Migración: Actualizar canal de notificación de NONE/SMS a PUSH/WHATSAPP/BOTH
-- Fecha: 2025-12-14
-- Descripción: Cambia los valores del campo canalNotificacion para que coincidan con las opciones reales del sistema

-- 1. Actualizar registros existentes con NONE a PUSH (notificaciones en la app por defecto)
UPDATE configuraciones 
SET canal_notificacion = 'PUSH' 
WHERE canal_notificacion = 'NONE';

-- 2. Actualizar registros existentes con SMS a WHATSAPP (no tenemos SMS, solo WhatsApp)
UPDATE configuraciones 
SET canal_notificacion = 'WHATSAPP' 
WHERE canal_notificacion = 'SMS';

-- 3. Los registros con WHATSAPP se mantienen igual

-- Nota: Los nuevos registros usarán 'PUSH' como valor por defecto
