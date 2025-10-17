import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart' show showDialog;
import '../providers/admin_provider.dart';
import '../providers/catalog_provider.dart';
import '../models/user.dart' as model;
import '../ui/widgets/index.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  @override
  void initState() {
    super.initState();
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    adminProvider.loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        if (adminProvider.isLoading) {
          return AppScaffold(
            title: 'Gestión de Usuarios',
            body: const Center(child: AppSpinner()),
          );
        }

        final users = adminProvider.users;

        return AppScaffold(
          title: 'Gestión de Usuarios',
          body: ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        color: Color(0xFFEDEDED),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(color: Color(0xFFCCCCCC)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Roles: ${user.roles.join(', ')}',
                      style: const TextStyle(color: Color(0xFFCCCCCC)),
                    ),
                    Text(
                      'Sitios: ${user.sites.join(', ')}',
                      style: const TextStyle(color: Color(0xFFCCCCCC)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        AppButton(
                          label: 'Editar Roles',
                          onPressed: () => _showRoleDialog(user),
                        ),
                        const SizedBox(width: 8),
                        AppButton(
                          label: user.status == 'active' ? 'Desactivar' : 'Activar',
                          onPressed: () => adminProvider.setUserStatus(
                            user.uid,
                            user.status == 'active' ? 'inactive' : 'active',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showRoleDialog(model.User user) {
    final availableRoles = ['employee', 'site_admin', 'super_admin'];
    final selectedRoles = List<String>.from(user.roles);
    final catalogProvider = Provider.of<CatalogProvider>(context, listen: false);
    final availableSites = catalogProvider.sites.map((s) => s.id).toList();
    final selectedSites = List<String>.from(user.sites);

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
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Editar Roles - ${user.displayName}',
                    style: const TextStyle(
                      color: Color(0xFFEDEDED),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Roles:',
                    style: TextStyle(
                      color: Color(0xFFEDEDED),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...availableRoles.map((role) => _buildCheckbox(
                    title: role,
                    value: selectedRoles.contains(role),
                    onChanged: (value) {
                      setState(() {
                        if (value) {
                          selectedRoles.add(role);
                        } else {
                          selectedRoles.remove(role);
                        }
                      });
                    },
                  )),
                  const SizedBox(height: 16),
                  const Text(
                    'Sitios:',
                    style: TextStyle(
                      color: Color(0xFFEDEDED),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...availableSites.map((siteId) => _buildCheckbox(
                    title: siteId, // TODO: Show site name
                    value: selectedSites.contains(siteId),
                    onChanged: (value) {
                      setState(() {
                        if (value) {
                          selectedSites.add(siteId);
                        } else {
                          selectedSites.remove(siteId);
                        }
                      });
                    },
                  )),
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
                          label: 'Guardar',
                          onPressed: () async {
                            final adminProvider = Provider.of<AdminProvider>(context, listen: false);
                            await adminProvider.assignRoles(user.uid, selectedRoles);
                            await adminProvider.assignSites(user.uid, selectedSites);
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

  Widget _buildCheckbox({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF35A0FF),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
                color: value ? const Color(0xFF35A0FF) : const Color(0xFF151515),
              ),
              child: value
                  ? const Center(
                      child: Text(
                        '✓',
                        style: TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(color: Color(0xFFEDEDED)),
            ),
          ],
        ),
      ),
    );
  }
}