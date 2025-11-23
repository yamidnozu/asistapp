# 🎨 Guía para Generar Iconos de la Aplicación desde logo.jpg

Este documento contiene las instrucciones y herramientas para generar todos los iconos necesarios de la aplicación a partir del archivo `logo.jpg`.

## 📋 Requisitos

1. **ImageMagick** - Herramienta de línea de comandos para procesamiento de imágenes
   - Windows: `choco install imagemagick` o descargar desde https://imagemagick.org/
   - Linux/Mac: `sudo apt-get install imagemagick` o `brew install imagemagick`

2. **Flutter Launcher Icons** (ya incluido en el proyecto)
   ```bash
   flutter pub add flutter_launcher_icons --dev
   ```

## 🚀 Método Automatizado (Recomendado)

### Opción 1: Usar Flutter Launcher Icons

1. El logo fuente está en: `logo.jpg`
2. Ejecuta el script de generación:
   ```bash
   bash generate_icons.sh
   ```
   O en Windows:
   ```bash
   generate_icons.bat
   ```

3. Esto generará automáticamente:
   - ✅ Android icons (todos los tamaños mipmap)
   - ✅ iOS icons
   - ✅ Web icons
   - ✅ Windows icons

## 🛠️ Método Manual (Con ImageMagick)

Si prefieres hacerlo manualmente, usa los comandos del script `generate_icons_manual.sh` para crear cada tamaño específico.

### Tamaños necesarios:

#### 📱 Android (mipmap)
- **mdpi**: 48x48px
- **hdpi**: 72x72px
- **xhdpi**: 96x96px
- **xxhdpi**: 144x144px
- **xxxhdpi**: 192x192px

#### 🍎 iOS
- **20x20** @1x, @2x, @3x
- **29x29** @1x, @2x, @3x
- **40x40** @1x, @2x, @3x
- **60x60** @2x, @3x
- **76x76** @1x, @2x
- **83.5x83.5** @2x
- **1024x1024** (App Store)

#### 🌐 Web
- **favicon.ico**: 16x16, 32x32
- **icon-192.png**: 192x192px
- **icon-512.png**: 512x512px

#### 🪟 Windows
- **app_icon.ico**: 16, 32, 48, 256 tamaños

## 📝 Estructura de Carpetas

```
assets/
  └── icon/
      └── logo.jpg (original)
android/
  └── app/
      └── src/
          └── main/
              └── res/
                  ├── mipmap-mdpi/
                  ├── mipmap-hdpi/
                  ├── mipmap-xhdpi/
                  ├── mipmap-xxhdpi/
                  └── mipmap-xxxhdpi/
ios/
  └── Runner/
      └── Assets.xcassets/
          └── AppIcon.appiconset/
web/
  ├── favicon.png
  ├── icons/
  │   ├── Icon-192.png
  │   └── Icon-512.png
windows/
  └── runner/
      └── resources/
          └── app_icon.ico
```

## 🎯 Proceso Completo

1. **Preparar el logo**: Asegúrate de que `logo.jpg` tenga alta resolución (mínimo 1024x1024px)
2. **Ejecutar generación**: Usa el script automatizado
3. **Verificar**: Revisa que todos los iconos se generaron correctamente
4. **Limpiar**: El script eliminará los iconos antiguos automáticamente
5. **Probar**: Ejecuta la app en cada plataforma para verificar

## 🔧 Configuración en pubspec.yaml

La configuración ya está actualizada:

```yaml
flutter_icons:
  android: "ic_launcher"
  ios: true
  image_path: "assets/icon/logo.jpg"
  min_sdk_android: 21
  web:
    generate: true
    image_path: "assets/icon/logo.jpg"
  windows:
    generate: true
    image_path: "assets/icon/logo.jpg"
```

## ⚠️ Notas Importantes

- El logo original debe ser cuadrado (1:1 ratio)
- Usar PNG con transparencia es ideal, pero JPG también funciona
- Para iOS, el logo NO debe tener transparencia
- Para Android, puedes usar transparencia
- Resolución mínima recomendada: 1024x1024px
- El logo debe tener margen interno (padding) para verse bien en todos los tamaños

## 🐛 Solución de Problemas

### Error: ImageMagick no encontrado
```bash
# Instala ImageMagick primero
choco install imagemagick  # Windows
brew install imagemagick   # Mac
sudo apt install imagemagick  # Linux
```

### Los iconos no se actualizan
```bash
# Limpia y reconstruye
flutter clean
flutter pub get
flutter pub run flutter_launcher_icons:main
```

### Los iconos se ven pixelados
- Verifica que `logo.jpg` tenga al menos 1024x1024px
- Usa una imagen de mayor calidad
- Considera usar PNG en lugar de JPG

## 📚 Referencias

- [Flutter Launcher Icons](https://pub.dev/packages/flutter_launcher_icons)
- [ImageMagick Documentation](https://imagemagick.org/script/command-line-processing.php)
- [Android Icon Guidelines](https://developer.android.com/guide/practices/ui_guidelines/icon_design_launcher)
- [iOS Icon Guidelines](https://developer.apple.com/design/human-interface-guidelines/app-icons)
