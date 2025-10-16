class Project {
  String name;
  double progress = 0.0;
  double requiredFunds;
  int stage = 0; // 0: idea, 1: dev, 2: launch, 3: mature

  Project({required this.name, required this.requiredFunds});

  void progressDay() {
    progress += 0.01; // Placeholder
    if (progress >= 1.0 && stage < 3) {
      stage++;
      progress = 0.0;
    }
  }
}