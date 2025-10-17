import 'package:cloud_firestore/cloud_firestore.dart';

class Site {
  final String id;
  final String name;
  final String address;
  final GeoPoint? geo;
  final bool active;

  Site({
    required this.id,
    required this.name,
    required this.address,
    this.geo,
    required this.active,
  });

  factory Site.fromJson(String id, Map<String, dynamic> json) {
    return Site(
      id: id,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      geo: json['geo'],
      active: json['active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'geo': geo,
      'active': active,
    };
  }

  Site copyWith({
    String? id,
    String? name,
    String? address,
    GeoPoint? geo,
    bool? active,
  }) {
    return Site(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      geo: geo ?? this.geo,
      active: active ?? this.active,
    );
  }
}