import 'package:cloud_firestore/cloud_firestore.dart';

class Config {
  final List<String> superAdminUids;
  final bool allowSeed;
  final String version;
  final Timestamp createdAt;

  Config({
    required this.superAdminUids,
    required this.allowSeed,
    required this.version,
    Timestamp? createdAt,
  }) : createdAt = createdAt ?? Timestamp.now();

  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      superAdminUids: List<String>.from(json['superAdminUids'] ?? []),
      allowSeed: json['allowSeed'] ?? false,
      version: json['version'] ?? '1.0.0',
      createdAt: json['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'superAdminUids': superAdminUids,
      'allowSeed': allowSeed,
      'version': version,
      'createdAt': createdAt,
    };
  }

  Config copyWith({
    List<String>? superAdminUids,
    bool? allowSeed,
    String? version,
    Timestamp? createdAt,
  }) {
    return Config(
      superAdminUids: superAdminUids ?? this.superAdminUids,
      allowSeed: allowSeed ?? this.allowSeed,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}