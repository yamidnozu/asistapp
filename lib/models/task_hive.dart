import 'package:hive/hive.dart';

part 'task_hive.g.dart';

/// Modelo de tarea para persistencia local con Hive
@HiveType(typeId: 0)
class TaskHive {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  bool isCompleted;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime? dueDate;

  TaskHive({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    required this.createdAt,
    this.dueDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
      };

  factory TaskHive.fromJson(Map<String, dynamic> json) => TaskHive(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'],
        isCompleted: json['isCompleted'] ?? false,
        createdAt:
            DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
        dueDate:
            json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      );
}
