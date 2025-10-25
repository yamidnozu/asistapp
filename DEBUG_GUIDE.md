# Guía de Debug en VS Code

## Configuraciones de Debug Disponibles

### 1. Flutter (Debug Normal)
- **Uso**: Para desarrollo estándar con hot reload
- **Características**:
  - Hot reload automático
  - Consola de debug abierta
  - Conexión persistente al VM service

### 2. Flutter Debug (Hot Reload)
- **Uso**: Optimizado para desarrollo continuo
- **Características**:
  - Hot reload mejorado
  - Consola de debug siempre visible
  - Conexión VM service activa

### 3. Flutter Debug (Persistent)
- **Uso**: Para debugging avanzado y troubleshooting
- **Características**:
  - Pausa automática de isolates
  - VM service siempre activo
  - Mejor visibilidad de errores

## Cómo Mantener la Conexión de Debug

1. **Seleccionar la configuración correcta**:
   - Ve a la pestaña de Debug (Ctrl+Shift+D)
   - Selecciona "Flutter Debug (Hot Reload)" o "Flutter Debug (Persistent)"

2. **Iniciar en modo debug**:
   - Presiona F5 o el botón verde de play
   - La barra de VS Code debe permanecer NARANJA (modo debug activo)

3. **Verificar la conexión**:
   - Abre la consola de Debug (Ctrl+Shift+Y)
   - Deberías ver logs de Flutter y tu aplicación
   - Los breakpoints deberían funcionar

## Solución de Problemas

### Si VS Code se desconecta:
1. Detén la aplicación (Shift+F5)
2. Ejecuta `flutter: clean & pub get` desde la paleta de comandos
3. Reinicia VS Code
4. Selecciona "Flutter Debug (Persistent)" y presiona F5

### Si no hay hot reload:
1. Verifica que estés en modo debug (barra naranja)
2. Guarda el archivo (Ctrl+S) para activar hot reload
3. Si no funciona, reinicia la sesión de debug

## Atajos Útiles

- **F5**: Iniciar/continuar debug
- **F10**: Step over
- **F11**: Step into
- **Shift+F11**: Step out
- **Shift+F5**: Detener debug
- **Ctrl+Shift+D**: Abrir panel de debug

## Logs y Debugging

- Los logs de la aplicación aparecen en la consola de Debug
- Para ver logs detallados del backend, mira la consola de Debug mientras haces login
- Los errores de red/API se muestran en los logs de debug