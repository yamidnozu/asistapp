// 📚 Ejemplos de Uso de PaginationWidget
//
// Este archivo muestra cómo reutilizar el PaginationWidget en diferentes pantallas
// No es código que se ejecute, solo ejemplos de referencia

// ============================================================================
// EJEMPLO 1: Uso Básico en users_list_screen.dart (IMPLEMENTADO)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/pagination_widget.dart';
import '../../providers/user_provider.dart';

class UsersListExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        return Column(
          children: [
            // Lista de usuarios
            Expanded(
              child: ListView.builder(
                itemCount: userProvider.users.length,
                itemBuilder: (context, index) {
                  return UserTile(user: userProvider.users[index]);
                },
              ),
            ),
            
            // Paginación - REUTILIZABLE EN 1 LÍNEA
            PaginationWidget(
              currentPage: userProvider.paginationInfo?.page ?? 1,
              totalPages: userProvider.paginationInfo?.totalPages ?? 1,
              totalItems: userProvider.paginationInfo?.total ?? 0,
              isLoading: userProvider.isLoading,
              onPageChange: (page) async {
                await userProvider.loadUsersByInstitution(
                  context.read<AuthProvider>().accessToken!,
                  context.read<AuthProvider>().selectedInstitutionId!,
                  page: page,
                  limit: 10,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// EJEMPLO 2: Instituciones (FUTURO)
// ============================================================================

class InstitutionsListExample extends StatefulWidget {
  @override
  State<InstitutionsListExample> createState() => _InstitutionsListExampleState();
}

class _InstitutionsListExampleState extends State<InstitutionsListExample> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InstitutionProvider>(context, listen: false).loadInstitutions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InstitutionProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Buscar institución
            SearchField(
              hintText: 'Buscar institución...',
              onChanged: (value) {
                provider.searchInstitutions(value);
              },
            ),
            
            // Lista
            Expanded(
              child: ListView.builder(
                itemCount: provider.institutions.length,
                itemBuilder: (context, index) {
                  return InstitutionTile(
                    institution: provider.institutions[index],
                  );
                },
              ),
            ),
            
            // Paginación
            PaginationWidget(
              currentPage: provider.paginationInfo?.page ?? 1,
              totalPages: provider.paginationInfo?.totalPages ?? 1,
              totalItems: provider.paginationInfo?.total ?? 0,
              isLoading: provider.isLoading,
              onPageChange: (page) async {
                await provider.loadInstitutions(page: page, limit: 20);
              },
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// EJEMPLO 3: Búsqueda Global (FUTURO)
// ============================================================================

class GlobalSearchExample extends StatefulWidget {
  @override
  State<GlobalSearchExample> createState() => _GlobalSearchExampleState();
}

class _GlobalSearchExampleState extends State<GlobalSearchExample> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedEntityType = 'usuarios'; // usuarios, instituciones, reportes

  @override
  Widget build(BuildContext context) {
    return Consumer<GlobalSearchProvider>(
      builder: (context, searchProvider, _) {
        return Column(
          children: [
            // Campo de búsqueda
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar ${_selectedEntityType}...',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () async {
                    await searchProvider.search(
                      _searchController.text,
                      entityType: _selectedEntityType,
                      page: 1,
                    );
                  },
                ),
              ),
            ),
            
            // Filtro de tipo
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'usuarios', label: Text('Usuarios')),
                ButtonSegment(value: 'instituciones', label: Text('Instituciones')),
                ButtonSegment(value: 'reportes', label: Text('Reportes')),
              ],
              selected: {_selectedEntityType},
              onSelectionChanged: (newSelection) {
                setState(() => _selectedEntityType = newSelection.first);
              },
            ),
            
            // Resultados
            Expanded(
              child: _buildResults(searchProvider),
            ),
            
            // Paginación
            PaginationWidget(
              currentPage: searchProvider.currentPage,
              totalPages: searchProvider.totalPages,
              totalItems: searchProvider.totalResults,
              isLoading: searchProvider.isLoading,
              onPageChange: (page) async {
                await searchProvider.search(
                  _searchController.text,
                  entityType: _selectedEntityType,
                  page: page,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildResults(GlobalSearchProvider provider) {
    if (provider.results.isEmpty) {
      return Center(child: Text('Sin resultados'));
    }

    return ListView.builder(
      itemCount: provider.results.length,
      itemBuilder: (context, index) {
        final result = provider.results[index];
        return ListTile(
          title: Text(result.title),
          subtitle: Text(result.description),
          trailing: Icon(result.getIcon()),
        );
      },
    );
  }
}

// ============================================================================
// EJEMPLO 4: Reportes Paginados (FUTURO)
// ============================================================================

class ReportsListExample extends StatefulWidget {
  @override
  State<ReportsListExample> createState() => _ReportsListExampleState();
}

class _ReportsListExampleState extends State<ReportsListExample> {
  DateTimeRange? _dateRange;
  String _reportType = 'attendance';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReports();
    });
  }

  Future<void> _loadReports({int page = 1}) async {
    final provider = Provider.of<ReportProvider>(context, listen: false);
    await provider.loadReports(
      page: page,
      type: _reportType,
      startDate: _dateRange?.start,
      endDate: _dateRange?.end,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, reportProvider, _) {
        return Column(
          children: [
            // Filtros
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Selector de tipo de reporte
                    DropdownButton<String>(
                      value: _reportType,
                      items: [
                        DropdownMenuItem(value: 'attendance', child: Text('Asistencia')),
                        DropdownMenuItem(value: 'grades', child: Text('Calificaciones')),
                        DropdownMenuItem(value: 'behavior', child: Text('Conducta')),
                      ],
                      onChanged: (newType) {
                        setState(() => _reportType = newType ?? 'attendance');
                        _loadReports();
                      },
                    ),
                    
                    // Selector de rango de fechas
                    ElevatedButton(
                      onPressed: () async {
                        final range = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (range != null) {
                          setState(() => _dateRange = range);
                          _loadReports();
                        }
                      },
                      child: Text('Seleccionar rango'),
                    ),
                  ],
                ),
              ),
            ),
            
            // Lista de reportes
            Expanded(
              child: ListView.builder(
                itemCount: reportProvider.reports.length,
                itemBuilder: (context, index) {
                  return ReportTile(report: reportProvider.reports[index]);
                },
              ),
            ),
            
            // Paginación - Misma línea para todas las pantallas!
            PaginationWidget(
              currentPage: reportProvider.currentPage,
              totalPages: reportProvider.totalPages,
              totalItems: reportProvider.totalReports,
              isLoading: reportProvider.isLoading,
              onPageChange: _loadReports,
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// EJEMPLO 5: Con PaginationState (Mejor Práctica)
// ============================================================================

import '../../widgets/pagination_widget.dart';

class BestPracticeExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, provider, _) {
        // Acceso a todo el estado de paginación encapsulado
        final pagination = provider.pagination; // PaginationState
        
        return Column(
          children: [
            // Header con información
            if (pagination.totalItems > 0)
              Text(
                'Mostrando ${pagination.itemsPerPage} de ${pagination.totalItems} items',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            
            // Lista
            Expanded(
              child: ListView.builder(
                itemCount: provider.items.length,
                itemBuilder: (context, index) => ItemTile(item: provider.items[index]),
              ),
            ),
            
            // Paginación con PaginationState
            PaginationWidget(
              currentPage: pagination.currentPage,
              totalPages: pagination.totalPages,
              totalItems: pagination.totalItems,
              isLoading: pagination.isLoading,
              onPageChange: (page) async {
                await provider.loadItems(page: page);
              },
            ),
            
            // Información adicional
            if (pagination.hasNextPage)
              Padding(
                padding: EdgeInsets.all(8),
                child: Text('${pagination.totalPages - pagination.currentPage} página(s) más'),
              ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// EJEMPLO 6: Con Provider.select() para Optimización
// ============================================================================

class OptimizedExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Solo reconstruir cuando la paginación cambia
    final pagination = context.select<DataProvider, PaginationState>(
      (provider) => provider.pagination,
    );

    return Consumer<DataProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Lista (se reconstruye cuando items cambian)
            Expanded(
              child: ListView.builder(
                itemCount: provider.items.length,
                itemBuilder: (context, index) => ItemTile(item: provider.items[index]),
              ),
            ),
            
            // Paginación (se reconstruye solo cuando pagination cambia)
            PaginationWidget(
              currentPage: pagination.currentPage,
              totalPages: pagination.totalPages,
              totalItems: pagination.totalItems,
              isLoading: pagination.isLoading,
              onPageChange: (page) async {
                await provider.loadItems(page: page);
              },
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// EJEMPLO 7: Combinado con Búsqueda y Filtros
// ============================================================================

class ComplexExample extends StatefulWidget {
  @override
  State<ComplexExample> createState() => _ComplexExampleState();
}

class _ComplexExampleState extends State<ComplexExample> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload({int page = 1}) async {
    final provider = Provider.of<ComplexDataProvider>(context, listen: false);
    await provider.loadData(
      query: _searchController.text,
      filter: _selectedFilter,
      page: page,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ComplexDataProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Búsqueda
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => _reload(), // Reset a página 1
            ),
            
            // Filtros
            Wrap(
              children: ['all', 'active', 'inactive'].map((filter) {
                return FilterChip(
                  label: Text(filter),
                  selected: _selectedFilter == filter,
                  onSelected: (selected) {
                    setState(() => _selectedFilter = filter);
                    _reload(); // Reset a página 1
                  },
                );
              }).toList(),
            ),
            
            // Lista
            Expanded(
              child: provider.items.isEmpty
                  ? Center(child: Text('Sin resultados'))
                  : ListView.builder(
                      itemCount: provider.items.length,
                      itemBuilder: (context, index) {
                        return ItemTile(item: provider.items[index]);
                      },
                    ),
            ),
            
            // Paginación
            PaginationWidget(
              currentPage: provider.pagination.currentPage,
              totalPages: provider.pagination.totalPages,
              totalItems: provider.pagination.totalItems,
              isLoading: provider.isLoading,
              onPageChange: _reload,
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// NOTAS IMPORTANTES
// ============================================================================

/*
✅ VENTAJAS DE USAR PaginationWidget:

1. REUTILIZACIÓN:
   - Mismo widget en todas las pantallas
   - No duplicar código de paginación

2. CONSISTENCIA:
   - Mismo look & feel en toda la app
   - Mismo comportamiento

3. MANTENIMIENTO:
   - Cambiar paginación en 1 lugar
   - Afecta a todas las pantallas

4. TESTABILIDAD:
   - Test al widget en aislamiento
   - Otros tests no necesitan manejar paginación

5. EXTENSIBILIDAD:
   - Agregar tema/estilo personalizado
   - Agregar nuevas funcionalidades

✅ PATRONES DE USO RECOMENDADOS:

1. Simple: Solo pasar datos + callback
2. Intermedio: Usar PaginationState en Provider
3. Avanzado: Combinar con select() para optimización
4. Experto: Subclasificar con temas personalizados

✅ CASOS DE USO:

- Listas paginadas de cualquier entidad
- Búsqueda con resultados paginados
- Datos de API con límite de items
- Cualquier UI que muestre múltiples páginas

*/
