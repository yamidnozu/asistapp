class Job {
  final String id;
  final String name;
  final String description;
  final List<String> siteIds;

  Job({
    required this.id,
    required this.name,
    required this.description,
    required this.siteIds,
  });

  factory Job.fromJson(String id, Map<String, dynamic> json) {
    return Job(
      id: id,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      siteIds: List<String>.from(json['siteIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'siteIds': siteIds,
    };
  }

  Job copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? siteIds,
  }) {
    return Job(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      siteIds: siteIds ?? this.siteIds,
    );
  }
}