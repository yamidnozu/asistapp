import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  void playAmbientMusic(String mood) async {
    try {
      await _player.setSourceAsset('assets/audio/$mood.mp3');
      _player.play(AssetSource('assets/audio/$mood.mp3'));
    } catch (e) {
      // Asset not found, skip
    }
  }

  void stopMusic() {
    _player.stop();
  }
}