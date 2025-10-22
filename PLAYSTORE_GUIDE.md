# 🚀 Guía para Publicar AsistApp en Google Play Store

## 📋 Requisitos Previos
- ✅ Cuenta de desarrollador en Google Play Console (edevcore@gmail.com)
- ✅ Aplicación completada y probada
- ✅ Icono de la app (512x512 PNG)
- ✅ Capturas de pantalla de la app

## 🔧 Paso 1: Preparación de la App (COMPLETADO)

### Configuración del Proyecto
- ✅ Versión: 1.0.0+1
- ✅ Nombre del paquete: `com.edevcore.asistapp`
- ✅ Dependencias actualizadas

### Firma Digital (COMPLETADO)
- ✅ Configuración de keystore en `android/key.properties`
- ✅ Scripts de generación de keystore incluidos

## 🎨 Paso 2: Preparar Assets

### Icono de la App
1. Crea un icono PNG de 512x512 píxeles
2. Guárdalo en `assets/icon/app_icon.png`
3. Ejecuta: `flutter pub run flutter_launcher_icons:main`

### Capturas de Pantalla
Necesitas al menos 2 capturas por dispositivo:
- 📱 Teléfono: 1080x1920 (mínimo 2)
- 📱 Tablet 7": 1200x1920 (opcional)
- 📱 Tablet 10": 1600x2560 (opcional)

## 🏗️ Paso 3: Generar App Bundle

### Opción 1: Usar script incluido
```bash
# Ejecutar el script incluido
./build_release.bat
```

### Opción 2: Comando manual
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

**Resultado:** `build/app/outputs/bundle/release/app-release.aab`

## 🎯 Paso 4: Google Play Console

### 4.1 Crear App
1. Ve a [Google Play Console](https://play.google.com/console)
2. Inicia sesión con `edevcore@gmail.com`
3. Haz clic en "Crear app"
4. Selecciona idioma predeterminado: **Español (Colombia)**
5. Tipo de app: **Aplicación**
6. Nombre de la app: **AsistApp**
7. Aplicación gratuita

### 4.2 Configurar Store Listing
1. **Título:** AsistApp - Registro de Asistencia
2. **Descripción corta:** App para registro de asistencia escolar con escaneo QR
3. **Descripción completa:**
```
AsistApp es una aplicación innovadora diseñada para facilitar el registro de asistencia en instituciones educativas. Utilizando tecnología QR, permite un proceso rápido y eficiente de marcado de asistencia.

Características principales:
• Escaneo QR para registro rápido
• Autenticación segura con Google
• Interfaz intuitiva y moderna
• Optimización de rendimiento
• Compatible con Android

Ideal para escuelas, colegios y universidades que buscan modernizar sus procesos administrativos.
```

4. **Capturas de pantalla:** Sube las imágenes preparadas
5. **Icono:** 512x512 PNG (se genera automáticamente)
6. **Características:** Marca las relevantes
7. **Categoría:** Educación
8. **Etiquetas:** asistencia, escuela, QR, educación
9. **Correo de contacto:** edevcore@gmail.com

### 4.3 Configurar Clasificación de Contenido
1. Ve a "Clasificación de contenido"
2. Responde el cuestionario (aplicación educativa)
3. Clasificación esperada: **Todos**

### 4.4 Subir App Bundle
1. Ve a "Liberar" → "Producción"
2. Haz clic en "Crear nueva versión"
3. Sube el archivo `app-release.aab`
4. **Nombre de versión:** 1.0.0
5. **Código de versión:** 1
6. **Notas de la versión:**
```
Versión inicial de AsistApp
• Registro de asistencia con QR
• Autenticación con Google
• Interfaz moderna y responsiva
• Optimización de rendimiento
```

### 4.5 Probar y Publicar
1. Una vez subida, Google revisará la app (24-48 horas)
2. Si aprueba, podrás publicar
3. Haz clic en "Revisar y lanzar"
4. Selecciona "Lanzar en producción"

## ⚠️ Notas Importantes

### Seguridad
- **NUNCA** subas el keystore ni `key.properties` a control de versiones
- Guarda las contraseñas en un lugar seguro
- El keystore es único por app

### Requisitos de Play Store
- **Tamaño máximo:** 150MB para AAB
- **API mínima:** 23 (Android 6.0)
- **Permisos:** Solo los necesarios
- **Política:** Cumple con políticas de Play Store

### Costos
- **Registro:** $25 USD (una sola vez)
- **Publicación:** Gratis para apps gratuitas

## 🔄 Actualizaciones Futuras

Para futuras versiones:
1. Incrementa `versionCode` en `pubspec.yaml`
2. Actualiza `versionName` si es versión mayor
3. Genera nuevo bundle
4. Sube como nueva versión en Play Console

## 📞 Soporte

Si tienes problemas:
- Revisa los logs de compilación
- Verifica que el keystore esté configurado correctamente
- Asegúrate de que todas las dependencias estén actualizadas

¡Tu app estará disponible en Play Store pronto! 🎉