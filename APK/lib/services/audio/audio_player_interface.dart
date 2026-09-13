import 'package:flutter/foundation.dart';

abstract class PlatformAudioPlayer {
  bool get isPlaying;

  Future<void> playMp3Bytes(
    Uint8List bytes, {
    VoidCallback? onStart,
    VoidCallback? onEnded,
    Function(dynamic error)? onError,
  });

  /// Unlocks audio context / primes media playback during initial user interaction
  void unlockAudioContext();

  Future<void> stop();
}
