import 'package:audioplayers/audioplayers.dart';

class ChessAudioManager {
  static final ChessAudioManager _instance = ChessAudioManager._internal();
  factory ChessAudioManager() => _instance;
  ChessAudioManager._internal();

  final AudioPlayer _bgPlayer = AudioPlayer();
  bool _isPlaying = false;

  Future<void> playBackgroundMusic() async {
    if (_isPlaying) return;
    try {
      await _bgPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgPlayer.setVolume(0.4);
      await _bgPlayer.play(AssetSource('audio/andean_music.mp3'));
      _isPlaying = true;
    } catch (e) {
      // Music unavailable, continue silently
    }
  }

  Future<void> stopMusic() async {
    await _bgPlayer.stop();
    _isPlaying = false;
  }

  Future<void> dispose() async {
    await _bgPlayer.dispose();
  }
}
