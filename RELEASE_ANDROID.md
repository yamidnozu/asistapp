# Publicar la app Android en Google Play Store

Este documento explica cómo automatizar la publicación de la app Android (Flutter) en Google Play usando GitHub Actions.

## Requisitos previos

1. Cuenta de Google Play Console con permisos para publicar.
2. Servicio de cuenta de Google Play (JSON) con permisos `Edit` o `Release` para la app.
   - En el Play Console: `Settings > API access` → `Create service account` y dar permisos.
   - Descarga el JSON y guarda su contenido.
3. Keystore para firmar la app (archivo `.jks`) y datos:
    - `KEYSTORE_BASE64` (string Base64 del contenido de keystore.jks) o incluir `keystore.jks` en el repo raíz.
       - Si incluyes el archivo en el repo, el workflow copiará el archivo a `android/keystore.jks` para que Gradle pueda usarlo (esto sobrescribirá el `android/keystore.jks` si existe).
   - `KEYSTORE_PASSWORD`
   - `KEY_ALIAS`
   - `KEY_PASSWORD`
4. Asegúrate que el `applicationId` en `android/app/build.gradle` sea el package correcto (ej. `com.edevcore.asistapp`).

## Secretos de GitHub Actions sugeridos

Configura estos secrets en `Settings > Secrets and variables > Actions` del repositorio:

- `PLAY_STORE_SERVICE_ACCOUNT`: El contenido JSON del archivo de la cuenta de servicio.
- `KEYSTORE_BASE64`: Base64 del archivo `keystore.jks` (opcional si ya incluiste `keystore.jks` en la raíz del repo).
- `KEYSTORE_PASSWORD`
- `KEY_ALIAS`
- `KEY_PASSWORD`
- `API_BASE_URL` (opcional) - Dirección completa (incluye protocolo) del backend en producción. Ej: `https://mi-dominio.com` o `https://31.220.104.130`
  
### Cómo codificar el keystore a base64 (opcional)

Si vas a usar `KEYSTORE_BASE64` en GitHub Secrets, puedes generar la variable desde tu entorno local:

```bash
# Linux / macOS
base64 -w 0 keystore.jks > keystore.b64

# Windows (PowerShell)
[Convert]::ToBase64String([IO.File]::ReadAllBytes('keystore.jks')) > keystore.b64
```

Copiar el contenido de `keystore.b64` en el secret `KEYSTORE_BASE64`.

## Cómo usar el workflow

Se añadió el workflow `.github/workflows/release-android.yml`. Para ejecutar manualmente:

1. Ve a `Actions` → `Release Android to Play Store` → `Run workflow`.
2. Rellena los inputs:
   - `track`: `internal`, `alpha`, `beta` o `production`.
   - `releaseName` (opcional): nombre de release.
   - `releaseNotes` (opcional): notas que se publicarán con la release.
3. Ejecuta la publicación.

Si prefieres hacerlo localmente o en un runner, puedes generar el AAB con:

# Si quieres especificar la URL del backend en el build, añade el flag --dart-define
```bash
flutter pub get
# Ejemplo local con API_BASE_URL
flutter build appbundle --release --dart-define=API_BASE_URL=https://mi-dominio.com --dart-define=ENVIRONMENT=production
# El archivo resultante estará en build/app/outputs/bundle/release/app-release.aab
```

Y subirlo manualmente al Play Console.

## Notas y consejos

- Revisa que `android/key.properties` no esté comiteado al repo (puedes ignorarlo en `.gitignore`).
- Si el proyecto utiliza ProGuard/obfuscación, revisa la `mapping.txt` y súbelo si es necesario.
- Para pruebas rápidas puedes usar el `internal` track y luego promover la release a `production` desde Play Console.

---

Si quieres, puedo:
- Crear una release en GitHub con notas y el AAB como artefacto.
- Añadir un step en el workflow para subir la AAB como artifact si deseas revisar antes del publish.
- Configurar un flujo para promover releases entre tracks automáticamente.
