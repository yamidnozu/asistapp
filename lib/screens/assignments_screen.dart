import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../providers/assignment_provider.dart';
import '../providers/user_provider.dart';
import '../ui/widgets/index.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAssignments();
    });
  }

  Future<void> _loadAssignments() async {
    if (_isInitialized) return;
    _isInitialized = true;
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);
    
    if (userProvider.currentUser != null) {
      if (userProvider.isSuperAdmin() || userProvider.isSiteAdmin()) {
        // Load all assignments for admin (using first site as default)
        await assignmentProvider.loadSiteAssignments('site1');
      } else {
        // Load user assignments
        await assignmentProvider.loadUserAssignments(userProvider.currentUser!.uid);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AssignmentProvider>(
      builder: (context, assignmentProvider, child) {
        if (assignmentProvider.isLoading) {
          return AppScaffold(
            title: 'Asignaciones',
            body: const Center(child: AppSpinner()),
          );
        }

        final assignments = assignmentProvider.assignments;
        
        return AppScaffold(
          title: 'Asignaciones',
          body: assignments.isEmpty
              ? const Center(
                  child: Text(
                    'No hay asignaciones',
                    style: TextStyle(color: Color(0xFFEDEDED)),
                  ),
                )
              : ListView.builder(
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
                                  color: Color(0xFFEDEDED),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Usuario: ${assignment.userId}',
                            style: const TextStyle(color: Color(0xFFCCCCCC)),
                          ),
                          Text(
                            'Estado: ${assignment.status}',
                            style: const TextStyle(color: Color(0xFFCCCCCC)),
                          ),
                          if (assignment.evidence != null) ...[
                            const SizedBox(height: 8),
                            const Text(
                              '✓ Evidencia subida',
                              style: TextStyle(color: Color(0xFF4CAF50)),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}