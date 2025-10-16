import 'package:google_generative_ai/google_generative_ai.dart';

const String kGeminiKey = String.fromEnvironment('GEMINI_API_KEY');

class GeminiService {
  final GenerativeModel _model;
  GeminiService._(this._model);

  static GeminiService? fromApiKey() {
    const key = kGeminiKey;
    if (key.isNotEmpty) {
      return GeminiService._(GenerativeModel(model: 'gemini-2.5-flash-lite', apiKey: key));
    }
    return null;
  }

  Future<String?> generateContent(String prompt) async {
    final res = await _model.generateContent([Content.text(prompt)]);
    return res.text;
  }
}