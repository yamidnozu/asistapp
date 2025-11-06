# 📊 DATOS DE PRUEBA - AsistApp

> **Generado:** 5 de Noviembre de 2025  
> **Base de datos:** PostgreSQL (Docker - puerto 5433)  
> **Total registros creados:** 
> - ✅ 26 usuarios
> - ✅ 18 estudiantes
> - ✅ 3 instituciones
> - ✅ 4 grupos
> - ✅ 13 materias
> - ✅ 63 horarios (semana completa)
> - ✅ 18 registros de asistencia históricos

---

## 🔐 USUARIOS PARA LOGIN

### 👨‍💼 Super Admin
```
Email: superadmin@asistapp.com
Password: Admin123!
Rol: super_admin
```

### 🏫 Administradores de Institución

#### Colegio San José
```
Email: admin@sanjose.edu
Password: SanJose123!
Rol: admin_institucion
Institución: Colegio San José
```

#### IE Santander
```
Email: admin@santander.edu
Password: Santander123!
Rol: admin_institucion
Institución: IE Santander
```

#### Multi-Institución
```
Email: multiadmin@asistapp.com
Password: Multi123!
Rol: admin_institucion
Instituciones: Colegio San José + IE Santander
```

---

## 👨‍🏫 PROFESORES

### Colegio San José

#### Juan Pérez (Matemáticas, Español, etc.)
```
Email: juan.perez@sanjose.edu
Password: Prof123!
Materias: Matemáticas, Español, Ciencias Sociales, Informática, Educación Física
Grupos: 10-A, 11-B, 9-C
```

#### Laura Gómez (Física, Química, Biología)
```
Email: laura.gomez@sanjose.edu
Password: Prof123!
Materias: Física, Química, Biología, Inglés, Educación Artística
Grupos: 10-A, 11-B, 9-C
```

#### Profe Sin Clases (Para testing)
```
Email: vacio.profe@sanjose.edu
Password: Prof123!
Materias: Ninguna
Grupos: Ninguno
```

### IE Santander

#### Carlos Díaz
```
Email: carlos.diaz@santander.edu
Password: Prof123!
Materias: Español, Inglés, Matemáticas
Grupos: 6-1
```

---

## 👨‍🎓 ESTUDIANTES

### Colegio San José - Grupo 10-A (6 estudiantes)

| Nombre | Email | Password | Identificación | Código QR | Responsable | Teléfono |
|--------|-------|----------|----------------|-----------|-------------|----------|
| Santiago Mendoza | santiago.mendoza@sanjose.edu | Est123! | 1001 | QR-SANTIAGO | Ana Mendoza | +573001234567 |
| Valentina Rojas | valentina.rojas@sanjose.edu | Est123! | 1002 | QR-VALENTINA | Carlos Rojas | +573001234568 |
| Lucas Martínez | lucas.martinez@sanjose.edu | Est123! | 1005 | QR-LUCAS | Diana Martínez | +573001234571 |
| Isabella López | isabella.lopez@sanjose.edu | Est123! | 1006 | QR-ISABELLA | Jorge López | +573001234572 |
| Sebastián García | sebastian.garcia@sanjose.edu | Est123! | 1007 | QR-SEBASTIAN | Marta García | +573001234573 |
| María Fernández | maria.fernandez@sanjose.edu | Est123! | 1008 | QR-MARIA | Luis Fernández | +573001234574 |

### Colegio San José - Grupo 11-B (5 estudiantes)

| Nombre | Email | Password | Identificación | Código QR | Responsable | Teléfono |
|--------|-------|----------|----------------|-----------|-------------|----------|
| Mateo Castro | mateo.castro@sanjose.edu | Est123! | 1003 | QR-MATEO | Patricia Castro | +573001234569 |
| Camila Ortiz | camila.ortiz@sanjose.edu | Est123! | 1004 | QR-CAMILA | Roberto Ortiz | +573001234570 |
| Diego Ramírez | diego.ramirez@sanjose.edu | Est123! | 1009 | QR-DIEGO | Sandra Ramírez | +573001234575 |
| Sofía Torres | sofia.torres@sanjose.edu | Est123! | 1010 | QR-SOFIA-T | Pedro Torres | +573001234576 |
| Andrés Moreno | andres.moreno@sanjose.edu | Est123! | 1011 | QR-ANDRES | Gloria Moreno | +573001234577 |

### Colegio San José - Grupo 9-C (4 estudiantes)

| Nombre | Email | Password | Identificación | Código QR | Responsable | Teléfono |
|--------|-------|----------|----------------|-----------|-------------|----------|
| Laura Sánchez | laura.sanchez@sanjose.edu | Est123! | 1012 | QR-LAURA | Miguel Sánchez | +573001234578 |
| Nicolás Vargas | nicolas.vargas@sanjose.edu | Est123! | 1013 | QR-NICOLAS | Carmen Vargas | +573001234579 |
| Mariana Cruz | mariana.cruz@sanjose.edu | Est123! | 1014 | QR-MARIANA | Ricardo Cruz | +573001234580 |
| Felipe Herrera | felipe.herrera@sanjose.edu | Est123! | 1015 | QR-FELIPE | Elena Herrera | +573001234581 |

### IE Santander - Grupo 6-1 (3 estudiantes)

| Nombre | Email | Password | Identificación | Código QR | Responsable | Teléfono |
|--------|-------|----------|----------------|-----------|-------------|----------|
| Sofía Núñez | sofia.nunez@santander.edu | Est123! | 2001 | QR-SOFIA | Antonio Núñez | +573002234567 |
| Daniel Ruiz | daniel.ruiz@santander.edu | Est123! | 2002 | QR-DANIEL | Isabel Ruiz | +573002234568 |
| Paula Méndez | paula.mendez@santander.edu | Est123! | 2003 | QR-PAULA | Fernando Méndez | +573002234569 |

---

## 📚 MATERIAS POR INSTITUCIÓN

### Colegio San José
1. Matemáticas (MAT-001)
2. Física (FIS-001)
3. Química (QUI-001)
4. Biología (BIO-001)
5. Español (ESP-001)
6. Inglés (ING-001)
7. Ciencias Sociales (SOC-001)
8. Educación Artística (ART-001)
9. Educación Física (EDF-001)
10. Informática (INF-001)

### IE Santander
1. Español (ESP-S001)
2. Inglés (ING-S001)
3. Matemáticas (MAT-S001)

---

## 📅 HORARIOS - COLEGIO SAN JOSÉ

### 📘 GRUPO 10-A (Décimo A)
**Estudiantes:** Santiago, Valentina, Lucas, Isabella, Sebastián, María

#### Lunes
- 07:00-08:00 | Matemáticas (Prof. Juan Pérez)
- 08:00-09:00 | Física (Prof. Laura Gómez)
- 09:00-10:00 | Español (Prof. Juan Pérez)
- 10:30-11:30 | Inglés (Prof. Laura Gómez)
- 11:30-12:30 | Ciencias Sociales (Prof. Juan Pérez)

#### Martes
- 07:00-08:00 | Química (Prof. Laura Gómez)
- 08:00-09:00 | Biología (Prof. Laura Gómez)
- 09:00-10:00 | Matemáticas (Prof. Juan Pérez)
- 10:30-11:30 | Informática (Prof. Juan Pérez)
- 11:30-12:30 | Educación Artística (Prof. Laura Gómez)

#### Miércoles
- 07:00-08:00 | Matemáticas (Prof. Juan Pérez)
- 08:00-09:00 | Física (Prof. Laura Gómez)
- 09:00-10:00 | Inglés (Prof. Laura Gómez)
- 10:30-11:30 | Educación Física (Prof. Juan Pérez)
- 11:30-12:30 | Español (Prof. Juan Pérez)

#### Jueves
- 07:00-08:00 | Química (Prof. Laura Gómez)
- 08:00-09:00 | Matemáticas (Prof. Juan Pérez)
- 09:00-10:00 | Ciencias Sociales (Prof. Juan Pérez)
- 10:30-11:30 | Biología (Prof. Laura Gómez)
- 11:30-12:30 | Informática (Prof. Juan Pérez)

#### Viernes
- 07:00-08:00 | Física (Prof. Laura Gómez)
- 08:00-09:00 | Inglés (Prof. Laura Gómez)
- 09:00-10:00 | Español (Prof. Juan Pérez)
- 10:30-11:30 | Educación Artística (Prof. Laura Gómez)
- 11:30-12:30 | Educación Física (Prof. Juan Pérez)

---

### 📗 GRUPO 11-B (Once B)
**Estudiantes:** Mateo, Camila, Diego, Sofía Torres, Andrés

#### Lunes
- 07:00-08:00 | Química (Prof. Laura Gómez)
- 08:00-09:00 | Matemáticas (Prof. Juan Pérez)
- 09:00-10:00 | Física (Prof. Laura Gómez)
- 10:30-11:30 | Español (Prof. Juan Pérez)

#### Martes
- 07:00-08:00 | Biología (Prof. Laura Gómez)
- 09:00-10:00 | Inglés (Prof. Laura Gómez)
- 10:30-11:30 | Ciencias Sociales (Prof. Juan Pérez)

#### Miércoles
- 07:00-08:00 | Matemáticas (Prof. Juan Pérez)
- 08:00-09:00 | Química (Prof. Laura Gómez)
- 09:00-10:00 | Informática (Prof. Juan Pérez)

#### Jueves
- 08:00-09:00 | Física (Prof. Laura Gómez)
- 09:00-10:00 | Educación Física (Prof. Juan Pérez)
- 10:30-11:30 | Educación Artística (Prof. Laura Gómez)

#### Viernes
- 07:00-08:00 | Inglés (Prof. Laura Gómez)
- 08:00-09:00 | Español (Prof. Juan Pérez)
- 09:00-10:00 | Biología (Prof. Laura Gómez)

---

### 📙 GRUPO 9-C (Noveno C)
**Estudiantes:** Laura Sánchez, Nicolás, Mariana, Felipe

#### Lunes
- 07:00-08:00 | Matemáticas (Prof. Juan Pérez)
- 08:00-09:00 | Español (Prof. Juan Pérez)
- 09:00-10:00 | Biología (Prof. Laura Gómez)

#### Martes
- 07:00-08:00 | Inglés (Prof. Laura Gómez)
- 08:00-09:00 | Ciencias Sociales (Prof. Juan Pérez)
- 10:30-11:30 | Educación Artística (Prof. Laura Gómez)

#### Miércoles
- 07:00-08:00 | Matemáticas (Prof. Juan Pérez)
- 09:00-10:00 | Informática (Prof. Juan Pérez)

#### Jueves
- 08:00-09:00 | Educación Física (Prof. Juan Pérez)
- 09:00-10:00 | Inglés (Prof. Laura Gómez)

#### Viernes
- 07:00-08:00 | Español (Prof. Juan Pérez)
- 08:00-09:00 | Biología (Prof. Laura Gómez)

---

## 📅 HORARIOS - IE SANTANDER

### 📕 GRUPO 6-1 (Sexto Uno)
**Estudiantes:** Sofía Núñez, Daniel, Paula

#### Lunes
- 07:00-08:00 | Matemáticas (Prof. Carlos Díaz)
- 08:00-09:00 | Español (Prof. Carlos Díaz)

#### Martes
- 09:00-10:00 | Inglés (Prof. Carlos Díaz)
- 10:30-11:30 | Matemáticas (Prof. Carlos Díaz)

#### Miércoles
- 07:00-08:00 | Español (Prof. Carlos Díaz)
- 08:00-09:00 | Inglés (Prof. Carlos Díaz)

#### Jueves
- 09:00-10:00 | Matemáticas (Prof. Carlos Díaz)
- 11:00-12:00 | Español (Prof. Carlos Díaz)

#### Viernes
- 08:00-09:00 | Inglés (Prof. Carlos Díaz)
- 11:00-12:00 | Matemáticas (Prof. Carlos Díaz)

---

## 📊 REGISTROS DE ASISTENCIA HISTÓRICOS

Se crearon **18 registros** de asistencia para días pasados (hace 3 días y hace 1 día) en el Grupo 10-A:

### Hace 3 días - Matemáticas (Lunes 7:00am)
- ✅ Santiago: PRESENTE (QR)
- ✅ Valentina: PRESENTE (QR)
- ⏰ Lucas: TARDANZA (Manual)
- ❌ Isabella: AUSENTE (Manual)
- ✅ Sebastián: PRESENTE (QR)
- ✅ María: PRESENTE (QR)

### Hace 1 día - Matemáticas (Lunes 7:00am)
- ✅ Santiago: PRESENTE (QR)
- ❌ Valentina: AUSENTE (Manual)
- ✅ Lucas: PRESENTE (QR)
- 📝 Isabella: JUSTIFICADO (Manual) - "Excusa médica presentada"
- ✅ Sebastián: PRESENTE (QR)
- ⏰ María: TARDANZA (Manual)

### Hace 3 días - Física (Lunes 8:00am)
- ✅ Santiago: PRESENTE (QR)
- ✅ Valentina: PRESENTE (QR)
- ✅ Lucas: PRESENTE (QR)
- ❌ Isabella: AUSENTE (Manual)
- ✅ Sebastián: PRESENTE (QR)
- ✅ María: PRESENTE (QR)

---

## 🧪 CASOS DE PRUEBA SUGERIDOS

### 1. **Login y Navegación**
- ✅ Login como profesor (Juan o Laura)
- ✅ Ver dashboard con clases del día
- ✅ Navegar a una clase específica
- ✅ Ver lista de estudiantes

### 2. **Registro Manual de Asistencia**
- ✅ Login como `juan.perez@sanjose.edu`
- ✅ Ir a "Matemáticas - 10-A - Lunes 7:00"
- ✅ Ver estudiantes sin registro (hoy)
- ✅ Click en botón "touch_app" de un estudiante
- ✅ Confirmar en dialog
- ✅ Verificar que lista se actualiza

### 3. **Ver QR del Estudiante**
- ✅ Login como estudiante (ej: `santiago.mendoza@sanjose.edu`)
- ✅ Navegar a "Mi Código QR"
- ✅ Verificar que muestra QR-SANTIAGO
- ✅ Ver datos: Santiago Mendoza, ID: 1001

### 4. **Historial de Asistencias**
- ✅ Login como profesor
- ✅ Ver clase con asistencias pasadas
- ✅ Verificar estados: PRESENTE, AUSENTE, TARDANZA, JUSTIFICADO
- ✅ Ver diferencia entre registros QR y MANUAL

### 5. **Múltiples Grupos**
- ✅ Login como `laura.gomez@sanjose.edu`
- ✅ Verificar que ve clases de 10-A, 11-B y 9-C
- ✅ Cambiar entre diferentes grupos
- ✅ Ver diferentes listas de estudiantes

### 6. **Horarios Completos**
- ✅ Verificar horarios de Lunes a Viernes
- ✅ Probar diferentes horas del día
- ✅ Verificar materias variadas

### 7. **Admin Multi-Institución**
- ✅ Login como `multiadmin@asistapp.com`
- ✅ Verificar acceso a Colegio San José
- ✅ Verificar acceso a IE Santander
- ✅ Cambiar entre instituciones

---

## 🔧 COMANDOS ÚTILES

### Recargar datos de prueba
```bash
cd backend
npm run prisma:seed:host
```

### Ver logs del backend
```bash
docker compose logs -f app
```

### Conectar a base de datos
```bash
docker compose exec db psql -U postgres -d asistapp
```

### Limpiar y recrear DB
```bash
docker compose down -v
docker compose up -d db
docker compose exec backend npx prisma db push
cd backend && npm run prisma:seed:host
```

---

## 📝 NOTAS IMPORTANTES

1. **Todas las contraseñas** de profesores y estudiantes son: `Prof123!` y `Est123!` respectivamente
2. **Día de la semana:** 1=Lunes, 2=Martes, 3=Miércoles, 4=Jueves, 5=Viernes
3. **Estados de asistencia:** PRESENTE, AUSENTE, TARDANZA, JUSTIFICADO
4. **Tipos de registro:** QR (código QR escaneado), MANUAL (marcado por profesor)
5. **Horarios:** Formato 24 horas sin segundos (ej: "07:00", "08:00")

---

## 🚀 PRÓXIMOS PASOS DE TESTING

1. ✅ **Registro Manual** - Probar endpoint POST /asistencias/registrar-manual
2. ✅ **QR Estudiante** - Verificar GET /estudiantes/me
3. ⏳ **Escaneo QR** - Implementar POST /asistencias/registrar-qr
4. ⏳ **Reportes** - Ver asistencias históricas por estudiante
5. ⏳ **Notificaciones** - Envío de WhatsApp a responsables

---

**¡Datos listos para pruebas completas! 🎉**
