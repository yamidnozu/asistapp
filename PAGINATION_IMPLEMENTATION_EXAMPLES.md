# 🎨 PaginationWidget - Ejemplos de Implementación

## 📋 Índice
1. [Implementación Básica](#implementación-básica)
2. [Con Provider](#con-provider)
3. [Con Búsqueda y Filtros](#con-búsqueda-y-filtros)
4. [Responsive Design](#responsive-design)
5. [Estados de Error](#estados-de-error)
6. [Optimizaciones](#optimizaciones)

---

## 1. Implementación Básica

### Ejemplo Simple
```dart
class SimpleListScreen extends StatefulWidget {
  @override
  _SimpleListScreenState createState() => _SimpleListScreenState();
}

class _SimpleListScreenState extends State<SimpleListScreen> {
  List<Item> items = [];
  int currentPage = 1;
  int totalPages = 1;
  int totalItems = 0;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({int page = 1}) async {
    setState(() => isLoading = true);
    
    try {
      final response = await apiService.getItems(page: page);
      setState(() {
        items = response.data;
        currentPage = response.pagination.page;
        totalPages = response.pagination.totalPages;
        totalItems = response.pagination.total;
      });
    } catch (e) {
      // Manejar error
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Lista de items
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) => ItemTile(items[index]),
          ),
        ),
        
        // Widget de paginación
        PaginationWidget(
          currentPage: currentPage,
          totalPages: totalPages,
          totalItems: totalItems,
          isLoading: isLoading,
          onPageChange: (page) => _loadData(page: page),
        ),
      ],
    );
  }
}
```

**Resultado Visual:**
```
┌─────────────────────────────────┐
│ Item 1                          │
│ Item 2                          │
│ Item 3                          │
│ ...                             │
├─────────────────────────────────┤
│ 📚 Página 1 de 5 [ 45 items ]  │
│ [●1] [2] [3] [4] [5]           │
│ [|<] [← Anterior] [>] [>|]     │
└─────────────────────────────────┘
```

---

## 2. Con Provider

### Provider Setup
```dart
class DataProvider extends ChangeNotifier {
  List<DataItem> _items = [];
  PaginationInfo? _paginationInfo;
  bool _isLoading = false;

  List<DataItem> get items => _items;
  PaginationInfo? get paginationInfo => _paginationInfo;
  bool get isLoading => _isLoading;

  Future<void> loadPage(int page) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await dataService.getData(page: page);
      _items = response.data;
      _paginationInfo = response.pagination;
    } catch (e) {
      // Manejo de error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNextPage() async {
    if (_paginationInfo?.hasNext ?? false) {
      await loadPage((_paginationInfo?.page ?? 0) + 1);
    }
  }

  Future<void> loadPreviousPage() async {
    if (_paginationInfo?.hasPrev ?? false) {
      await loadPage((_paginationInfo?.page ?? 2) - 1);
    }
  }
}
```

### Screen con Provider
```dart
class DataListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // Lista
            Expanded(
              child: provider.isLoading && provider.items.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: provider.items.length,
                      itemBuilder: (context, index) {
                        return DataItemTile(provider.items[index]);
                      },
                    ),
            ),
            
            // Paginación
            PaginationWidget(
              currentPage: provider.paginationInfo?.page ?? 1,
              totalPages: provider.paginationInfo?.totalPages ?? 1,
              totalItems: provider.paginationInfo?.total ?? 0,
              isLoading: provider.isLoading,
              onPageChange: (page) => provider.loadPage(page),
            ),
          ],
        );
      },
    );
  }
}
```

**Ventajas:**
- ✅ Estado centralizado
- ✅ Fácil de probar
- ✅ Reutilizable en múltiples pantallas
- ✅ Reactivo automático

---

## 3. Con Búsqueda y Filtros

### Screen Completo con Filtros
```dart
class FilteredListScreen extends StatefulWidget {
  @override
  _FilteredListScreenState createState() => _FilteredListScreenState();
}

class _FilteredListScreenState extends State<FilteredListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedFilter;
  List<Item> _items = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Debounce para búsqueda
    _searchController.addListener(_onSearchChanged);
  }

  Timer? _debounce;
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadData(page: 1); // Reset a página 1 en búsqueda
    });
  }

  Future<void> _loadData({int page = 1}) async {
    setState(() => _isLoading = true);
    
    try {
      final response = await apiService.getItems(
        page: page,
        search: _searchController.text.isEmpty ? null : _searchController.text,
        filter: _selectedFilter,
      );
      
      setState(() {
        _items = response.data;
        _currentPage = response.pagination.page;
        _totalPages = response.pagination.totalPages;
        _totalItems = response.pagination.total;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;

    return Column(
      children: [
        // Barra de búsqueda
        Padding(
          padding: EdgeInsets.all(spacing.md),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar...',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _loadData(page: 1);
                            },
                          )
                        : null,
                  ),
                ),
              ),
              SizedBox(width: spacing.sm),
              // Filtro dropdown
              DropdownButton<String>(
                value: _selectedFilter,
                hint: Text('Filtrar'),
                items: [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  DropdownMenuItem(value: 'active', child: Text('Activos')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactivos')),
                ],
                onChanged: (value) {
                  setState(() => _selectedFilter = value);
                  _loadData(page: 1);
                },
              ),
            ],
          ),
        ),
        
        // Contador de resultados
        if (_totalItems > 0)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing.md),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Mostrando ${_items.length} de $_totalItems resultados',
                style: context.textStyles.bodySmall
                    .copyWith(color: colors.textSecondary),
              ),
            ),
          ),
        
        // Lista
        Expanded(
          child: _isLoading && _items.isEmpty
              ? Center(child: CircularProgressIndicator())
              : _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: colors.textMuted),
                          SizedBox(height: spacing.md),
                          Text(
                            'No se encontraron resultados',
                            style: context.textStyles.bodyLarge
                                .copyWith(color: colors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        return ItemTile(_items[index]);
                      },
                    ),
        ),
        
        // Paginación
        PaginationWidget(
          currentPage: _currentPage,
          totalPages: _totalPages,
          totalItems: _totalItems,
          isLoading: _isLoading,
          onPageChange: _loadData,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}
```

**Resultado Visual:**
```
┌─────────────────────────────────────────┐
│ [🔍 Buscar...    ] [▼ Filtrar]        │
│ Mostrando 10 de 45 resultados           │
├─────────────────────────────────────────┤
│ Item 1 (coincidencia)                   │
│ Item 2 (coincidencia)                   │
│ ...                                     │
├─────────────────────────────────────────┤
│ 📚 Página 1 de 5 [ 45 items ]          │
│ [●1] [2] [3] [4] [5]                   │
└─────────────────────────────────────────┘
```

---

## 4. Responsive Design

### Adaptación Móvil/Desktop
```dart
class ResponsivePaginatedList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            // Lista adaptativa
            Expanded(
              child: isMobile
                  ? _buildMobileList()
                  : _buildDesktopList(),
            ),
            
            // Paginación (siempre responsive)
            PaginationWidget(
              currentPage: currentPage,
              totalPages: totalPages,
              totalItems: totalItems,
              isLoading: isLoading,
              onPageChange: loadPage,
              // El widget ya maneja responsive internamente
            ),
          ],
        );
      },
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            title: Text(items[index].name),
            subtitle: Text(items[index].description),
          ),
        );
      },
    );
  }

  Widget _buildDesktopList() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.5,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return ItemCard(items[index]);
      },
    );
  }
}
```

**Mobile View:**
```
┌──────────────────┐
│ 📚 Pág 1/5      │
│ [ 45 items ]    │
├──────────────────┤
│ ← [1][2][●3]    │ ← Scroll horizontal
│ [|<][<][>][>|]  │ ← Botones compactos
└──────────────────┘
```

**Desktop View:**
```
┌────────────────────────────────────────────┐
│ 📚 Página 1 de 5  [ 45 items ]            │
├────────────────────────────────────────────┤
│ [1] [2] [●3] [4] [5]                      │
│ [|< Primera] [← Anterior] [>] [Última >|] │
└────────────────────────────────────────────┘
```

---

## 5. Estados de Error

### Manejo de Errores con Paginación
```dart
class ErrorHandlingScreen extends StatefulWidget {
  @override
  _ErrorHandlingScreenState createState() => _ErrorHandlingScreenState();
}

class _ErrorHandlingScreenState extends State<ErrorHandlingScreen> {
  List<Item> _items = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _loadData({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final response = await apiService.getItems(page: page);
      setState(() {
        _items = response.data;
        _currentPage = response.pagination.page;
        _totalPages = response.pagination.totalPages;
        _totalItems = response.pagination.total;
      });
    } on NetworkException catch (e) {
      setState(() => _errorMessage = 'Error de red: ${e.message}');
    } on ServerException catch (e) {
      setState(() => _errorMessage = 'Error del servidor: ${e.message}');
    } catch (e) {
      setState(() => _errorMessage = 'Error inesperado: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;

    return Column(
      children: [
        // Mostrar error si existe
        if (_errorMessage != null)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(spacing.md),
            color: colors.error.withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: colors.error),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: context.textStyles.bodyMedium
                        .copyWith(color: colors.error),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: colors.error),
                  onPressed: () => _loadData(page: _currentPage),
                ),
              ],
            ),
          ),
        
        // Lista
        Expanded(
          child: _buildContent(),
        ),
        
        // Paginación (deshabilitada si hay error)
        if (_errorMessage == null)
          PaginationWidget(
            currentPage: _currentPage,
            totalPages: _totalPages,
            totalItems: _totalItems,
            isLoading: _isLoading,
            onPageChange: _loadData,
          ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading && _items.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null && _items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: context.colors.error),
            SizedBox(height: context.spacing.md),
            Text('No se pudieron cargar los datos'),
            SizedBox(height: context.spacing.sm),
            ElevatedButton.icon(
              onPressed: () => _loadData(page: 1),
              icon: Icon(Icons.refresh),
              label: Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) => ItemTile(_items[index]),
    );
  }
}
```

**Estado de Error:**
```
┌─────────────────────────────────────┐
│ ⚠️ Error de red: Sin conexión [↻] │
├─────────────────────────────────────┤
│                                     │
│       🚫                            │
│   No se pudieron cargar datos       │
│   [ ↻ Reintentar ]                  │
│                                     │
└─────────────────────────────────────┘
```

---

## 6. Optimizaciones

### Caché de Páginas
```dart
class CachedPaginationProvider extends ChangeNotifier {
  final Map<int, List<Item>> _cache = {};
  final Map<int, PaginationInfo> _paginationCache = {};
  
  int _currentPage = 1;
  bool _isLoading = false;

  List<Item> get items => _cache[_currentPage] ?? [];
  PaginationInfo? get paginationInfo => _paginationCache[_currentPage];
  bool get isLoading => _isLoading;

  Future<void> loadPage(int page, {bool forceRefresh = false}) async {
    // Usar caché si existe
    if (!forceRefresh && _cache.containsKey(page)) {
      _currentPage = page;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _currentPage = page;
    notifyListeners();

    try {
      final response = await apiService.getItems(page: page);
      _cache[page] = response.data;
      _paginationCache[page] = response.pagination;
      
      // Limitar tamaño del caché (mantener últimas 5 páginas)
      if (_cache.length > 5) {
        final oldestPage = _cache.keys.first;
        _cache.remove(oldestPage);
        _paginationCache.remove(oldestPage);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCache() {
    _cache.clear();
    _paginationCache.clear();
    notifyListeners();
  }
}
```

### Precarga de Páginas Adyacentes
```dart
class PreloadingPaginationProvider extends ChangeNotifier {
  Future<void> loadPage(int page) async {
    // Cargar página solicitada
    await _loadPageData(page);
    
    // Precargar siguiente página en background
    if (page < totalPages) {
      _preloadPage(page + 1);
    }
  }

  Future<void> _preloadPage(int page) async {
    if (_cache.containsKey(page)) return;
    
    try {
      final response = await apiService.getItems(page: page);
      _cache[page] = response.data;
      _paginationCache[page] = response.pagination;
    } catch (e) {
      // Silenciar errores de precarga
      print('Precarga fallida para página $page: $e');
    }
  }
}
```

### Infinite Scroll Híbrido
```dart
class HybridPaginationScreen extends StatefulWidget {
  @override
  _HybridPaginationScreenState createState() => _HybridPaginationScreenState();
}

class _HybridPaginationScreenState extends State<HybridPaginationScreen> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      // Auto-cargar siguiente página al acercarse al final
      if (!isLoading && currentPage < totalPages) {
        loadPage(currentPage + 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: items.length + (isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == items.length) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return ItemTile(items[index]);
            },
          ),
        ),
        
        // Mostrar paginación manual también
        PaginationWidget(
          currentPage: currentPage,
          totalPages: totalPages,
          totalItems: totalItems,
          isLoading: isLoading,
          onPageChange: loadPage,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
```

---

## 📊 Comparativa de Rendimiento

| Técnica | Velocidad | Uso Memoria | UX | Complejidad |
|---------|-----------|-------------|-----|-------------|
| Básica | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐ |
| Con Caché | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |
| Precarga | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| Híbrida | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |

---

## ✅ Checklist de Implementación

- [ ] Definir modelo de paginación
- [ ] Implementar servicio con parámetros de página
- [ ] Crear provider o state management
- [ ] Integrar PaginationWidget en UI
- [ ] Manejar estados de carga
- [ ] Implementar manejo de errores
- [ ] Agregar búsqueda/filtros si es necesario
- [ ] Optimizar con caché (opcional)
- [ ] Probar en diferentes tamaños de pantalla
- [ ] Verificar accesibilidad
- [ ] Medir performance

---

¡Implementa según tus necesidades! 🚀
