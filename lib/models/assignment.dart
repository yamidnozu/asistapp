import 'package:cloud_firestore/cloud_firestore.dart';

class Evidence {
  final String storagePath;
  final String url;
  final Timestamp takenAt;

  Evidence({
    required this.storagePath,
    required this.url,
    required this.takenAt,
  });

  factory Evidence.fromJson(Map<String, dynamic> json) {
    return Evidence(
      storagePath: json['storagePath'] ?? '',
      url: json['url'] ?? '',
      takenAt: json['takenAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storagePath': storagePath,
      'url': url,
      'takenAt': takenAt,
    };
  }
}

class Assignment {
  final String id;
  final String taskId;
  final String userId;
  final String status; // 'pending' | 'in_progress' | 'done'
  final DateTime assignedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final Evidence? evidence;

  Assignment({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.status,
    DateTime? assignedAt,
    this.startedAt,
    this.completedAt,
    this.evidence,
  }) : assignedAt = assignedAt ?? DateTime.now();

  factory Assignment.fromJson(String id, Map<String, dynamic> json) {
    return Assignment(
      id: id,
      taskId: json['taskId'] ?? '',
      userId: json['userId'] ?? '',
      status: json['status'] ?? 'pending',
      assignedAt: (json['assignedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startedAt: (json['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (json['completedAt'] as Timestamp?)?.toDate(),
      evidence: json['evidence'] != null ? Evidence.fromJson(json['evidence']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'userId': userId,
      'status': status,
      'assignedAt': assignedAt,
      'startedAt': startedAt,
      'completedAt': completedAt,
      'evidence': evidence?.toJson(),
    };
  }

  Assignment copyWith({
    String? id,
    String? taskId,
    String? userId,
    String? status,
    DateTime? assignedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    Evidence? evidence,
  }) {
    return Assignment(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      assignedAt: assignedAt ?? this.assignedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      evidence: evidence ?? this.evidence,
    );
  }
}