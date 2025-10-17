import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../providers/user_provider.dart';
import '../providers/assignment_provider.dart';
import '../models/assignment.dart';
import '../theme/app_theme.dart';
import '../ui/widgets/index.dart';
import 'assignments_screen.dart';
import 'users_screen.dart';
import 'catalog_screens.dart';
import 'reset_seed_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize assignments after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAssignmentsIfNeeded();
    });
  }

  void _loadAssignmentsIfNeeded() {
    if (_isInitialized) return;
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.currentUser != null && userProvider.isEmployee()) {
      final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);
      assignmentProvider.loadUserAssignments(userProvider.currentUser!.uid);
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    if (userProvider.isEmployee()) {
      return _buildEmployeeView();
    } else {
      return _buildAdminView();
    }
  }

  Widget _buildEmployeeView() {
    final userProvider = Provider.of<UserProvider>(context);
    return AppScaffold(
      title: 'Mis Tareas',
      body: Consumer<AssignmentProvider>(
        builder: (context, assignmentProvider, child) {
          if (assignmentProvider.isLoading) {
            return const Center(child: AppSpinner());
          }

          final assignments = assignmentProvider.assignments;
          if (assignments.isEmpty) {
            return const Center(
              child: Text(
                'No tienes tareas asignadas',
                style: AppTextStyles.bodyLarge,
              ),
            );
          }

          return ListView.builder(
            itemCount: assignments.length,
            itemBuilder: (context, index) {
              final assignment = assignments[index];
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String>(
                      future: assignmentProvider.getTaskTitle(assignment.taskId),
                      builder: (context, snapshot) {
                        final title = snapshot.data ?? assignment.taskId;
                        return Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Estado: ${assignment.status}',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        AppButton(
                          label: 'Iniciar',
                          onPressed: assignment.status == 'pending'
                              ? () => assignmentProvider.updateAssignmentStatus(
                                    assignment.id,
                                    'in_progress',
                                    userId: userProvider.currentUser!.uid,
                                  )
                              : () {},
                        ),
                        const SizedBox(width: 8),
                        AppButton(
                          label: 'Finalizar',
                          onPressed: assignment.status == 'in_progress'
                              ? () => assignmentProvider.updateAssignmentStatus(
                                    assignment.id,
                                    'done',
                                    userId: userProvider.currentUser!.uid,
                                  )
                              : () {},
                        ),
                        const SizedBox(width: 8),
                        AppButton(
                          label: 'Evidencia',
                          onPressed: assignment.status == 'in_progress'
                              ? () => _uploadEvidence(context, assignment)
                              : () {},
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAdminView() {
    final userProvider = Provider.of<UserProvider>(context);
    final tabs = [
      const AssignmentsScreen(),
      const UsersScreen(),
      const CatalogScreens(),
      if (userProvider.isSuperAdmin()) const ResetSeedScreen(),
    ];

    return Column(
      children: [
        // Header
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Panel de Administración',
                  style: AppTextStyles.headlineLarge,
                ),
              ),
              GestureDetector(
                onTap: () => _showLogoutDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Cerrar Sesión',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Dashboard KPIs
        Container(
          color: AppColors.background,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: AppTextStyles.headlineMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildKPICard('Total Usuarios', '12', AppColors.primary),
                  const SizedBox(width: 16),
                  _buildKPICard('Tareas Activas', '8', AppColors.success),
                  const SizedBox(width: 16),
                  _buildKPICard('Completadas Hoy', '5', AppColors.warning),
                ],
              ),
            ],
          ),
        ),
        // Navigation
        Container(
          height: 60,
          color: AppColors.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem('Asignaciones', 0),
              _buildNavItem('Usuarios', 1),
              _buildNavItem('Catálogo', 2),
              if (userProvider.isSuperAdmin()) _buildNavItem('Reset', 3),
            ],
          ),
        ),
        // Body
        Expanded(
          child: tabs[_selectedIndex],
        ),
      ],
    );
  }

  Widget _buildNavItem(String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0x00000000),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.surface : AppColors.textPrimary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _uploadEvidence(BuildContext context, Assignment assignment) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      
      if (image != null) {
        // Upload to Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('taskmonitoring')
            .child('evidence')
            .child('${assignment.id}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        
        final uploadTask = storageRef.putFile(File(image.path));
        final snapshot = await uploadTask.whenComplete(() => {});
        final downloadUrl = await snapshot.ref.getDownloadURL();
        
        final evidence = Evidence(
          storagePath: snapshot.ref.fullPath,
          url: downloadUrl,
          takenAt: Timestamp.now(),
        );
        
        await assignmentProvider.updateAssignmentEvidence(
          assignment.id,
          evidence,
          userProvider.currentUser!.uid,
        );
      }
    } catch (e) {
      debugPrint('Error subiendo evidencia: $e');
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: 'Cerrar Sesión',
        message: '¿Estás seguro de que quieres cerrar sesión?',
        actionLabel: 'Cerrar Sesión',
        onAction: () async {
          Navigator.pop(context);
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          await userProvider.signOut();
          if (context.mounted) {
            context.go('/');
          }
        },
        cancelLabel: 'Cancelar',
      ),
    );
  }

  Widget _buildKPICard(String title, String value, Color color) {
    return Expanded(
      child: AppCard(
        backgroundColor: AppColors.surface,
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}