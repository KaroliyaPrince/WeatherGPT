import 'dart:async';
import 'package:flutter/foundation.dart';
import 'audio_player_interface.dart';

class StubAudioPlayer implements PlatformAudioPlayer {
  bool _isPlaying = false;
  Timer? _timer;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Future<void> playMp3Bytes(
    Uint8List bytes, {
    VoidCallback? onStart,
    VoidCallback? onEnded,
    Function(dynamic error)? onError,
  }) async {
    await stop();
    _isPlaying = true;
    onStart?.call();

    // In non-web / testing environments, simulate playback duration based on byte size
    final durationSec = (bytes.length / 16000).clamp(1.0, 30.0);
    _timer = Timer(Duration(milliseconds: (durationSec * 1000).round()), () {
      if (_isPlaying) {
        _isPlaying = false;
        onEnded?.call();
      }
    });
  }

  @override
  void unlockAudioContext() {
    // No-op for stub / test environment
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _isPlaying = false;
  }
}

PlatformAudioPlayer createPlatformAudioPlayer() => StubAudioPlayer();
