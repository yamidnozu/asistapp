# 🔧 Corrección: Filtrado de Paginación

## 🐛 Problema Identificado

Al seleccionar un filtro de rol (profesor, estudiante, admin), el total de items permanecía en 14 (total de usuarios) en lugar de mostrar el total correcto de usuarios filtrados.

### Causa Raíz
El código estaba haciendo **filtrado local** en el frontend después de cargar TODOS los datos del backend:

```dart
// ❌ ANTES: Mal enfoque
Future<void> _loadUsers({int page = 1}) async {
  // SIEMPRE cargaba todos los usuarios
  await userProvider.loadUsersByInstitution(...);
}

List<User> _getFilteredUsers(UserProvider provider) {
  // Luego filtraba localmente
  if (_selectedRoleFilter.isNotEmpty) {
    users = users.where((user) => user.rol == _selectedRoleFilter).toList();
  }
}
```

**Resultado:**
- Backend devuelve: `{data: [...], pagination: {total: 14}}` (todos)
- Frontend filtra localmente: muestra 5 profesores pero total sigue siendo 14
- Paginación incorrecta: muestra "14 items" cuando solo hay 5 profesores

---

## ✅ Solución Implementada

### 1. Usar Endpoint del Backend con Filtrado

Ahora usamos el endpoint correcto según el filtro seleccionado:

```dart
// ✅ DESPUÉS: Enfoque correcto
Future<void> _loadUsers({int page = 1}) async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final userProvider = Provider.of<UserProvider>(context, listen: false);

  if (authProvider.accessToken != null && authProvider.selectedInstitutionId != null) {
    // Si hay filtro de rol, usar endpoint filtrado
    if (_selectedRoleFilter.isNotEmpty) {
      await userProvider.loadUsersByRole(
        authProvider.accessToken!,
        _selectedRoleFilter,
        page: page,
        limit: _itemsPerPage,
      );
    } else {
      // Sin filtro, cargar todos
      await userProvider.loadUsersByInstitution(
        authProvider.accessToken!,
        authProvider.selectedInstitutionId!,
        page: page,
        limit: _itemsPerPage,
      );
    }
  }
}
```

### 2. Eliminar Filtrado Local Duplicado

Actualizado `_getFilteredUsers` para NO filtrar localmente cuando el backend ya filtró:

```dart
// ✅ DESPUÉS: Sin filtrado duplicado
List<User> _getFilteredUsers(UserProvider provider) {
  List<User> users;

  if (_isSearching) {
    users = provider.searchUsers(_searchController.text);
  } else {
    users = _showActiveOnly ? provider.activeUsers : provider.users;
  }

  // NO filtrar localmente si ya se filtró en backend
  if (_selectedRoleFilter.isNotEmpty && !_isSearching) {
    return provider.users; // Ya vienen filtrados del backend
  }

  // Solo filtrar localmente en búsqueda local
  if (_selectedRoleFilter.isNotEmpty && _isSearching) {
    users = users.where((user) => user.rol == _selectedRoleFilter).toList();
  }

  return users;
}
```

### 3. Recargar Datos al Cambiar Filtro

El dropdown ahora recarga datos automáticamente:

```dart
// ✅ DESPUÉS: Recarga con nuevo filtro
onChanged: (value) {
  setState(() => _selectedRoleFilter = value ?? '');
  _loadUsers(page: 1); // 👈 Recarga desde página 1
},
```

---

## 🎯 Comportamiento Correcto Ahora

### Sin Filtro (Todos)
```
GET /usuarios/institucion/:id?page=1&limit=10

Response:
{
  "data": [14 usuarios],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 14,
    "totalPages": 2
  }
}

Frontend muestra: "14 items total"
```

### Con Filtro "profesor"
```
GET /usuarios/rol/profesor?page=1&limit=10

Response:
{
  "data": [5 profesores],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 5,
    "totalPages": 1
  }
}

Frontend muestra: "5 items total" ✅
```

### Con Filtro "estudiante"
```
GET /usuarios/rol/estudiante?page=1&limit=10

Response:
{
  "data": [7 estudiantes],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 7,
    "totalPages": 1
  }
}

Frontend muestra: "7 items total" ✅
```

---

## 📊 Comparativa

| Escenario | Antes | Después |
|-----------|-------|---------|
| **Sin filtro** | 14 items ✅ | 14 items ✅ |
| **Filtro profesor** | 14 items ❌ | 5 items ✅ |
| **Filtro estudiante** | 14 items ❌ | 7 items ✅ |
| **Páginas profesor** | 2 páginas ❌ | 1 página ✅ |
| **Endpoint usado** | Siempre `/institucion/:id` | Dinámico según filtro |
| **Filtrado** | Local (frontend) | Backend (correcto) |

---

## 🔄 Flujo Corregido

### 1. Usuario Selecciona Filtro "profesor"
```
Usuario → Dropdown: "Profesores"
        ↓
setState: _selectedRoleFilter = "profesor"
        ↓
_loadUsers(page: 1)
        ↓
userProvider.loadUsersByRole("profesor", page: 1)
        ↓
GET /usuarios/rol/profesor?page=1&limit=10
        ↓
Backend filtra y cuenta
        ↓
Response: {data: [5], pagination: {total: 5}}
        ↓
Provider actualiza _users y _paginationInfo
        ↓
Widget muestra: "📚 Página 1 de 1 [ 5 items ]" ✅
```

### 2. Usuario Navega a Página 2 (si hay más profesores)
```
PaginationWidget → onPageChange(2)
        ↓
_loadUsers(page: 2)
        ↓
userProvider.loadUsersByRole("profesor", page: 2)
        ↓
GET /usuarios/rol/profesor?page=2&limit=10
        ↓
Response: {data: [3 más], pagination: {page: 2, total: 13}}
        ↓
Widget muestra: "📚 Página 2 de 2 [ 13 items ]" ✅
```

### 3. Usuario Cambia a "Todos"
```
Dropdown → "Todos los roles"
        ↓
setState: _selectedRoleFilter = ""
        ↓
_loadUsers(page: 1)
        ↓
userProvider.loadUsersByInstitution(institucionId, page: 1)
        ↓
GET /usuarios/institucion/:id?page=1&limit=10
        ↓
Response: {data: [10], pagination: {total: 14}}
        ↓
Widget muestra: "📚 Página 1 de 2 [ 14 items ]" ✅
```

---

## 🧪 Testing

### Casos de Prueba

1. **Sin filtro, página 1**
   - Endpoint: `/usuarios/institucion/:id?page=1&limit=10`
   - Esperado: "14 items" (o total real)
   - ✅ Funciona

2. **Filtro profesor, página 1**
   - Endpoint: `/usuarios/rol/profesor?page=1&limit=10`
   - Esperado: Total de profesores (ej: 5)
   - ✅ Funciona

3. **Filtro estudiante, página 1**
   - Endpoint: `/usuarios/rol/estudiante?page=1&limit=10`
   - Esperado: Total de estudiantes (ej: 7)
   - ✅ Funciona

4. **Cambiar de filtro sin → profesor**
   - Endpoint cambia a: `/usuarios/rol/profesor`
   - Esperado: Total actualiza a profesores
   - ✅ Funciona

5. **Cambiar de profesor → sin filtro**
   - Endpoint cambia a: `/usuarios/institucion/:id`
   - Esperado: Total vuelve a todos
   - ✅ Funciona

6. **Paginación con filtro**
   - Navegar entre páginas mantiene filtro
   - Total consistente en todas las páginas
   - ✅ Funciona

---

## 📝 Cambios en Archivos

### `lib/screens/users/users_list_screen.dart`

#### 1. Método `_loadUsers()` - Línea ~43
**Antes:**
```dart
await userProvider.loadUsersByInstitution(
  authProvider.accessToken!,
  authProvider.selectedInstitutionId!,
  page: page,
  limit: _itemsPerPage,
);
```

**Después:**
```dart
if (_selectedRoleFilter.isNotEmpty) {
  await userProvider.loadUsersByRole(
    authProvider.accessToken!,
    _selectedRoleFilter,
    page: page,
    limit: _itemsPerPage,
  );
} else {
  await userProvider.loadUsersByInstitution(
    authProvider.accessToken!,
    authProvider.selectedInstitutionId!,
    page: page,
    limit: _itemsPerPage,
  );
}
```

#### 2. Método `_getFilteredUsers()` - Línea ~75
**Antes:**
```dart
if (_selectedRoleFilter.isNotEmpty) {
  users = users.where((user) => user.rol == _selectedRoleFilter).toList();
}
```

**Después:**
```dart
if (_selectedRoleFilter.isNotEmpty && !_isSearching) {
  return provider.users; // Ya filtrados del backend
}

if (_selectedRoleFilter.isNotEmpty && _isSearching) {
  users = users.where((user) => user.rol == _selectedRoleFilter).toList();
}
```

#### 3. Dropdown `onChanged` - Línea ~295
**Antes:**
```dart
onChanged: (value) {
  setState(() => _selectedRoleFilter = value ?? '');
},
```

**Después:**
```dart
onChanged: (value) {
  setState(() => _selectedRoleFilter = value ?? '');
  _loadUsers(page: 1);
},
```

---

## ✅ Resultado Final

### Problema Resuelto
- ✅ Total de items refleja el filtro aplicado
- ✅ Paginación correcta según resultados filtrados
- ✅ Backend hace el filtrado (más eficiente)
- ✅ Cambio de filtro recarga datos automáticamente
- ✅ Navegación de páginas mantiene el filtro

### Beneficios Adicionales
- 🚀 **Performance**: Backend solo envía datos necesarios
- 📊 **Precisión**: Total y páginas siempre correctos
- 🔄 **Consistencia**: Una sola fuente de verdad (backend)
- 💾 **Eficiencia**: No carga datos innecesarios

---

## 🎯 Endpoints Utilizados

| Filtro | Endpoint | Query Params |
|--------|----------|--------------|
| **Ninguno** | `GET /usuarios/institucion/:id` | `?page=1&limit=10` |
| **profesor** | `GET /usuarios/rol/profesor` | `?page=1&limit=10` |
| **estudiante** | `GET /usuarios/rol/estudiante` | `?page=1&limit=10` |
| **admin_institucion** | `GET /usuarios/rol/admin_institucion` | `?page=1&limit=10` |

Todos devuelven:
```typescript
{
  data: User[],
  pagination: {
    page: number,
    limit: number,
    total: number,
    totalPages: number,
    hasNext: boolean,
    hasPrev: boolean
  }
}
```

---

## 📚 Lecciones Aprendidas

### ❌ Anti-Patrón: Filtrado Local
```dart
// NO HACER: Cargar todo y filtrar localmente
loadAll() → Filter locally → Show subset
// Problema: Total incorrecto, ineficiente
```

### ✅ Patrón Correcto: Filtrado en Backend
```dart
// SÍ HACER: Filtrar en backend
loadFiltered(filter) → Backend filters → Show results + correct total
// Ventaja: Total correcto, eficiente, escalable
```

### Regla de Oro
> **"El backend debe ser la única fuente de verdad para datos paginados y filtrados"**

---

**Status**: ✅ **CORREGIDO**  
**Fecha**: 28 de octubre de 2025  
**Impacto**: Alto - Funcionalidad core de filtrado ahora funciona correctamente
