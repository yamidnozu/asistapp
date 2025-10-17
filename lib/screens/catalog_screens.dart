import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart' show showDialog, TextEditingController;
import '../providers/catalog_provider.dart';
import '../models/site.dart';
import '../ui/widgets/index.dart';

class CatalogScreens extends StatefulWidget {
  const CatalogScreens({super.key});

  @override
  State<CatalogScreens> createState() => _CatalogScreensState();
}

class _CatalogScreensState extends State<CatalogScreens> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final catalogProvider = Provider.of<CatalogProvider>(context, listen: false);
    await catalogProvider.loadSites();
    await catalogProvider.loadJobs();
    await catalogProvider.loadResponsibilities();
    await catalogProvider.loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildSitesTab(),
      _buildJobsTab(),
      _buildResponsibilitiesTab(),
      _buildTasksTab(),
    ];

    return AppScaffold(
      title: 'Catálogo',
      body: tabs[_selectedTab],
      actions: [
        Row(
          children: [
            _buildTabButton('Sitios', 0),
            _buildTabButton('Empleos', 1),
            _buildTabButton('Resp.', 2),
            _buildTabButton('Tareas', 3),
          ],
        ),
      ],
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF35A0FF) : const Color(0xFF151515),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFFFFFFF) : const Color(0xFFEDEDED),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSitesTab() {
    return Consumer<CatalogProvider>(
      builder: (context, catalogProvider, child) {
        if (catalogProvider.isLoading) {
          return const Center(child: AppSpinner());
        }

        final sites = catalogProvider.sites;

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: sites.length,
                itemBuilder: (context, index) {
                  final site = sites[index];
                  return AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                site.name,
                                style: const TextStyle(
                                  color: Color(0xFFEDEDED),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                site.address,
                                style: const TextStyle(color: Color(0xFFCCCCCC)),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            AppButton(
                              label: 'Editar',
                              onPressed: () => _showSiteDialog(context, site),
                            ),
                            const SizedBox(width: 8),
                            AppButton(
                              label: 'Eliminar',
                              onPressed: () => _deleteSite(context, site.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppButton(
                label: 'Agregar Sitio',
                onPressed: () => _showSiteDialog(context, null),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildJobsTab() {
    return Consumer<CatalogProvider>(
      builder: (context, catalogProvider, child) {
        if (catalogProvider.isLoading) {
          return const Center(child: AppSpinner());
        }

        final jobs = catalogProvider.jobs;

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: jobs.length,
                itemBuilder: (context, index) {
                  final job = jobs[index];
                  return AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job.name,
                                style: const TextStyle(
                                  color: Color(0xFFEDEDED),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                job.description,
                                style: const TextStyle(color: Color(0xFFCCCCCC)),
                              ),
                            ],
                          ),
                        ),
                        AppButton(
                          label: 'Eliminar',
                          onPressed: () => _deleteJob(context, job.id),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppButton(
                label: 'Agregar Empleo',
                onPressed: () => _showJobDialog(context, null),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResponsibilitiesTab() {
    return const Center(
      child: Text(
        'Gestión de Responsabilidades - Pendiente',
        style: TextStyle(color: Color(0xFFEDEDED)),
      ),
    );
  }

  Widget _buildTasksTab() {
    return const Center(
      child: Text(
        'Gestión de Tareas - Pendiente',
        style: TextStyle(color: Color(0xFFEDEDED)),
      ),
    );
  }

  void _showSiteDialog(BuildContext context, Site? site) {
    final nameController = TextEditingController(text: site?.name ?? '');
    final addressController = TextEditingController(text: site?.address ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          color: const Color(0x80000000),
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF151515),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    site == null ? 'Agregar Sitio' : 'Editar Sitio',
                    style: const TextStyle(
                      color: Color(0xFFEDEDED),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppTextInput(
                    label: 'Nombre',
                    controller: nameController,
                  ),
                  const SizedBox(height: 16),
                  AppTextInput(
                    label: 'Dirección',
                    controller: addressController,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Cancelar',
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppButton(
                          label: site == null ? 'Crear' : 'Actualizar',
                          onPressed: () async {
                            final catalogProvider = Provider.of<CatalogProvider>(context, listen: false);
                            if (site == null) {
                              final newSite = Site(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                name: nameController.text,
                                address: addressController.text,
                                active: true,
                              );
                              await catalogProvider.createSite(newSite);
                            } else {
                              await catalogProvider.updateSite(site.id, {
                                'name': nameController.text,
                                'address': addressController.text,
                              });
                            }
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _deleteSite(BuildContext context, String siteId) {
    final catalogProvider = Provider.of<CatalogProvider>(context, listen: false);
    catalogProvider.deleteSite(siteId);
  }

  void _showJobDialog(BuildContext context, dynamic job) {
    // TODO: Implement form dialog
  }

  void _deleteJob(BuildContext context, String jobId) {
    final catalogProvider = Provider.of<CatalogProvider>(context, listen: false);
    // TODO: Implement deleteJob in provider
  }
}