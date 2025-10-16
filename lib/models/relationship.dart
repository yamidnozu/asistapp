class Relationship {
  String name;
  double level = 50.0;

  Relationship({required this.name});

  void update() {
    level += 0.5; // Placeholder
  }
}