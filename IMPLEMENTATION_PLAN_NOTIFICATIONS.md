# Implementation Plan: Notification System Enhancement

## Date: 2025-11-28
## Status: READY TO IMPLEMENT

---

## Executive Summary

The notification system infrastructure is **already implemented** using the Adapter Pattern. This document outlines enhancements needed to complete the full notification feature set.

---

## Current State Analysis

### ✅ Already Implemented

1. **Adapter Pattern** (`notification.adapter.ts`)
   - `INotificationAdapter` interface
   - `WhatsAppAdapter` for Meta API integration
   - `ConsoleAdapter` for development/testing

2. **Database Schema** (`schema.prisma`)
   - `Configuracion` table with notification fields:
     - `notificacionesActivas` (Boolean)
     - `canalNotificacion` (WHATSAPP/SMS/NONE)
     - `modoNotificacionAsistencia` (INSTANT/END_OF_DAY/MANUAL_ONLY)
     - `horaDisparoNotificacion` (Time string)
   - `LogNotificacion` table for tracking sent notifications
   - `ColaNotificacion` table for queue management
   - `Estudiante` table with:
     - `nombreResponsable`
     - `telefonoResponsable`
     - `telefonoResponsableVerificado`
     - `aceptaNotificaciones`

3. **Services**
   - `notification.service.ts` - Core notification logic
   - `notification-queue.service.ts` - Queue processing
   - `cron.service.ts` - Scheduled job runner

4. **API Routes**
   - `POST /notifications/manual-trigger` - Manual notification dispatch
   - `PUT /institutions/:institutionId/notification-config` - Update settings

5. **Integration**
   - Attendance service already calls `notificationService.notifyAttendanceCreated()`

---

## What Needs Enhancement

### 1. WhatsApp Adapter Implementation
**Priority: HIGH**
**File**: `backend/src/services/notification/notification.adapter.ts`

Current state: Mock implementation
Needed: Real Meta WhatsApp Business API integration

```typescript
// TODO: Implement actual API calls
async send(message: NotificationMessage): Promise<NotificationResult> {
  // Use axios to call Meta Graph API
  // Handle rate limits, retries, error responses
}
```

### 2. Notification Templates
**Priority: MEDIUM**
**File**: Create `backend/src/services/notification/templates.ts`

Define message templates for different scenarios:
- Student absence
- Student tardiness
- End-of-day summary
- Custom messages

### 3. Frontend UI for Settings
**Priority: HIGH**
**Files**: 
- `lib/screens/institution/settings_screen.dart`
- `lib/services/institution_service.dart`

Features needed:
- Toggle notifications on/off
- Select notification channel (WhatsApp/SMS/None)
- Choose mode (Instant/End of Day/Manual Only)
- Set end-of-day notification time
- Test notification button

### 4. Enhanced Queue Processing
**Priority: MEDIUM**
**File**: `backend/src/services/notification-queue.service.ts`

Current: Groups by student
Enhancement needed: Group by phone number to consolidate messages for parents with multiple children

### 5. Error Handling & Retry Logic
**Priority: MEDIUM**
**File**: `backend/src/services/notification.service.ts`

Add:
- Exponential backoff for failed notifications
- Maximum retry attempts
- Dead letter queue for permanently failed messages

### 6. Cost Tracking
**Priority: LOW**
**File**: `backend/src/services/notification.service.ts`

Implement cost calculation per message based on provider pricing

### 7. Phone Number Verification
**Priority: MEDIUM**
**Files**: 
- Create `backend/src/services/phone-verification.service.ts`
- Add verification flow in student registration

---

## Implementation Phases

### Phase 1: Core Enhancement (Week 1)
1. ✅ Review existing implementation
2. ⏳ Implement WhatsApp API integration
3. ⏳ Create notification templates
4. ⏳ Build institution settings UI
5. ⏳ Test end-to-end flow

### Phase 2: Optimization (Week 2)
1. Enhance queue processing (group by phone)
2. Add retry logic and error handling
3. Implement rate limiting
4. Add monitoring and logging

### Phase 3: Polish (Week 3)
1. Phone number verification
2. Cost tracking
3. Admin dashboard for notification history
4. Bulk notification testing

---

## Database Migration Status

**No migrations needed!** The schema already contains all required fields.

Verification:
```sql
-- Check Configuracion table
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'configuraciones';

-- Expected fields:
-- notificaciones_activas (boolean)
-- canal_notificacion (varchar)
-- modo_notificacion_asistencia (varchar)
-- hora_disparo_notificacion (varchar)
```

---

## Configuration

### Environment Variables Needed

```env
# WhatsApp Business API
WHATSAPP_API_URL=https://graph.facebook.com/v17.0
WHATSAPP_TOKEN=your_access_token
WHATSAPP_PHONE_ID=your_phone_number_id

# Notification Provider
NOTIFICATION_PROVIDER=WHATSAPP  # or CONSOLE for dev

# Optional: SMS Provider (future)
SMS_PROVIDER=
SMS_API_KEY=
```

---

## Testing Strategy

### Unit Tests
- [ ] Adapter send methods
- [ ] Template rendering
- [ ] Queue processing logic
- [ ] Error handling scenarios

### Integration Tests
- [ ] Full notification flow (attendance → notification)
- [ ] Manual trigger endpoint
- [ ] Configuration update endpoint
- [ ] Cron job execution

### E2E Tests
- [ ] Create attendance → receive notification
- [ ] Update settings → verify behavior change
- [ ] Test each notification mode
- [ ] Test phone number validation

---

## Security Considerations

1. **API Keys**: Store in environment variables, never commit
2. **Phone Numbers**: Validate format before sending
3. **Rate Limiting**: Prevent abuse of manual trigger
4. **Data Privacy**: GDPR compliance for guardian data
5. **Opt-out**: Respect `aceptaNotificaciones` flag

---

## Monitoring & Observability

### Metrics to Track
- Notification send success rate
- Average delivery time
- Queue size
- Failed notifications count
- Cost per institution per month

### Logs to Capture
- All notification attempts (success/failure)
- Configuration changes
- Manual trigger events
- Cron job executions

---

## Next Steps

1. **Start with WhatsApp Integration**: Get real API credentials
2. **Build Settings UI**: Allow institutions to configure
3. **Test thoroughly**: Use Console adapter first, then WhatsApp
4. **Deploy gradually**: Start with one institution as pilot
5. **Monitor closely**: Watch for errors and performance issues

---

## Resources

- [Meta WhatsApp Business API Docs](https://developers.facebook.com/docs/whatsapp/business-management-api)
- [Notification Templates Best Practices](https://developers.facebook.com/docs/whatsapp/message-templates)
- [Rate Limits and Quotas](https://developers.facebook.com/docs/graph-api/overview/rate-limiting)

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2025-11-28 | Use existing Adapter Pattern | Already implemented, avoid duplication |
| 2025-11-28 | No schema changes needed | All fields already present in database |
| 2025-11-28 | Prioritize WhatsApp over SMS | More popular in target market |

---

**Author**: GitHub Copilot CLI
**Last Updated**: 2025-11-28
