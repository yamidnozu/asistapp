# Estrategia de Recuperación de Estado de la Aplicación

## 📋 Descripción General

Sistema optimizado de persistencia y recuperación de estado que permite a la aplicación:
- **Recordar la pantalla** en la que estaba el usuario
- **Recuperar datos cargados** de forma eficiente
- **Limpiar automáticamente** estados obsoletos
- **Mantener navegación** incluso después de cerrar/abrir la app

## 🏗️ Arquitectura Implementada

### Componentes Principales

#### 1. **NavigationStateProvider** (`lib/providers/navigation_state_provider.dart`)
- Guarda y recupera el estado de navegación
- Verifica validez temporal (30 minutos por defecto)
- Limpia estados obsoletos automáticamente
- Persiste en SharedPreferences

**Métodos clave:**
```dart
saveNavigationState(String route, {Map<String, dynamic>? arguments})
clearNavigationState()
hasValidState() // Verifica si el estado es recuperable
refreshStateTimestamp() // Mantiene el estado activo
```

#### 2. **AuthProvider Mejorado** (`lib/providers/auth_provider.dart`)
Nuevos métodos para gestión optimizada:

```dart
clearHeavyData() // Limpia instituciones pero mantiene sesión
clearTemporaryData() // Limpia datos temporales
recoverFullState() // Recupera estado completo al volver
```

#### 3. **AppRoutes** (`lib/utils/app_routes.dart`)
Centraliza todas las rutas de la aplicación:
- Rutas tipadas (no más strings mágicos)
- Métodos helper para obtener dashboards por rol
- Verificación de autenticación requerida

#### 4. **LifecycleAwareWrapper Mejorado** (`lib/widgets/app_wrappers.dart`)
Maneja el ciclo de vida completo:

```dart
AppLifecycleState.resumed: 
  → Recupera estado completo
  → Valida estado de navegación
  → Limpia si es obsoleto

AppLifecycleState.paused:
  → Guarda timestamp actualizado
  → Prepara para background
```

#### 5. **NavigationStateMixin** (`lib/widgets/navigation_state_mixin.dart`)
Mixin opcional para StatefulWidgets que necesiten guardar estado automáticamente.

## 🔄 Flujo de Recuperación de Estado

### Escenario 1: Usuario vuelve a la app (< 30 min)
```
1. App resumed
2. LifecycleAwareWrapper detecta cambio
3. AuthProvider.recoverFullState() → Carga instituciones
4. NavigationStateProvider.hasValidState() → true
5. AuthWrapper restaura pantalla guardada
6. Usuario ve exactamente donde estaba ✅
```

### Escenario 2: Usuario vuelve después de mucho tiempo (> 30 min)
```
1. App resumed
2. NavigationStateProvider.hasValidState() → false
3. clearNavigationState() limpia estado obsoleto
4. AuthWrapper navega según rol del usuario
5. Estado limpio, pero sesión mantiene ✅
```

### Escenario 3: Usuario cierra la app completamente
```
1. App detached
2. Estado guardado en SharedPreferences
3. Usuario reabre app (días después)
4. Si token válido → recupera sesión
5. Si estado < 30 min → restaura navegación
6. Si no → dashboard por defecto según rol ✅
```

## 💾 Datos Persistidos

### SharedPreferences guarda:
```json
{
  "accessToken": "...",
  "refreshToken": "...",
  "user": {...},
  "selectedInstitutionId": "...",
  "navigationState": {
    "currentRoute": "/teacher-dashboard",
    "routeArguments": {...},
    "lastStateUpdate": "2025-10-24T10:30:00Z"
  }
}
```

## 🎯 Uso en Dashboards

### Opción 1: Automático (ya implementado)
El `AuthWrapper` guarda automáticamente la ruta cuando navegas a un dashboard.

### Opción 2: Manual con Mixin (para StatefulWidgets)
```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> 
    with NavigationStateMixin {
  
  @override
  String get currentRoute => AppRoutes.myCustomRoute;
  
  @override
  Map<String, dynamic>? get routeArguments => {
    'selectedTab': _currentTab,
    'scrollPosition': _scrollController.offset,
  };
  
  void _onTabChanged(int tab) {
    setState(() => _currentTab = tab);
    updateNavigationState(arguments: {
      'selectedTab': tab,
    });
  }
}
```

### Opción 3: Wrapper para StatelessWidgets
```dart
NavigationStateWrapper(
  route: AppRoutes.teacherDashboard,
  arguments: {'section': 'attendance'},
  child: TeacherDashboard(),
)
```

## ⚙️ Configuración

### Cambiar tiempo de validez del estado:
En `navigation_state_provider.dart`:
```dart
static const int maxStateAgeMinutes = 30; // Cambiar según necesidad
```

### Agregar nuevas rutas:
En `app_routes.dart`:
```dart
static const String myNewRoute = '/my-new-route';
```

Luego en `AuthWrapper._getScreenForRoute()`:
```dart
case AppRoutes.myNewRoute:
  return const MyNewScreen();
```

## 🔒 Seguridad y Validación

✅ **Validación temporal**: Estados > 30 min se descartan  
✅ **Validación de autenticación**: Rutas protegidas verifican token  
✅ **Validación de institución**: Si institución guardada no existe, se limpia  
✅ **Fallback seguro**: Si ruta no válida, navega a dashboard por rol  

## 📊 Optimizaciones Aplicadas

### Limpieza Inteligente
- **clearTemporaryData()**: Limpia solo datos que "pesan" (instituciones, listas grandes)
- **clearHeavyData()**: Limpia específicamente datos grandes
- **recoverFullState()**: Recupera solo lo necesario

### Persistencia Selectiva
- Token/usuario: Siempre persistido
- Navegación: Persistido con validez temporal
- Datos pesados: Solo en memoria, se recargan al volver

### Rendimiento
- Datos se cargan bajo demanda
- Estados antiguos se limpian automáticamente
- Sin overhead innecesario en memoria

## 🚀 Beneficios

1. **UX Mejorado**: Usuario vuelve donde estaba
2. **Memoria Optimizada**: Solo guarda lo necesario
3. **Seguridad**: Estados obsoletos se descartan
4. **Escalable**: Fácil agregar nuevas rutas/estados
5. **Mantenible**: Lógica centralizada
6. **Type-safe**: Rutas con constantes tipadas

## 📝 Próximos Pasos (Opcional)

- [x] Persistir scroll positions ✅
- [ ] Guardar estados de formularios
- [ ] Sincronizar con backend (estado en la nube)
- [x] Implementar deep linking ✅
- [ ] Analytics de navegación

## 🔗 Deep Linking y Scroll

✅ **Sistema completo implementado**. Ver documentación detallada en:
- `DEEP_LINKING_GUIDE.md` - Guía completa de deep linking

### Quick Start

**Deep Links funcionando:**
```
https://asistapp.com/teacher-dashboard
asistapp://app/admin-dashboard
```

**Scroll Persistence automático:**
```dart
ScrollStateKeeper(
  routeKey: AppRoutes.teacherDashboard,
  builder: (context, controller) => SingleChildScrollView(
    controller: controller,
    child: YourContent(),
  ),
)
```

## 🐛 Debug

Para ver logs de estado:
```dart
debugPrint('Estado actual: ${navigationProvider.currentRoute}');
debugPrint('Estado válido: ${navigationProvider.hasValidState()}');
debugPrint('Última actualización: ${navigationProvider.lastStateUpdate}');
```

---

**Estrategia implementada**: Estado limpio con recuperación inteligente ✅
