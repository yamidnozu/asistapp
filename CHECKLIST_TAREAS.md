# 📋 Checklist de Tareas Pendientes

## ✅ Completadas (Esta sesión)

- [x] Agregar dependencias faltantes a pubspec.yaml
  - [x] cloud_firestore
  - [x] firebase_storage
  - [x] hive
  - [x] hive_flutter
  - [x] google_generative_ai

- [x] Inicializar Hive en main.dart
- [x] Crear UserProvider con sincronización de roles
- [x] Crear Route Guards para protección de rutas
- [x] Crear sistema de tema (AppTheme, AppColors, AppSpacing)
- [x] Crear componentes UI reutilizables
  - [x] AppButton y AppSecondaryButton
  - [x] AppTextInput y AppCheckbox
  - [x] AppScaffold, AppCard, AppDialog
- [x] Crear modelo Hive para tareas
- [x] Renombrar web/manifest.json
- [x] flutter pub get (instalar todas las dependencias)
- [x] flutter analyze (validación sin errores)

---

## 🔄 Próximas Tareas (Implementación)

### Fase 1: Preparación

- [ ] Ejecutar `flutter pub run build_runner build` para generar adaptadores Hive
- [ ] Revisar que flutter analyze no tenga errores
- [ ] Verificar que el proyecto compile sin advertencias críticas

### Fase 2: Integración de Auth

- [ ] **Actualizar AuthProvider**
  - Llamar a `UserProvider().syncUserData()` después de `signInWithGoogle()`
  - Sincronizar también en `AuthProvider._init()`

  ```dart
  Future<void> signInWithGoogle() async {
    try {
      final result = await _authService.signInWithGoogle();
      if (result != null) {
        _user = _authService.currentUser;
        // NUEVO: Sincronizar usuario y rol
        await context.read<UserProvider>().syncUserData();
        notifyListeners();
      }
    } catch (e) {
      // Error
    }
  }
  ```

- [ ] **Actualizar LoginScreen**
  - Usar `AppButton` en lugar de widgets nativos
  - Usar `AppTextInput` para email/password
  - Aplicar `AppScaffold` como contenedor
  - Aplicar estilos de `AppTextStyles`

- [ ] **Proteger acceso a HomeScreen**
  ```dart
  // En main.dart
  Consumer<AuthProvider>(
    builder: (context, authProvider, _) {
      if (authProvider.isAuthenticated) {
        return ProtectedRoute(
          guard: (ctx) => RouteGuards.requireAuth(ctx),
          fallback: LoginScreen(),
          child: HomeScreen(),
        );
      } else {
        return LoginScreen();
      }
    },
  )
  ```

### Fase 3: Refactorizar Pantallas Existentes

- [ ] **HomeScreen**
  - [ ] Reemplazar layout con `AppScaffold`
  - [ ] Usar `AppCard` para listar tareas
  - [ ] Usar `AppButton` para acciones
  - [ ] Aplicar `AppTextStyles` a todo texto

- [ ] **LoginScreen**
  - [ ] Reemplazar botones con `AppButton`
  - [ ] Reemplazar inputs con `AppTextInput`
  - [ ] Usar `AppScaffold` o layout personalizado
  - [ ] Aplicar colores de `AppColors`

### Fase 4: Implementar Nuevas Funcionalidades

- [ ] **Guards de Ruta por Rol**
  - Crear pantalla AdminPanel (solo admins)
  - Crear pantalla UserProfile (usuarios normales)
  - Implementar guards en navegación

- [ ] **Persistencia con Hive**
  - [ ] Actualizar `TaskProvider` para usar Hive
  - [ ] Sincronizar tareas locales con Firestore
  - [ ] Implementar caché offline

- [ ] **Firebase Storage (Fotos)**
  - [ ] Crear `StorageService`
  - [ ] Implementar subida de imágenes
  - [ ] Mostrar fotos en tareas

- [ ] **Gemini AI Integration**
  - [ ] Usar GeminiService para generar sugerencias
  - [ ] Crear pantalla de sugerencias de tareas
  - [ ] Integrar con generación automática de descripciones

### Fase 5: Testing y Validación

- [ ] Compilar para Android
- [ ] Compilar para iOS
- [ ] Compilar para Web
- [ ] Ejecutar pruebas unitarias
- [ ] Pruebas de integración
- [ ] Probar en dispositivo físico

### Fase 6: Configuración Firebase

- [ ] **Verificar firebase_options.dart**
  - [ ] Android appId: `1:145893311915:android:e89a9e0e847d4968da3eee`
  - [ ] iOS appId: `1:145893311915:ios:e89a9e0e847d4968da3eee`
  - [ ] Web appId: `1:145893311915:web:e89a9e0e847d4968da3eee`

- [ ] **Habilitar servicios en Firebase Console**
  - [ ] Authentication (Google Sign-In)
  - [ ] Firestore Database
  - [ ] Storage (para fotos)
  - [ ] Gemini API (si es necesario)

- [ ] **Configurar CORS para Web**
  - [ ] Autorizar `localhost:*` (desarrollo)
  - [ ] Autorizar dominio de producción

- [ ] **Configurar Rules en Firestore**
  ```firestore
  match /users/{userId} {
    allow read, write: if request.auth.uid == userId;
    allow read: if request.auth != null;
    
    match /tasks/{document=**} {
      allow read, write: if request.auth.uid == userId;
    }
  }
  ```

- [ ] **Configurar Rules en Storage**
  ```
  match /tasks/{userId}/{allPaths=**} {
    allow read, write: if request.auth.uid == userId;
  }
  ```

---

## 📱 Checklist por Plataforma

### Android
- [ ] Compilar sin errores
- [ ] Probar Google Sign-In
- [ ] Probar cámara para fotos
- [ ] Probar Hive persistencia

### iOS
- [ ] Compilar sin errores
- [ ] Configurar Google Sign-In (Info.plist)
- [ ] Probar cámara para fotos
- [ ] Probar Hive persistencia
- [ ] Probar en dispositivo real

### Web
- [ ] Compilar sin errores
- [ ] Probar Google Sign-In
- [ ] Probar localStorage (Hive)
- [ ] Probar en navegadores modernos

### Windows/macOS (Opcional)
- [ ] Compilar sin errores
- [ ] Probar persistencia

---

## 🔧 Comando Útiles

```bash
# Generar adaptadores Hive
flutter pub run build_runner build

# Limpiar build
flutter clean

# Instalar dependencias
flutter pub get

# Actualizar dependencias
flutter pub upgrade

# Analizar código
flutter analyze

# Ejecutar con verbose
flutter run -v

# Construir APK
flutter build apk --release

# Construir App Bundle
flutter build appbundle

# Construir Web
flutter build web

# Construir Windows
flutter build windows
```

---

## 📊 Resumen de Estados

| Tarea | Estado | Asignado a | Fecha |
|-------|--------|-----------|-------|
| Dependencias | ✅ | - | 16/10/2025 |
| Hive Init | ✅ | - | 16/10/2025 |
| UserProvider | ✅ | - | 16/10/2025 |
| Route Guards | ✅ | - | 16/10/2025 |
| Tema UI | ✅ | - | 16/10/2025 |
| Componentes | ✅ | - | 16/10/2025 |
| Refactor Screens | ⏳ | - | Próximo |
| Storage Service | ⏳ | - | Próximo |
| Gemini Integration | ⏳ | - | Próximo |
| Testing | ⏳ | - | Próximo |

---

## 🎯 Orden Recomendado de Ejecución

1. ✅ Generar adaptadores Hive con build_runner
2. ✅ Actualizar AuthProvider para sincronizar UserProvider
3. ⏳ Refactorizar LoginScreen
4. ⏳ Refactorizar HomeScreen
5. ⏳ Crear AdminPanel (protegida)
6. ⏳ Crear StorageService
7. ⏳ Integrar Gemini AI
8. ⏳ Testing completo
9. ⏳ Build para todas las plataformas

---

## 📞 Soporte

### Si encuentras problemas:

1. Ejecuta `flutter clean && flutter pub get`
2. Verifica `flutter analyze` sin errores
3. Revisa logs con `flutter run -v`
4. Consulta la guía en `GUIA_COMPONENTES.md`
5. Revisa cambios en `CAMBIOS_REALIZADOS.md`

---

**Última actualización**: 16 de octubre de 2025  
**Última revisión**: Completa y actualizada
