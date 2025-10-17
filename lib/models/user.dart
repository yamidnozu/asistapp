import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String displayName;
  final String email;
  final String? photoURL;
  final List<String> roles;
  final List<String> sites;
  final String status;
  final DateTime createdAt;

  User({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoURL,
    required this.roles,
    required this.sites,
    required this.status,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] ?? '',
      displayName: json['displayName'] ?? '',
      email: json['email'] ?? '',
      photoURL: json['photoURL'],
      roles: List<String>.from(json['roles'] ?? []),
      sites: List<String>.from(json['sites'] ?? []),
      status: json['status'] ?? 'active',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'roles': roles,
      'sites': sites,
      'status': status,
      'createdAt': createdAt,
    };
  }

  User copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoURL,
    List<String>? roles,
    List<String>? sites,
    String? status,
    DateTime? createdAt,
  }) {
    return User(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      roles: roles ?? this.roles,
      sites: sites ?? this.sites,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}