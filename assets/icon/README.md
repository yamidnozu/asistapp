# ✅ ICONOS GENERADOS EXITOSAMENTE

## 🎯 Estado: COMPLETADO

Los iconos han sido generados automáticamente para todas las plataformas:

### � Android (5 densidades)
- ✅ `mipmap-mdpi`: 48×48 px - Generado
- ✅ `mipmap-hdpi`: 72×72 px - Generado
- ✅ `mipmap-xhdpi`: 96×96 px - Generado
- ✅ `mipmap-xxhdpi`: 144×144 px - Generado
- ✅ `mipmap-xxxhdpi`: 192×192 px - Generado

### 🌐 Web (PWA)
- ✅ `Icon-192.png`: 192×192 px - Generado
- ✅ `Icon-512.png`: 512×512 px - Generado
- ✅ `Icon-maskable-192.png`: 192×192 px - Generado
- ✅ `Icon-maskable-512.png`: 512×512 px - Generado

### 🪟 Windows
- ✅ `app_icon.ico`: 48×48 px - Generado

## 📁 Ubicaciones
```
android/app/src/main/res/mipmap-*/ic_launcher.png
web/icons/Icon-*.png
windows/runner/resources/app_icon.ico
```

## ✅ Listo para Publicar
Tu app ya tiene todos los iconos necesarios para publicarse en Play Store y otras plataformas. ¡Todo está configurado correctamente! 🚀

## 🛠️ Cómo regenerar los iconos

Si actualizas `assets/icon/app_icon.png` (o `app_icon.svg`), puedes regenerar los iconos para todas las plataformas con `flutter_launcher_icons`.

1. Asegúrate de tener `flutter_launcher_icons.yaml` apuntando a `assets/icon/app_icon.png`.
2. Corre:
	- `flutter pub get`
	- `flutter pub run flutter_launcher_icons:main`

Esto actualizará `mipmap-*` (Android), `AppIcon.appiconset` (iOS), `app_icon.ico` (Windows) y las imágenes PWA para Web.

## 📥 Cómo instalar iconos desde las carpetas adjuntas

Si has subido o descargado las carpetas con iconos (por ejemplo: `mipmap-hdpi`, `mipmap-mdpi`, `mipmap-xhdpi`, `mipmap-xxhdpi`, `mipmap-xxxhdpi`), usa los scripts que añadamos para copiarlos automáticamente al proyecto.

En Bash (Linux / macOS / Windows con Git Bash):

```bash
./scripts/install_icons.sh /ruta/a/flutter_app_icons
```

En Windows (cmd.exe / PowerShell):

```bat
scripts\install_icons.bat C:\ruta\a\flutter_app_icons
```

Estos scripts copian los iconos a las rutas:
- `android/app/src/main/res/mipmap-*`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset`
- `windows/runner/resources/app_icon.ico`

Si quieres mantener una copia de seguridad de los recursos antiguos, el script de Bash guarda backups renombrando con timestamp; el script .bat renombra el archivo anterior añadiendo `.backup`.

## 🧼 Actualizar iconos visibles después de copiar (limpiar caché)

Android
- Desinstala la app del dispositivo/AVD (o ejecuta `adb uninstall com.edevcore.asistapp`), luego reconstruye e instala:

```bash
flutter clean
flutter pub get
flutter run -d <device>
```

- Nota: Algunos launchers en Android cachean los iconos; a veces es necesario reiniciar el dispositivo/emulador para ver cambios.

Web
- Forzar recarga del sitio (Ctrl+F5) o probar en modo incógnito. Para producción, rebuild:

```bash
flutter build web --release
```

Windows
- El Explorador de Windows cachea icons. Después de copiar `app_icon.ico`, reconstruye y ejecuta la app. Si el icono no cambia, reinicia el Explorador o el sistema:

	- Reinicia Explorer (PowerShell con permisos de usuario):

		```powershell
		Stop-Process -Name explorer -Force
		Start-Process explorer
		```

	- Alternativamente, desata y pinea de nuevo la app al taskbar para refrescar el icono.

	## 🛠️ Generar un `.ico` multi-res (opcional)

	Si quieres crear un `app_icon.ico` multi-res de alta calidad (varios tamaños empaquetados) desde tus PNGs, instala ImageMagick y ejecuta:

	Linux / macOS / Git Bash:

	```bash
	# Tomar la imagen grande (por ejemplo mipmap-xxxhdpi/ic_launcher.png)
	magick convert mipmap-xxxhdpi/ic_launcher.png -resize 16x16 icon-16.png
	magick convert mipmap-xxxhdpi/ic_launcher.png -resize 32x32 icon-32.png
	magick convert mipmap-xxxhdpi/ic_launcher.png -resize 48x48 icon-48.png
	magick convert mipmap-xxxhdpi/ic_launcher.png -resize 256x256 icon-256.png
	magick convert icon-16.png icon-32.png icon-48.png icon-256.png app_icon.ico
	```

	Windows (PowerShell):

	```powershell
	magick convert .\mipmap-xxxhdpi\ic_launcher.png -resize 16x16 .\tmp\icon-16.png
	magick convert .\mipmap-xxxhdpi\ic_launcher.png -resize 32x32 .\tmp\icon-32.png
	magick convert .\mipmap-xxxhdpi\ic_launcher.png -resize 48x48 .\tmp\icon-48.png
	magick convert .\mipmap-xxxhdpi\ic_launcher.png -resize 256x256 .\tmp\icon-256.png
	magick convert .\tmp\icon-16.png .\tmp\icon-32.png .\tmp\icon-48.png .\tmp\icon-256.png windows\runner\resources\app_icon.ico
	```

	Después copia `app_icon.ico` a `windows/runner/resources/`. El script `scripts/install_icons.sh` intenta generar un `app_icon.ico` automáticamente si `magick`/`convert` está disponible.

	### Instalar ImageMagick

	- Windows: Descarga desde https://imagemagick.org/script/download.php#windows y asegúrate de seleccionar la opción "Install legacy utilities (e.g., convert)" o de usar `magick` en tu PATH.
	- macOS: brew install imagemagick
	- Ubuntu/Debian: sudo apt-get install imagemagick

	Si no deseas instalar ImageMagick, puedes usar el fallback con Python y Pillow:

	```bash
	pip install pillow
	python scripts/png_to_ico.py mipmap-xxxhdpi/ic_launcher.png windows/runner/resources/app_icon.ico
	```
