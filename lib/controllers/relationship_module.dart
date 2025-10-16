import '../models/module.dart';
import '../models/relationship.dart';

class RelationshipModule extends Module {
  List<Relationship> relations = [];

  @override
  void update() {
    for (var relation in relations) {
      relation.update();
    }
    value = relations.isNotEmpty ? relations.map((r) => r.level).reduce((a, b) => a + b) / relations.length : 0;
    history.add(value);
  }
}