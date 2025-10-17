import 'package:cloud_firestore/cloud_firestore.dart';

class Log {
  final String id;
  final String userId;
  final String assignmentId;
  final String action; // 'create' | 'status_change' | 'evidence_upload' | 'edit'
  final Timestamp at;
  final Map<String, dynamic>? metadata;

  Log({
    required this.id,
    required this.userId,
    required this.assignmentId,
    required this.action,
    Timestamp? at,
    this.metadata,
  }) : at = at ?? Timestamp.now();

  factory Log.fromJson(String id, Map<String, dynamic> json) {
    return Log(
      id: id,
      userId: json['userId'] ?? '',
      assignmentId: json['assignmentId'] ?? '',
      action: json['action'] ?? '',
      at: json['at'] ?? Timestamp.now(),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'assignmentId': assignmentId,
      'action': action,
      'at': at,
      'metadata': metadata,
    };
  }
}