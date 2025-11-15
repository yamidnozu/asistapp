## 📊 Visualización de Límites Horarios

### Escala de Minutos
```
Minuto:   420    480    540    600    660    720
          |______|______|______|______|______|
          07:00  08:00  09:00  10:00  11:00  12:00
```

### Caso 1: Conflicto Total ❌
```
Existente: [━━━━━━━━━━━] 08:00-10:00 (480-600)
Nueva:    [━━━━━━━━━━━] 08:00-10:00 (480-600)
                        ^CONFLICTO TOTAL^

Lógica: 480 < 600 AND 600 > 480 ✓ = RECHAZAR
```

### Caso 2: Sin Conflicto ✅
```
Existente: [━━━━━━━━━━━]         08:00-10:00 (480-600)
Nueva:                    [━━━━━━━━━━━] 10:00-12:00 (600-720)
                          ^Perfectamente consecutivas^

Lógica: 600 < 600? NO = SIN CONFLICTO, ACEPTAR
```

### Caso 3: Conflicto Parcial Inicio ❌
```
Existente: [━━━━━━━━━━━] 08:00-10:00 (480-600)
Nueva:              [━━━━━━━━━━━] 09:00-11:00 (540-660)
                    ^SOLAPA AQUÍ^

Lógica: 540 < 600 AND 660 > 480 ✓ = RECHAZAR
```

### Caso 4: Conflicto Parcial Fin ❌
```
Existente:             [━━━━━━━━━━━] 08:00-10:00 (480-600)
Nueva:      [━━━━━━━━━━━] 07:00-09:00 (420-540)
                        ^SOLAPA AQUÍ^

Lógica: 420 < 600 AND 540 > 480 ✓ = RECHAZAR
```

### Caso 5: Conflicto - Contención ❌
```
Existente:      [━━━━━━━━━━━] 08:00-10:00 (480-600)
Nueva:    [━━━━━━━━━━━━━━━━━━━] 07:00-11:00 (420-660)
          ^LA NUEVA CONTIENE A LA EXISTENTE^

Lógica: 420 < 600 AND 660 > 480 ✓ = RECHAZAR
```

## Fórmula de Detección

```
CONFLICTO = (inicioNuevo < finExistente) AND (finNuevo > inicioExistente)
```

### Ejemplos Numéricos

| Existente | Nueva | inicioN < finE? | finN > inicioE? | Resultado |
|-----------|-------|-----------------|-----------------|-----------|
| 480-600   | 480-600 | ✓ (480<600) | ✓ (600>480) | ❌ CONFLICTO |
| 480-600   | 600-720 | ✗ (600<600) | ✓ (720>480) | ✅ OK |
| 480-600   | 540-660 | ✓ (540<600) | ✓ (660>480) | ❌ CONFLICTO |
| 480-600   | 420-540 | ✓ (420<600) | ✓ (540>480) | ❌ CONFLICTO |
| 480-600   | 420-660 | ✓ (420<600) | ✓ (660>480) | ❌ CONFLICTO |
| 480-600   | 300-420 | ✗ (300<600) | ✗ (420>480) | ✅ OK |

## Casos en la App

### ✅ Caso Exitoso en Prueba de Usuario

El usuario intentó crear una clase a las 08:00-10:00 (mismo horario existente)
→ Sistema rechazó correctamente con error 409

El usuario seleccionó otra hora sin conflictos
→ Sistema aceptó y creó la clase exitosamente

**Esto demuestra que la validación funciona perfectamente.**
