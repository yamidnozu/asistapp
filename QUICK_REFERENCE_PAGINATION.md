# ⚡ Guía Rápida: Paginación en DemoLife

## 🚀 Usar PaginationWidget en 30 Segundos

### 1. Importar
```dart
import '../../widgets/pagination_widget.dart';
```

### 2. Agregar Widget
```dart
PaginationWidget(
  currentPage: provider.paginationInfo?.page ?? 1,
  totalPages: provider.paginationInfo?.totalPages ?? 1,
  totalItems: provider.paginationInfo?.total ?? 0,
  isLoading: provider.isLoading,
  onPageChange: (page) => _loadData(page: page),
)
```

### 3. Listo ✅
Eso es todo! El widget maneja:
- ✅ Indicador de página
- ✅ Botones Anterior/Siguiente
- ✅ Selector de página
- ✅ Validación de límites
- ✅ Responsividad
- ✅ Estado de carga

---

## 🔗 API del Widget

```dart
PaginationWidget(
  // Requeridos
  currentPage: int,              // Página actual (1-indexed)
  totalPages: int,               // Total de páginas
  totalItems: int,               // Total de items
  onPageChange: (int) async {},  // Callback de cambio

  // Opcionales
  isLoading: bool = false,       // Desactiva botones si es true
  maxPageButtons: int = 5,       // Máx botones visibles
)
```

---

## 📋 Checklist: Agregar Paginación

- [ ] El Provider tiene `paginationInfo` property
- [ ] El Provider tiene `loadData(page)` method
- [ ] Importar `PaginationWidget`
- [ ] Agregar widget al layout (Column)
- [ ] Mapear `paginationInfo` → widget properties
- [ ] Pasar `onPageChange` callback
- [ ] Ejecutar `flutter run`
- [ ] Probar navegación entre páginas

---

## 🎯 Ejemplos Rápidos

### Usuarios (IMPLEMENTADO)
```dart
PaginationWidget(
  currentPage: userProvider.paginationInfo?.page ?? 1,
  totalPages: userProvider.paginationInfo?.totalPages ?? 1,
  totalItems: userProvider.paginationInfo?.total ?? 0,
  isLoading: userProvider.isLoading,
  onPageChange: (page) => _loadUsers(page: page),
)
```

### Instituciones (TEMPLATE)
```dart
PaginationWidget(
  currentPage: institutionProvider.page,
  totalPages: institutionProvider.totalPages,
  totalItems: institutionProvider.total,
  isLoading: institutionProvider.isLoading,
  onPageChange: (page) async {
    await institutionProvider.loadInstitutions(page: page);
  },
)
```

### Reportes (TEMPLATE)
```dart
PaginationWidget(
  currentPage: reportProvider.currentPage,
  totalPages: reportProvider.totalPages,
  totalItems: reportProvider.totalReports,
  isLoading: reportProvider.isLoading,
  onPageChange: _loadReports,  // _loadReports(page)
)
```

---

## 🐛 Troubleshooting

| Problema | Solución |
|----------|----------|
| Widget no aparece | Verificar `totalPages > 1` |
| Botones no funcionan | Verificar `onPageChange` está siendo llamado |
| Datos no actualizan | Verificar que Provider hace `notifyListeners()` |
| Estilos raros | Verificar que `context.colors` funciona |
| Errores de compilación | Verificar import del widget |

---

## 📁 Archivos Importantes

| Archivo | Propósito |
|---------|-----------|
| `lib/widgets/pagination_widget.dart` | Widget reutilizable (CREAR AQUÍ) |
| `lib/screens/users/users_list_screen.dart` | Ejemplo implementado (REFERENCIA) |
| `PAGINATION_USAGE_EXAMPLES.md` | 7 ejemplos detallados |
| `TESTING_PAGINATION.md` | Cómo testear |
| `SUMMARY_PAGINATION.md` | Resumen completo |

---

## 🔧 Propiedades Útiles

### Getters del PaginationState
```dart
bool hasNextPage      // Puede ir a siguiente?
bool hasPreviousPage  // Puede ir a anterior?
bool isFirstPage      // ¿Es primera página?
bool isLastPage       // ¿Es última página?
```

### Métodos del PaginationState
```dart
// Crear copia con cambios
state.copyWith(
  currentPage: 2,
  isLoading: true,
)
```

---

## 💡 Tips

✅ **Tip 1**: Si solo hay 1 página, el widget se oculta automáticamente

✅ **Tip 2**: Los botones se deshabilitan automáticamente en los límites

✅ **Tip 3**: El selector muestra máx 5 botones (configurable)

✅ **Tip 4**: Es responsive - scroll horizontal en móvil

✅ **Tip 5**: `isLoading: true` desactiva todos los botones

✅ **Tip 6**: Usar `Provider.select()` para optimizar rebuilds

---

## 🎨 Personalización (Futuro)

```dart
// Próximamente (v2.0)
PaginationWidget(
  // ... propiedades estándar
  theme: PaginationTheme(
    primaryColor: Colors.blue,
    backgroundColor: Colors.white,
  ),
  maxPageButtons: 7,  // Aumentar botones visibles
)
```

---

## 📚 Ver También

- [Documentación Completa](PAGINATION_COMPLETE.md)
- [Ejemplos de Uso](PAGINATION_USAGE_EXAMPLES.md)
- [Guía de Testing](TESTING_PAGINATION.md)
- [Refactorización](PAGINATION_REFACTORING.md)

---

## ❓ Preguntas Frecuentes

**P: ¿Puedo usar este widget en otra app Flutter?**
A: Sí, es totalmente reutilizable. Solo copia `pagination_widget.dart`.

**P: ¿Qué pasa si hay 0 items?**
A: Muestra 1 página con 0 items. El widget se comporta correctamente.

**P: ¿Cómo cambio el número de items por página?**
A: Pasar `limit` diferente al llamar `provider.loadData(page, limit)`.

**P: ¿Se puede hacer infinite scroll?**
A: Sí, ese es un futuro enhancement. Por ahora usa botones.

**P: ¿Qué sucede si el API falla?**
A: El widget desactiva los botones si `isLoading: true`. Manejar error en Provider.

---

## 🚀 Flujo Rápido

```
Usuario hace clic en "Siguiente"
    ↓
onPageChange(2) callback
    ↓
provider.loadData(page: 2)
    ↓
API request: GET /data?page=2
    ↓
Provider actualiza paginationInfo
    ↓
notifyListeners()
    ↓
Widget reconstruye con nuevos datos
    ↓
UI actualiza automáticamente ✅
```

---

## ✅ Estado de Implementación

| Pantalla | Estado | Línea de Paginación |
|----------|--------|-------------------|
| Usuarios | ✅ HECHO | users_list_screen.dart (línea ~210) |
| Instituciones | ⏳ TODO | institutions_list_screen.dart |
| Reportes | ⏳ TODO | reports_list_screen.dart |
| Búsqueda | ⏳ TODO | search_screen.dart |

---

**¿Listo? Empieza con el paso 1 arriba y ¡en 30 segundos tienes paginación! 🚀**

*Última actualización: 28 de octubre de 2025*
