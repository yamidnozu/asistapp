# Deep Linking y Scroll Position - Guía Completa

## 🔗 Deep Linking Implementado

### URLs Soportadas

#### 1. **Web (HTTPS/HTTP)**
```
https://asistapp.com/teacher-dashboard
https://asistapp.com/admin-dashboard
https://asistapp.com/student-dashboard
https://asistapp.com/super-admin-dashboard
```

#### 2. **Android (Custom Scheme)**
```
asistapp://app/teacher-dashboard
asistapp://app/admin-dashboard
asistapp://app/student-dashboard
```

#### 3. **Rutas Disponibles**
Todas las rutas definidas en `AppRoutes`:
- `/login` - Pantalla de inicio de sesión
- `/institution-selection` - Selección de institución
- `/super-admin-dashboard` - Dashboard super admin
- `/admin-dashboard` - Dashboard admin
- `/teacher-dashboard` - Dashboard profesor
- `/student-dashboard` - Dashboard estudiante
- `/home` - Dashboard genérico

## 🚀 Cómo Usar Deep Links

### Desde Terminal/CMD (Testing Android)
```bash
# Abrir dashboard de profesor
adb shell am start -a android.intent.action.VIEW \
  -d "asistapp://app/teacher-dashboard" com.asistapp

# Abrir con HTTPS
adb shell am start -a android.intent.action.VIEW \
  -d "https://asistapp.com/admin-dashboard" com.asistapp
```

### Desde Código (Compartir Link)
```dart
import 'package:url_launcher/url_launcher.dart';

// Compartir link del dashboard
final url = Uri.parse('https://asistapp.com/teacher-dashboard');
if (await canLaunchUrl(url)) {
  await launchUrl(url);
}
```

### Desde Web Browser
```
https://asistapp.com/teacher-dashboard
```

## 📜 Persistencia de Scroll

### Uso Automático con ScrollStateKeeper

#### Opción 1: Widget Wrapper (Stateless)
```dart
import '../widgets/scroll_state_keeper.dart';
import '../utils/app_routes.dart';

class MyDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScrollStateKeeper(
        routeKey: AppRoutes.myDashboard,
        keepScrollPosition: true,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController, // ← Automático
            child: Column(
              children: [
                // Tu contenido aquí
              ],
            ),
          );
        },
      ),
    );
  }
}
```

#### Opción 2: Mixin para StatefulWidget
```dart
import '../widgets/scroll_state_keeper.dart';
import '../utils/app_routes.dart';

class MyDashboard extends StatefulWidget {
  @override
  State<MyDashboard> createState() => _MyDashboardState();
}

class _MyDashboardState extends State<MyDashboard> 
    with ScrollStateMixin {
  
  @override
  String get scrollRouteKey => AppRoutes.myDashboard;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        controller: scrollController, // ← Del mixin
        child: Column(
          children: [
            // Tu contenido
          ],
        ),
      ),
    );
  }
}
```

### Gestión Manual (Advanced)
```dart
final scrollProvider = Provider.of<ScrollStateProvider>(context);

// Guardar posición
scrollProvider.saveScrollPosition('/my-route', 350.0);

// Obtener posición guardada
final position = scrollProvider.getScrollPosition('/my-route');

// Limpiar posición de una ruta
scrollProvider.clearScrollPosition('/my-route');

// Limpiar todas
scrollProvider.clearAllScrollPositions();
```

## 🏗️ Arquitectura del Sistema

### Flujo de Deep Link

```
1. Usuario recibe link: https://asistapp.com/teacher-dashboard
2. App se abre (o se activa si ya estaba abierta)
3. GoRouter intercepta la ruta
4. Verifica autenticación (redirect middleware)
5. Si está autenticado → Navega a TeacherDashboard
6. Si no → Redirige a /login
7. NavigationStateProvider guarda la ruta
8. ScrollStateKeeper restaura posición si existe
```

### Flujo de Scroll Persistence

```
1. Usuario scrollea en TeacherDashboard
2. ScrollController detecta cambio
3. ScrollStateProvider guarda posición (350.0)
4. Persiste en SharedPreferences
5. Usuario sale de la app
6. Usuario vuelve
7. ScrollStateKeeper restaura posición 350.0
8. Usuario ve exactamente donde estaba ✅
```

## 📱 Configuración por Plataforma

### Android (AndroidManifest.xml)

Ya configurado en `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Deep linking HTTPS -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    
    <data
        android:scheme="https"
        android:host="asistapp.com"
        android:pathPrefix="/" />
</intent-filter>

<!-- Deep linking Custom Scheme -->
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    
    <data
        android:scheme="asistapp"
        android:host="app" />
</intent-filter>
```

### Web

Automático con GoRouter. URLs se manejan directamente:
- `https://tudominio.com/teacher-dashboard`
- Router detecta la ruta y navega

### iOS (Futuro)

Para iOS, agregar en `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.asistapp</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>asistapp</string>
        </array>
    </dict>
</array>
```

## 🔐 Seguridad en Deep Links

### Protección de Rutas

El router tiene middleware de autenticación:

```dart
redirect: (context, state) {
  final isAuthenticated = authProvider.isAuthenticated;
  final isLoggingIn = state.matchedLocation == AppRoutes.login;
  
  // Si no está autenticado y no está en login → login
  if (!isAuthenticated && !isLoggingIn) {
    return AppRoutes.login;
  }
  
  // Verificar selección de institución
  // ...
}
```

**Esto significa:**
- ✅ Links a dashboards sin autenticación → Redirige a login
- ✅ Usuario autenticado recibe link → Navega directamente
- ✅ Validación de roles (el dashboard verifica el rol internamente)

## 📊 Casos de Uso

### Caso 1: Compartir Dashboard Específico
```dart
// Profesor comparte link de su dashboard
final teacherLink = 'https://asistapp.com/teacher-dashboard';
// Cualquier profesor autenticado puede abrir este link
```

### Caso 2: Notificación Push → Deep Link
```dart
// Notificación: "Nueva clase asignada"
// Link: asistapp://app/teacher-dashboard
// Usuario toca notificación → App abre en TeacherDashboard
```

### Caso 3: Email con Link Directo
```html
<!-- Email a admin -->
<a href="https://asistapp.com/admin-dashboard">
  Ver Panel de Administración
</a>
```

### Caso 4: Scroll Restoration
```dart
// Usuario en TeacherDashboard, scroll en posición 500
// Sale de la app
// Vuelve en 10 minutos
// Scroll automáticamente restaurado a posición 500 ✅
```

## 🧪 Testing

### Test Manual - Android

1. **Instalar la app**
   ```bash
   flutter run
   ```

2. **Test con custom scheme**
   ```bash
   adb shell am start -a android.intent.action.VIEW \
     -d "asistapp://app/teacher-dashboard"
   ```

3. **Test con HTTPS**
   ```bash
   adb shell am start -a android.intent.action.VIEW \
     -d "https://asistapp.com/admin-dashboard"
   ```

### Test Manual - Web

1. **Iniciar en modo web**
   ```bash
   flutter run -d chrome
   ```

2. **Navegar directamente**
   ```
   http://localhost:XXXX/teacher-dashboard
   ```

3. **Verificar scroll**
   - Scroll down en dashboard
   - Refrescar página (F5)
   - Verificar que mantiene posición ✅

## 🐛 Debug

### Ver logs de navegación
```dart
// En AppRouter, ya está activado:
debugLogDiagnostics: true
```

### Ver posiciones de scroll
```dart
final scrollProvider = context.read<ScrollStateProvider>();
print('Posición actual: ${scrollProvider.getScrollPosition(AppRoutes.teacherDashboard)}');
```

### Ver estado de deep link
```dart
// En cualquier widget
final location = GoRouterState.of(context).matchedLocation;
print('Ruta actual: $location');
```

## 📝 Mejoras Futuras

- [ ] Universal Links para iOS (app y web con mismo dominio)
- [ ] Deep links con parámetros: `/student-dashboard?studentId=123`
- [ ] Analytics de deep links (trackear cuántos se usan)
- [ ] QR codes que generan deep links
- [ ] Share sheet nativo para compartir dashboards

## ⚙️ Configuración Avanzada

### Cambiar dominio
En `AndroidManifest.xml`:
```xml
<data
    android:scheme="https"
    android:host="TU_DOMINIO.com"  ← Cambiar aquí
    android:pathPrefix="/" />
```

### Cambiar custom scheme
En `AndroidManifest.xml`:
```xml
<data
    android:scheme="TU_SCHEME"  ← Cambiar aquí
    android:host="app" />
```

### Agregar nueva ruta
1. En `app_routes.dart`:
   ```dart
   static const String myNewRoute = '/my-new-route';
   ```

2. En `app_router.dart`:
   ```dart
   GoRoute(
     path: AppRoutes.myNewRoute,
     name: 'my-new-route',
     pageBuilder: (context, state) => ...
   )
   ```

---

**Deep Linking + Scroll Persistence implementados** ✅

**URLs funcionando en Web y Android** ✅

**Persistencia automática de scroll** ✅
