import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';

class TaskProvider with ChangeNotifier {
  late Box _taskBox;
  List<Task> _tasks = [];

  List<Task> get tasks => _tasks;

  TaskProvider() {
    _init();
  }

  Future<void> _init() async {
    _taskBox = await Hive.openBox('tasks');
    _loadTasks();
  }

  void _loadTasks() {
    final taskMaps = _taskBox.toMap();
    _tasks = taskMaps.values.map((e) => Task.fromJson(Map<String, dynamic>.from(e))).toList();
    notifyListeners();
  }

  Future<void> addTask(Task task) async {
    await _taskBox.put(task.id, task.toJson());
    _loadTasks();
  }

  Future<void> updateTask(Task task) async {
    await _taskBox.put(task.id, task.toJson());
    _loadTasks();
  }

  Future<void> deleteTask(String id) async {
    await _taskBox.delete(id);
    _loadTasks();
  }

  Future<void> toggleTaskCompletion(String id) async {
    final taskMap = _taskBox.get(id);
    if (taskMap != null) {
      final task = Task.fromJson(Map<String, dynamic>.from(taskMap));
      task.isCompleted = !task.isCompleted;
      await _taskBox.put(id, task.toJson());
      _loadTasks();
    }
  }
}