# Arquitectura Estandarizada - AsistApp

## 📐 Estructura de Capas

```
┌──────────────────────────────────────┐
│         PRESENTACIÓN (UI)            │
│  Screens, Widgets, Components        │
└──────────────────────────────────────┘
                 ▼
┌──────────────────────────────────────┐
│    LÓGICA DE NEGOCIO (Providers)     │
│  AuthProvider, NavigationProvider    │
└──────────────────────────────────────┘
                 ▼
┌──────────────────────────────────────┐
│     SERVICIOS (Services)             │
│  AuthService, API Calls              │
└──────────────────────────────────────┘
                 ▼
┌──────────────────────────────────────┐
│    DATOS (Models, Storage)           │
│  SharedPreferences, Models           │
└──────────────────────────────────────┘
```

## 🎯 Responsabilidades por Capa

### 1. **main.dart** - Punto de entrada ✅
- Inicialización ordenada de servicios
- Configuración de providers
- Manejo del ciclo de vida de la app
- Configuración del router
- Limpieza de recursos

### 2. **app_router.dart** - Sistema de rutas ✅
- Configuración de GoRouter
- Middleware de autenticación
- Deep linking (web/Android)
- Persistencia de navegación
- Transiciones entre pantallas

### 3. **app_routes.dart** - Definición de rutas ✅
- Constantes de rutas (type-safe)
- Helpers de navegación
- Mapeo rol → dashboard
- Validaciones de rutas

### 4. **role_enum.dart** - Roles de usuario ✅
- Enum de roles (type-safe)
- Conversión string ↔ enum
- Helpers de permisos
- Nombres legibles

### 5. **role_guard.dart** - Control de acceso UI ✅
- Verificar rol del usuario
- Mostrar/ocultar widgets por rol
- Fallback opcional si no tiene permiso

### 6. **scroll_state_keeper.dart** - Persistencia de scroll ✅
- Guardar posición de scroll por ruta
- Restaurar automáticamente
- Persistir en storage

### 7. **navigation_state_mixin.dart** - Persistencia de navegación ✅
- Guardar estado de navegación
- Actualizar timestamp
- Integración con providers

## 📏 Estándares de Código

### Nomenclatura
```dart
// Clases: PascalCase
class MyAwesomeWidget extends StatelessWidget { }

// Métodos privados: _camelCase
Widget _buildMySection() { }

// Constantes: camelCase
static const String myRoute = '/my-route';
```

### Documentación
```dart
/// Descripción breve
/// 
/// Responsabilidades:
/// - Responsabilidad 1
/// - Responsabilidad 2
class MyClass { }
```

### Logs Descriptivos
```dart
debugPrint('🔄 Acción en progreso');
debugPrint('✅ Éxito');
debugPrint('❌ Error');
debugPrint('⚠️ Advertencia');
```

## ✅ Todo Estandarizado
- Main.dart con gestión de ciclo de vida
- Router con middleware y deep linking
- Roles con enums type-safe
- RoleGuard para control de acceso
- Scroll persistence automático
- Navegación con estado persistente

---

**Arquitectura limpia y escalable** ✅
