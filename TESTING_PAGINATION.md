# 🧪 Guía de Pruebas - Paginación en Flutter

## ✅ Checklist de Pruebas

### Prueba 1: Compilación Correcta
- [ ] `flutter analyze` - Sin errores críticos
- [ ] `flutter pub get` - Dependencias OK
- [ ] `flutter run` - App compila y abre

### Prueba 2: Visualización de Controles
**Ubicación**: Pantalla Gestión de Usuarios

- [ ] **Indicador de página visible**: "Página 1 de X (Y total)"
- [ ] **Botones de navegación visibles**: "⬅️ Anterior" y "➡️ Siguiente"
- [ ] **Selector de página visible**: Números 1, 2, 3, etc.
- [ ] **Espaciado correcto**: No superpone con lista de usuarios

### Prueba 3: Botones Anterior/Siguiente

**En Página 1 de 5**:
- [ ] Botón "Anterior" está DESHABILITADO (gris)
- [ ] Botón "Siguiente" está HABILITADO (azul)
- [ ] Hacer clic en "Siguiente"
  - [ ] Página cambia a 2
  - [ ] Indicador muestra "Página 2 de 5"
  - [ ] Nuevos usuarios cargan
  - [ ] Botón "Anterior" ahora HABILITADO

**En Página Intermedia (ej: 3 de 5)**:
- [ ] Ambos botones HABILITADOS
- [ ] Hacer clic en "Anterior"
  - [ ] Va a página 2
  - [ ] Usuarios actualizan correctamente

**En Última Página (5 de 5)**:
- [ ] Botón "Siguiente" DESHABILITADO
- [ ] Botón "Anterior" HABILITADO
- [ ] Hacer clic en "Anterior"
  - [ ] Va a página 4
  - [ ] Indicador actualiza

### Prueba 4: Selector de Página

**Hacer clic en botones de número**:
- [ ] Hacer clic en "3"
  - [ ] Va a página 3 directamente
  - [ ] Usuarios de página 3 cargan
  - [ ] Botón "3" resaltado en azul oscuro
  - [ ] Los demás números en azul claro

**Verificar rango de números mostrados**:
- [ ] Si 5+ páginas totales: muestra máximo 5 botones
- [ ] En página 1: muestra [1][2][3][4][5]
- [ ] En página 3: muestra [1][2][3][4][5]
- [ ] En última página: muestra últimos 5 números

### Prueba 5: Indicador de Página

- [ ] Formato correcto: "Página X de Y (Z total)"
  - X = página actual
  - Y = total de páginas
  - Z = total de registros
- [ ] Actualiza al cambiar página
- [ ] Total es consistente (no cambia al paginar)

### Prueba 6: Integración con Búsqueda y Filtros

**Con búsqueda**:
- [ ] Paginación funciona sobre resultados buscados
- [ ] Vuelve a página 1 al cambiar búsqueda
- [ ] Selector de página respeta rango

**Con filtro de rol**:
- [ ] Paginación funciona con filtro activo
- [ ] Total refleja el filtro
- [ ] Números de página ajustan al filtro

**Con filtro Activos/Todos**:
- [ ] Paginación respeta estado de filtro
- [ ] Cambiar filtro reinicia a página 1

### Prueba 7: Responsividad

**En pantalla grande (tablet/web)**:
- [ ] Todos los botones visibles en fila
- [ ] Sin scroll horizontal
- [ ] Bien espaciado

**En pantalla pequeña (móvil)**:
- [ ] Selector de página scrolleable horizontalmente
- [ ] Botones Anterior/Siguiente encima
- [ ] Indicador visible completamente

### Prueba 8: Edge Cases

**Si hay solo 1 página**:
- [ ] Controles de paginación NO se muestran
- [ ] No hay confusión del usuario

**Si hay exactamente 5 páginas**:
- [ ] Todos los números [1][2][3][4][5] visibles
- [ ] Sin necesidad de lógica de rango

**Si hay 100+ páginas**:
- [ ] Máximo 5 botones siempre visibles
- [ ] Scroll horizontal en selector
- [ ] Lógica de rango funciona correctamente

### Prueba 9: Performance

**Al cargar página 2, 3, 4...**:
- [ ] No hay lag o congelamiento
- [ ] UI responde inmediatamente
- [ ] Indicador de carga aparece si tarda > 1 segundo

**Cargar muchas páginas consecutivas**:
- [ ] App no consume excesiva memoria
- [ ] No hay crashes
- [ ] Datos son correctos en cada página

### Prueba 10: Datos Correctos

**Verificar en Página 1 de 5 (con limit=10)**:
- [ ] Muestra 10 usuarios (o menos si es última página)
- [ ] Total mostrado = real en backend
- [ ] Usuarios no se repiten entre páginas

**Verificar cambio a Página 2**:
- [ ] Nuevos usuarios (no los mismos de página 1)
- [ ] Total permanece igual
- [ ] IDs son diferentes

---

## 🧬 Escenarios de Prueba Detallados

### Escenario A: Usuario Nuevo

1. Abre app, va a "Gestión de Usuarios"
2. Ve lista con paginación abajo
3. Hace clic en "Siguiente"
4. **Resultado esperado**: Nueva página con nuevos usuarios

### Escenario B: Navegación Directa

1. En página 1 de 10
2. Hace clic en el número "7"
3. **Resultado esperado**: Va a página 7 directamente, mostrando usuarios correctos

### Escenario C: Búsqueda + Paginación

1. Busca "Juan" (5 resultados encontrados)
2. Muestra página 1 de 1 (solo 1 página con 5 resultados)
3. Controles de paginación se ocultan (porque totalPages = 1)
4. **Resultado esperado**: Sin confusión, solo muestra resultados

### Escenario D: Filtro + Paginación

1. Filtra por rol "Profesor" (45 profesores total, 5 páginas)
2. Muestra "Página 1 de 5 (45 total)"
3. Hace clic en siguiente
4. **Resultado esperado**: Nuevos 10 profesores cargan correctamente

### Escenario E: Cambio de Filtro

1. Está en página 3 de 5 (rol "Profesor")
2. Cambia a rol "Estudiante"
3. **Resultado esperado**: Vuelve a página 1 de X (donde X depende de estudiantes)

---

## 📱 Pruebas en Diferentes Dispositivos

### Android Emulator
- [ ] Compilar: `flutter run -d android-emulator`
- [ ] Ejecutar pruebas 1-10 completas
- [ ] Verificar scroll del selector de página

### iOS Simulator
- [ ] Compilar: `flutter run -d iphone-simulator`
- [ ] Ejecutar pruebas 1-10 completas
- [ ] Verificar gestos/swipe

### Windows Desktop
- [ ] Compilar: `flutter run -d windows`
- [ ] Pruebas 1-10 completas
- [ ] Verificar responsividad

### Web (Chrome)
- [ ] Compilar: `flutter run -d chrome`
- [ ] Pruebas 1-10 completas
- [ ] Verificar en distintos tamaños de ventana

---

## 🔍 Debugging

**Si algo no funciona**:

1. **Verificar que el backend está corriendo**:
   ```bash
   curl -X GET "http://localhost:3000/usuarios?page=1&limit=10" \
     -H "Authorization: Bearer YOUR_TOKEN"
   ```

2. **Ver logs de Flutter**:
   ```bash
   flutter run -v
   ```

3. **Verificar paginationInfo en Provider**:
   ```dart
   print('Pagination: ${userProvider.paginationInfo}');
   ```

4. **Verificar respuesta del API**:
   ```bash
   curl -s -X GET "http://localhost:3000/usuarios?page=2&limit=10" | jq '.pagination'
   ```

---

## ✅ Criterios de Éxito

- [ ] Todos los tests de Prueba 1-10 pasan
- [ ] No hay crashes al navegar
- [ ] Datos son consistentes y correctos
- [ ] UI es responsive en todos los dispositivos
- [ ] Performance es aceptable (< 1s por cambio de página)
- [ ] Integración con filtros/búsqueda funciona

---

## 📊 Resultado Esperado Final

```
Gestión de Usuarios
═══════════════════════════════════════
🔍 [Buscar...] 🎯 Filtros

📊 100 Total | 95 Activos | 30 Prof. | 70 Est.

┌─────────────────────────────────────┐
│ Juan Pérez (profesor)          ⋮   │
│ María García (estudiante)      ⋮   │
│ Carlos López (profesor)        ⋮   │
│ Ana Martínez (estudiante)      ⋮   │
│ Pedro Rodríguez (profesor)     ⋮   │
│ ... (5 más)                         │
└─────────────────────────────────────┘

Página 1 de 10 (100 total)
[⬅️ Anterior] [➡️ Siguiente]
[1] [2] [3] [4] [5]
═══════════════════════════════════════
```

---

## 🎬 Grabar Video de Prueba

Para documentar:
1. Abre app
2. Navega a usuarios
3. Hace clic en siguiente 3 veces
4. Hace clic en número "5"
5. Hace clic en anterior 2 veces
6. Verifica que indicador actualiza cada vez

Este video sirve como proof-of-concept de paginación funcional.
