import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    return Container(
      color: const Color(0xFF000000),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bienvenido, ${authProvider.user?.displayName ?? 'Usuario'}',
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 20,
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    await authProvider.signOut();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDB4437),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'Salir',
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: taskProvider.tasks.length,
              itemBuilder: (context, index) {
                final task = taskProvider.tasks[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: TextStyle(
                                color: task.isCompleted ? Color(0xFF888888) : Color(0xFFFFFFFF),
                                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            Text(
                              task.description,
                              style: const TextStyle(color: Color(0xFFCCCCCC)),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          taskProvider.toggleTaskCompletion(task.id);
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(0xFFFFFFFF)),
                            color: task.isCompleted ? Color(0xFFFFFFFF) : Color(0xFF000000),
                          ),
                          child: task.isCompleted
                              ? const Text('✓', style: TextStyle(color: Color(0xFF000000), fontSize: 16))
                              : null,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
              onTap: () {
                // Agregar nueva tarea
                final newTask = Task(
                  id: DateTime.now().toString(),
                  title: 'Nueva Tarea',
                  description: 'Descripción',
                );
                taskProvider.addTask(newTask);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text(
                  'Agregar Tarea',
                  style: TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}