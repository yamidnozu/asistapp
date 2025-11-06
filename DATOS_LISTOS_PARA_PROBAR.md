# 🎯 Datos Listos para Probar - QR Scanner

## Fecha: 5 de noviembre de 2025

## ✅ Base de Datos Limpia y Sincronizada

Se ejecutó exitosamente:
1. ✅ `prisma db push` - Schema sincronizado con la base de datos
2. ✅ `prisma generate` - Cliente Prisma actualizado
3. ✅ `seed.ts` - 26 usuarios, 4 grupos, 63 horarios, 18 asistencias históricas

---

## 👨‍🏫 Profesor para Probar

### Juan Pérez (Matemáticas, Español, Ciencias, etc.)
```
Email: juan.perez@sanjose.edu
Password: Prof123!
Institución: Colegio San José
Materias: Matemáticas, Español, Ciencias Sociales, Informática, Educación Física
Grupos: 10-A, 11-B, 9-C
```

**Horarios de Hoy (Martes):**
- 07:00-08:00: Matemáticas con 10-A
- 08:00-09:00: Español con 10-A
- 09:00-10:00: Ciencias Sociales con 10-A
- 13:00-14:00: Informática con 11-B
- 14:00-15:00: Educación Física con 11-B

---

## 👨‍🎓 Estudiantes del Grupo 10-A (para escanear QR)

### 1. Ana Martínez
```
Código QR: QR-EST-001
Email: ana.martinez@estudiantes.com
Password: Est123!
```

### 2. Carlos López
```
Código QR: QR-EST-002
Email: carlos.lopez@estudiantes.com
Password: Est123!
```

### 3. Isabella González
```
Código QR: QR-EST-003
Email: isabella.gonzalez@estudiantes.com
Password: Est123!
```

### 4. Sebastián Torres
```
Código QR: QR-EST-004
Email: sebastian.torres@estudiantes.com
Password: Est123!
```

### 5. María Fernández
```
Código QR: QR-EST-005
Email: maria.fernandez@estudiantes.com
Password: Est123!
```

### 6. Juan Ramírez
```
Código QR: QR-EST-006
Email: juan.ramirez@estudiantes.com
Password: Est123!
```

---

## 📱 Cómo Probar el QR Scanner

### Paso 1: Generar Código QR de Estudiante

**Opción A: Desde la App (como estudiante)**
1. Login en la app con credenciales de estudiante (ej: `ana.martinez@estudiantes.com` / `Est123!`)
2. Ir a "Mi Código QR" (menú lateral o perfil)
3. Captura de pantalla del QR
4. Logout

**Opción B: Generar QR Online**
1. Ir a https://www.qr-code-generator.com/
2. Tipo: "Text"
3. Contenido: `QR-EST-001` (o cualquier otro código de la lista)
4. Generar y guardar imagen

---

### Paso 2: Escanear como Profesor

1. **Login como profesor**
   ```
   Email: juan.perez@sanjose.edu
   Password: Prof123!
   ```

2. **Ver las clases de hoy**
   - Deberías ver las 5 clases listadas arriba
   - Selecciona "Matemáticas con 10-A (07:00-08:00)"

3. **Ver lista de estudiantes**
   - Deberías ver los 6 estudiantes del grupo 10-A
   - Todos aparecen como "SIN REGISTRO" (fondo gris)

4. **Escanear QR**
   - Presiona el botón FAB "Escanear QR" (esquina inferior derecha)
   - Apunta la cámara al código QR de Ana Martínez (`QR-EST-001`)
   - **Resultado esperado:** ✅ "¡Asistencia registrada exitosamente!"
   - El mensaje debe aparecer en la **parte superior** (no tapa el botón)
   - La cámara debe regresar a la pantalla anterior automáticamente

5. **Verificar el registro**
   - Ana Martínez ahora debe aparecer con check verde ✅
   - Estado: "PRESENTE"
   - Su card debe tener fondo verde claro

---

### Paso 3: Probar Escaneos Duplicados

1. **Volver a escanear el MISMO QR** (Ana Martínez - `QR-EST-001`)
2. **Resultado esperado:** 
   - ❌ Error 400: "El estudiante ya tiene registrada su asistencia para esta clase hoy"
   - El mensaje aparece en la parte superior con ícono rojo
   - La cámara se **reinicia automáticamente** (NO se queda gris)
   - Después de 2 segundos, puedes volver a escanear

3. **Escanear otro estudiante** (Carlos López - `QR-EST-002`)
4. **Resultado esperado:**
   - ✅ Debe registrar exitosamente (porque es diferente estudiante)

---

### Paso 4: Probar Escaneos Rápidos (Cooldown)

1. **Escanear un QR nuevo** (Isabella González - `QR-EST-003`)
2. **Inmediatamente** (< 500ms) intentar escanear otro código
3. **Resultado esperado:**
   - El segundo escaneo debe ser **ignorado**
   - En los logs debe aparecer: "⚠️ Escaneo muy rápido, ignorando"
   - Solo se procesa el primer código

---

### Paso 5: Probar Registro Manual (Doble Toque)

1. **Ver la lista de estudiantes**
2. **Primer toque** en un estudiante sin registro (ej: Sebastián Torres)
   - ✅ El card se marca en amarillo
   - ✅ Aparece mensaje: "Toca de nuevo para confirmar"
3. **Segundo toque** en el mismo estudiante
   - ✅ Se registra la asistencia
   - ✅ Mensaje en la parte superior: "✓ Sebastián Torres marcado como presente"
   - ✅ El card cambia a verde con check

---

## 🐛 Errores Esperados y Sus Mensajes

### ✅ Estudiante Ya Registrado
- **Código:** 400
- **Mensaje:** "El estudiante ya tiene registrada su asistencia para esta clase hoy"
- **Comportamiento:** Cámara se reinicia, puede escanear otro código

### ✅ Estudiante No Pertenece al Grupo
- **Código:** 403  
- **Mensaje:** "El estudiante no pertenece al grupo de esta clase"
- **Comportamiento:** Cámara se reinicia, puede escanear otro código

### ✅ Código QR Inválido
- **Código:** 404
- **Mensaje:** "Estudiante con el código QR proporcionado no encontrado"
- **Comportamiento:** Cámara se reinicia, puede escanear otro código

---

## 📊 Verificaciones Importantes

### Verificar Una Sola Petición HTTP

**En los logs de Flutter:**
```
I/flutter (xxxxx): POST /asistencias/registrar - Status: 201
```
- ✅ Debe aparecer **UNA SOLA VEZ** por cada escaneo
- ❌ Si aparece múltiples veces = BUG no corregido

**En los logs del backend:**
```bash
docker compose logs -f backend
```
- ✅ Solo debe procesar **UNA** petición por escaneo

---

### Verificar Posición de SnackBar

- ✅ Los mensajes deben aparecer en la **parte superior**
- ✅ El botón FAB debe estar **siempre visible**
- ❌ Si el mensaje tapa el botón = BUG no corregido

---

### Verificar Reinicio de Cámara

Después de cualquier error:
- ✅ La cámara debe **volver a funcionar**
- ✅ Debe poder escanear otro código
- ❌ Si la pantalla queda gris/cartón = BUG no corregido

---

## 🔧 Comandos Útiles

### Ver logs del backend
```bash
docker compose logs -f backend
```

### Ver logs de Flutter en tiempo real
```bash
flutter run --verbose
```

### Abrir Prisma Studio (ver datos)
```bash
docker compose exec backend npx prisma studio
```

### Limpiar y volver a seed
```bash
docker compose exec backend npx prisma db push --accept-data-loss
docker compose exec backend npx tsx prisma/seed.ts
```

---

## 📝 Checklist de Testing

### QR Scanner
- [ ] Escanea un código QR correctamente
- [ ] Solo hace UNA petición HTTP por escaneo
- [ ] Muestra mensaje de éxito en la parte superior
- [ ] El botón FAB permanece visible
- [ ] Vuelve a la pantalla anterior automáticamente

### Escaneos Duplicados
- [ ] Muestra error 400 al escanear el mismo código dos veces
- [ ] El mensaje de error es claro y descriptivo
- [ ] La cámara se reinicia automáticamente
- [ ] Puede escanear otro código después del error

### Cooldown
- [ ] Ignora escaneos más rápidos que 500ms
- [ ] Muestra mensaje de debug en los logs

### Registro Manual (Doble Toque)
- [ ] Primer toque marca en amarillo
- [ ] Segundo toque registra asistencia
- [ ] Tocar fuera desmarca la selección
- [ ] Mensaje aparece en la parte superior

---

## 🎯 Casos de Prueba Recomendados

### Test 1: Flujo Completo Exitoso
1. Login como profesor
2. Seleccionar clase
3. Escanear QR de Ana Martínez
4. Verificar registro exitoso
5. Escanear QR de Carlos López
6. Verificar segundo registro exitoso

**Resultado esperado:** ✅ 2 estudiantes marcados como PRESENTE

---

### Test 2: Manejo de Errores
1. Escanear QR de Ana Martínez (ya registrado)
2. Ver error 400 con mensaje claro
3. Escanear QR de Isabella González (nuevo)
4. Verificar registro exitoso

**Resultado esperado:** ✅ Error manejado correctamente, siguiente escaneo funciona

---

### Test 3: Combinación QR + Manual
1. Escanear QR de Ana Martínez
2. Usar doble toque para registrar a Sebastián Torres
3. Escanear QR de Carlos López
4. Usar doble toque para registrar a María Fernández

**Resultado esperado:** ✅ 4 estudiantes registrados, 2 con QR y 2 manual

---

## 🚀 ¡Listo para Probar!

Todos los datos están cargados y listos. La base de datos está sincronizada con las últimas mejoras de código.

**Próximos pasos:**
1. ✅ Ejecuta `flutter run` en tu dispositivo Android
2. ✅ Login como `juan.perez@sanjose.edu` / `Prof123!`
3. ✅ Selecciona una clase y comienza a escanear códigos QR
4. ✅ Verifica que todo funciona como se describe arriba

**Si encuentras algún problema:**
- Revisa los logs de Flutter: `flutter run --verbose`
- Revisa los logs del backend: `docker compose logs -f backend`
- Verifica los datos en Prisma Studio: `docker compose exec backend npx prisma studio`

¡Buena suerte con las pruebas! 🎉
