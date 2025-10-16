import '../data/models.dart';
import '../services/gemini_service.dart';

class EventResult {
  final String title;
  final String desc;
  final List<EventOption> options;
  EventResult(this.title, this.desc, this.options);
}

class EventOption {
  final String label;
  final void Function(PlayerState s) apply;
  EventOption(this.label, this.apply);
}

class EventEngine {
  final GeminiService? ai; // opcional

  EventEngine({this.ai});

  Future<EventResult?> maybeSpawn(PlayerState s) async {
    // Reglas base: si salud baja, si dinero bajo, etc.
    if (s.physical.value < 40) {
      return EventResult(
        'Dolor estomacal',
        'Últimos días comiste mal y dormiste poco.',
        [
          EventOption('Ir al médico (-\$80, +salud)', (ps) {
            ps.money -= 80;
            ps.physical.value = (ps.physical.value + 18).clamp(0, 100);
          }),
          EventOption('Ignorar (riesgo)', (ps) {
            ps.physical.value -= 6;
            ps.mental.value   -= 2;
          }),
        ],
      );
    }

    // Ejemplo: delegar a Gemini para un evento contextual "críble"
    if (ai != null && s.money < 250 && s.mental.value < 55) {
      final suggestion = await ai!.suggestContextualEvent(
        money: s.money,
        physical: s.physical.value,
        mental: s.mental.value,
        reputation: s.reputation.toDouble(),
        day: s.day,
      );
      if (suggestion != null) {
        return EventResult(
          suggestion.title,
          suggestion.description,
          [
            EventOption(suggestion.optionYesLabel, (ps) {
              ps.money += suggestion.deltaMoneyYes;
              ps.physical.value = (ps.physical.value + suggestion.deltaPhysYes).clamp(0,100);
              ps.mental.value   = (ps.mental.value   + suggestion.deltaMentYes).clamp(0,100);
            }),
            EventOption(suggestion.optionNoLabel, (ps) {
              ps.money += suggestion.deltaMoneyNo;
              ps.physical.value = (ps.physical.value + suggestion.deltaPhysNo).clamp(0,100);
              ps.mental.value   = (ps.mental.value   + suggestion.deltaMentNo).clamp(0,100);
            }),
          ],
        );
      }
    }

    return null;
  }
}