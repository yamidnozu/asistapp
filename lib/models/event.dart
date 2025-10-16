class Event {
  String id;
  String description;
  List<Decision> options;
  bool resolved = false;

  Event({required this.id, required this.description, required this.options});
}

class Decision {
  String label;
  Function effect;

  Decision({required this.label, required this.effect});
}