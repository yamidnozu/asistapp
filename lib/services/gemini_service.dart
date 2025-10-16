import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

class GeminiSuggestion {
  final String title;
  final String description;
  final String optionYesLabel;
  final String optionNoLabel;
  final double deltaMoneyYes, deltaPhysYes, deltaMentYes;
  final double deltaMoneyNo,  deltaPhysNo,  deltaMentNo;

  GeminiSuggestion({
    required this.title,
    required this.description,
    required this.optionYesLabel,
    required this.optionNoLabel,
    required this.deltaMoneyYes,
    required this.deltaPhysYes,
    required this.deltaMentYes,
    required this.deltaMoneyNo,
    required this.deltaPhysNo,
    required this.deltaMentNo,
  });
}

class GeminiService {
  final GenerativeModel _model;
  GeminiService._(this._model);

  static GeminiService fromApiKey(String apiKey, {String model='gemini-1.5-flash'}) {
    return GeminiService._(GenerativeModel(model: model, apiKey: apiKey));
  }

  Future<GeminiSuggestion?> suggestContextualEvent({
    required double money,
    required double physical,
    required double mental,
    required int day,
  }) async {
    final prompt = '''
Eres un motor de eventos de vida realista. Genera SOLO un evento breve con:
- title
- description (1 línea)
- option_yes_label
- option_no_label
- delta_money_yes, delta_phys_yes, delta_ment_yes (números enteros o decimales)
- delta_money_no,  delta_phys_no,  delta_ment_no

Contexto numérico:
money=$money, physical=$physical, mental=$mental, day=$day.

El evento debe ser coherente (salud/estrés/dinero). Devuelve en JSON puro.
''';

    final res = await _model.generateContent([Content.text(prompt)]);
    final text = res.text;
    if (text == null) return null;

    // parseo naive (en producción usar jsonDecode con try/catch)
    // Espera algo como:
    // {"title":"Oferta inesperada","description":"...","option_yes_label":"Aceptar","option_no_label":"Rechazar","delta_money_yes":100,"delta_phys_yes":-2,"delta_ment_yes":5,"delta_money_no":0,"delta_phys_no":1,"delta_ment_no":0}
    try {
      final json = _extractJson(text);
      return GeminiSuggestion(
        title: json['title'],
        description: json['description'],
        optionYesLabel: json['option_yes_label'],
        optionNoLabel: json['option_no_label'],
        deltaMoneyYes: (json['delta_money_yes'] as num).toDouble(),
        deltaPhysYes:  (json['delta_phys_yes']  as num).toDouble(),
        deltaMentYes:  (json['delta_ment_yes']  as num).toDouble(),
        deltaMoneyNo:  (json['delta_money_no']  as num).toDouble(),
        deltaPhysNo:   (json['delta_phys_no']   as num).toDouble(),
        deltaMentNo:   (json['delta_ment_no']   as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _extractJson(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    final jsonStr = raw.substring(start, end + 1);
    return Map<String, dynamic>.from(jsonDecode(jsonStr));
  }
}