# AsistApp - Environments de Postman

Este directorio contiene diferentes archivos de environment para Postman que puedes usar según el entorno donde estés probando la API.

## 📁 Archivos Disponibles

### `Asistapp.postman_environment.json`
Environment principal con configuración completa para desarrollo local.

### Creando Environments Personalizados

Puedes crear environments adicionales para diferentes entornos copiando la estructura del archivo principal y modificando las variables.

## 🛠️ Variables Importantes

### Variables de Conexión (requeridas)
```json
{
  "protocol": "http|https",
  "host": "tu-servidor.com",
  "port": "3000" // vacío para HTTPS estándar
}
```

### Variables de Autenticación (automáticas)
```json
{
  "accessToken": "", // Se actualiza en login
  "refreshToken": "" // Opcional
}
```

### Variables de Prueba (opcionales)
```json
{
  "userId": "",
  "institucionId": "",
  "role": "estudiante"
}
```

## 🌍 Ejemplos de Environments

### Desarrollo Local
```json
{
  "protocol": "http",
  "host": "localhost",
  "port": "3000"
}
```

### Docker Local
```json
{
  "protocol": "http",
  "host": "localhost",
  "port": "8080"
}
```

### Staging
```json
{
  "protocol": "https",
  "host": "api-staging.asistapp.com",
  "port": ""
}
```

### Producción
```json
{
  "protocol": "https",
  "host": "api.asistapp.com",
  "port": ""
}
```

## 🔄 Cambiando Entre Environments

1. En Postman, haz clic en el dropdown de "Environment" (esquina superior derecha)
2. Selecciona el environment deseado
3. Todas las variables se actualizarán automáticamente
4. Las requests usarán la nueva configuración

## ⚠️ Notas de Seguridad

- Nunca commits las contraseñas reales en los archivos de environment
- Usa variables de tipo "secret" para contraseñas sensibles
- Los environments son locales y no se suben al repositorio