import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'date_range.dart';

part 'assignment.g.dart';

@HiveType(typeId: 0)
class Assignment {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String userId;
  @HiveField(2)
  final String taskId;
  @HiveField(3)
  final String siteId;
  @HiveField(4)
  final Schedule schedule;
  @HiveField(5)
  final Timestamp? windowStart;
  @HiveField(6)
  final Timestamp? windowEnd;
  @HiveField(7)
  final String status; // 'pending' | 'in_progress' | 'blocked' | 'done'
  @HiveField(8)
  final String? blockedReason;
  @HiveField(9)
  final Evidence? evidence;
  @HiveField(10)
  final Timestamp lastUpdateAt;
  @HiveField(11)
  final Timestamp createdAt;

  Assignment({
    required this.id,
    required this.userId,
    required this.taskId,
    required this.siteId,
    required this.schedule,
    this.windowStart,
    this.windowEnd,
    required this.status,
    this.blockedReason,
    this.evidence,
    Timestamp? lastUpdateAt,
    Timestamp? createdAt,
  }) : 
    lastUpdateAt = lastUpdateAt ?? Timestamp.now(),
    createdAt = createdAt ?? Timestamp.now();

  factory Assignment.fromJson(String id, Map<String, dynamic> json) {
    return Assignment(
      id: id,
      userId: json['userId'] ?? '',
      taskId: json['taskId'] ?? '',
      siteId: json['siteId'] ?? '',
      schedule: Schedule.fromJson(json['schedule'] ?? {}),
      windowStart: json['windowStart'],
      windowEnd: json['windowEnd'],
      status: json['status'] ?? 'pending',
      blockedReason: json['blockedReason'],
      evidence: json['evidence'] != null ? Evidence.fromJson(json['evidence']) : null,
      lastUpdateAt: json['lastUpdateAt'] ?? Timestamp.now(),
      createdAt: json['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'taskId': taskId,
      'siteId': siteId,
      'schedule': schedule.toJson(),
      'windowStart': windowStart,
      'windowEnd': windowEnd,
      'status': status,
      'blockedReason': blockedReason,
      'evidence': evidence?.toJson(),
      'lastUpdateAt': lastUpdateAt,
      'createdAt': createdAt,
    };
  }

  Assignment copyWith({
    String? id,
    String? userId,
    String? taskId,
    String? siteId,
    Schedule? schedule,
    Timestamp? windowStart,
    Timestamp? windowEnd,
    String? status,
    String? blockedReason,
    Evidence? evidence,
    Timestamp? lastUpdateAt,
    Timestamp? createdAt,
  }) {
    return Assignment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      taskId: taskId ?? this.taskId,
      siteId: siteId ?? this.siteId,
      schedule: schedule ?? this.schedule,
      windowStart: windowStart ?? this.windowStart,
      windowEnd: windowEnd ?? this.windowEnd,
      status: status ?? this.status,
      blockedReason: blockedReason ?? this.blockedReason,
      evidence: evidence ?? this.evidence,
      lastUpdateAt: lastUpdateAt ?? this.lastUpdateAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

@HiveType(typeId: 1)
class Schedule {
  @HiveField(0)
  final Timestamp? at;
  @HiveField(1)
  final List<String>? times;
  @HiveField(2)
  final List<int>? daysOfWeek;
  @HiveField(3)
  final DateRange? dateRange;

  Schedule({
    this.at,
    this.times,
    this.daysOfWeek,
    this.dateRange,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      at: json['at'],
      times: json['times'] != null ? List<String>.from(json['times']) : null,
      daysOfWeek: json['daysOfWeek'] != null ? List<int>.from(json['daysOfWeek']) : null,
      dateRange: json['dateRange'] != null ? DateRange.fromJson(json['dateRange']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'at': at,
      'times': times,
      'daysOfWeek': daysOfWeek,
      'dateRange': dateRange?.toJson(),
    };
  }
}

@HiveType(typeId: 2)
class Evidence {
  @HiveField(0)
  final String? storagePath;
  @HiveField(1)
  final String? url;
  @HiveField(2)
  final Timestamp? takenAt;

  Evidence({
    this.storagePath,
    this.url,
    this.takenAt,
  });

  factory Evidence.fromJson(Map<String, dynamic> json) {
    return Evidence(
      storagePath: json['storagePath'],
      url: json['url'],
      takenAt: json['takenAt'],
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