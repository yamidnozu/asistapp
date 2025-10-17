class Responsibility {
  final String id;
  final String name;
  final String description;
  final List<String> jobIds;

  Responsibility({
    required this.id,
    required this.name,
    required this.description,
    required this.jobIds,
  });

  factory Responsibility.fromJson(String id, Map<String, dynamic> json) {
    return Responsibility(
      id: id,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      jobIds: List<String>.from(json['jobIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'jobIds': jobIds,
    };
  }

  Responsibility copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? jobIds,
  }) {
    return Responsibility(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      jobIds: jobIds ?? this.jobIds,
    );
  }
}