import 'package:cloud_firestore/cloud_firestore.dart';
import 'date_range.dart';

class Recurrence {
  final String type; // 'once' | 'daily' | 'weekly' | 'custom'
  final List<String> times; // ["08:00", "14:00"]
  final List<int> daysOfWeek; // [1..7] 1=Lunes
  final DateRange? dateRange;

  Recurrence({
    required this.type,
    required this.times,
    required this.daysOfWeek,
    this.dateRange,
  });

  factory Recurrence.fromJson(Map<String, dynamic> json) {
    return Recurrence(
      type: json['type'] ?? 'once',
      times: List<String>.from(json['times'] ?? []),
      daysOfWeek: List<int>.from(json['daysOfWeek'] ?? []),
      dateRange: json['dateRange'] != null ? DateRange.fromJson(json['dateRange']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'times': times,
      'daysOfWeek': daysOfWeek,
      'dateRange': dateRange?.toJson(),
    };
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final String siteId; // Cambiado de responsibilityId a siteId
  final String? location;
  final bool evidenceRequired;
  final int? durationMin;
  final String? priority; // 'low' | 'medium' | 'high'
  final Recurrence recurrence;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.siteId, // Cambiado
    this.location,
    required this.evidenceRequired,
    this.durationMin,
    this.priority,
    required this.recurrence,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Task.fromJson(String id, Map<String, dynamic> json) {
    return Task(
      id: id,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      siteId: json['siteId'] ?? '', // Cambiado
      location: json['location'],
      evidenceRequired: json['evidenceRequired'] ?? false,
      durationMin: json['durationMin'],
      priority: json['priority'],
      recurrence: Recurrence.fromJson(json['recurrence'] ?? {}),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'siteId': siteId, // Cambiado
      'location': location,
      'evidenceRequired': evidenceRequired,
      'durationMin': durationMin,
      'priority': priority,
      'recurrence': recurrence.toJson(),
      'createdAt': createdAt,
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? siteId, // Cambiado
    String? location,
    bool? evidenceRequired,
    int? durationMin,
    String? priority,
    Recurrence? recurrence,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      siteId: siteId ?? this.siteId, // Cambiado
      location: location ?? this.location,
      evidenceRequired: evidenceRequired ?? this.evidenceRequired,
      durationMin: durationMin ?? this.durationMin,
      priority: priority ?? this.priority,
      recurrence: recurrence ?? this.recurrence,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}