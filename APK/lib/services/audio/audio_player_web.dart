// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'audio_player_interface.dart';

class WebAudioPlayer implements PlatformAudioPlayer {
  html.AudioElement? _audio;
  String? _currentObjectUrl;
  bool _isPlaying = false;
  StreamSubscription? _playSub;
  StreamSubscription? _endedSub;
  StreamSubscription? _errorSub;

  dynamic _sharedAudioContext;
  html.AudioElement? _primedAudio;

  @override
  bool get isPlaying => _isPlaying;

  @override
  void unlockAudioContext() {
    try {
      // 1. Initialize or resume AudioContext on user gesture
      final audioCtxConstructor = js.context['AudioContext'] ?? js.context['webkitAudioContext'];
      if (audioCtxConstructor != null) {
        _sharedAudioContext ??= js.JsObject(audioCtxConstructor, []);
        final state = _sharedAudioContext['state']?.toString();
        if (state == 'suspended') {
          _sharedAudioContext.callMethod('resume', []);
        }

        // Play 1 silent sample to unlock audio engine for the session
        try {
          final buffer = _sharedAudioContext.callMethod('createBuffer', [1, 1, 22050]);
          final source = _sharedAudioContext.callMethod('createBufferSource', []);
          source['buffer'] = buffer;
          source.callMethod('connect', [_sharedAudioContext['destination']]);
          source.callMethod('start', [0]);
        } catch (_) {}
      }

      // 2. Prime an HTML5 AudioElement with a silent WAV sample
      if (_primedAudio == null) {
        final dummyAudio = html.AudioElement();
        dummyAudio.src = 'data:audio/wav;base64,UklGRigAAABXQVZFZm10IBIAAAABAAEARKwAAIhYAQACABAAAABkYXRhAgAAAAEA';
        dummyAudio.play().then((_) {
          dummyAudio.pause();
          dummyAudio.currentTime = 0;
        }).catchError((_) {});
        _primedAudio = dummyAudio;
      }

      // 3. Resume Web Speech Synthesis if suspended
      try {
        final synth = html.window.speechSynthesis;
        if (synth != null && synth.paused == true) {
          synth.resume();
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('[WebAudioPlayer] unlockAudioContext error: $e');
    }
  }

  @override
  Future<void> playMp3Bytes(
    Uint8List bytes, {
    VoidCallback? onStart,
    VoidCallback? onEnded,
    Function(dynamic error)? onError,
  }) async {
    await stop();

    // Ensure audio context is active
    unlockAudioContext();

    try {
      // 1. Create MP3 audio Blob and Object URL from byte array
      final blob = html.Blob([bytes], 'audio/mpeg');
      final url = html.Url.createObjectUrlFromBlob(blob);
      _currentObjectUrl = url;

      // 2. Instantiate HTML5 Audio element
      final audio = html.AudioElement(url);
      _audio = audio;
      audio.autoplay = true;

      // 3. Listen to playback lifecycle events
      _playSub = audio.onPlay.listen((_) {
        _isPlaying = true;
        onStart?.call();
      });

      _endedSub = audio.onEnded.listen((_) {
        _isPlaying = false;
        _cleanup();
        onEnded?.call();
      });

      _errorSub = audio.onError.listen((event) {
        debugPrint('[WebAudioPlayer] HTML5 audio error event, trying Web Audio API buffer playback...');
        _playViaWebAudioApi(bytes, onStart: onStart, onEnded: onEnded, onError: onError);
      });

      // 4. Play MP3 audio
      try {
        await audio.play();
        _isPlaying = true;
        onStart?.call();
      } catch (playErr) {
        debugPrint('[WebAudioPlayer] Audio play rejected ($playErr), falling back to Web Audio API...');
        await _playViaWebAudioApi(bytes, onStart: onStart, onEnded: onEnded, onError: onError);
      }
    } catch (e) {
      debugPrint('[WebAudioPlayer] playMp3Bytes exception ($e), falling back to Web Audio API...');
      await _playViaWebAudioApi(bytes, onStart: onStart, onEnded: onEnded, onError: onError);
    }
  }

  /// Web Audio API buffer playback fallback (works even when HTML5 AudioElement play() is rejected by mobile autoplay)
  Future<void> _playViaWebAudioApi(
    Uint8List bytes, {
    VoidCallback? onStart,
    VoidCallback? onEnded,
    Function(dynamic error)? onError,
  }) async {
    try {
      final audioCtxConstructor = js.context['AudioContext'] ?? js.context['webkitAudioContext'];
      if (audioCtxConstructor == null) {
        _isPlaying = false;
        _cleanup();
        onError?.call('No AudioContext available');
        return;
      }

      _sharedAudioContext ??= js.JsObject(audioCtxConstructor, []);
      final state = _sharedAudioContext['state']?.toString();
      if (state == 'suspended') {
        _sharedAudioContext.callMethod('resume', []);
      }

      // Convert Uint8List bytes to ArrayBuffer via JsObject
      final jsUint8Array = js.context['Uint8Array'];
      final jsBuffer = js.JsObject(jsUint8Array, [bytes]);
      final arrayBuffer = jsBuffer['buffer'];

      final decodeCompleter = Completer<dynamic>();
      _sharedAudioContext.callMethod('decodeAudioData', [
        arrayBuffer,
        js.JsFunction.withThis((self, buffer) {
          if (!decodeCompleter.isCompleted) decodeCompleter.complete(buffer);
        }),
        js.JsFunction.withThis((self, err) {
          if (!decodeCompleter.isCompleted) decodeCompleter.completeError(err ?? 'decodeAudioData failed');
        }),
      ]);

      final decodedBuffer = await decodeCompleter.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('decodeAudioData timeout'),
      );

      final sourceNode = _sharedAudioContext.callMethod('createBufferSource', []);
      sourceNode['buffer'] = decodedBuffer;
      sourceNode.callMethod('connect', [_sharedAudioContext['destination']]);

      sourceNode['onended'] = js.JsFunction.withThis((self, _) {
        _isPlaying = false;
        _cleanup();
        onEnded?.call();
      });

      _isPlaying = true;
      onStart?.call();
      sourceNode.callMethod('start', [0]);
    } catch (fallbackErr) {
      debugPrint('[WebAudioPlayer] Web Audio API playback error: $fallbackErr');
      _isPlaying = false;
      _cleanup();
      onError?.call(fallbackErr);
    }
  }

  void _cleanup() {
    _playSub?.cancel();
    _playSub = null;
    _endedSub?.cancel();
    _endedSub = null;
    _errorSub?.cancel();
    _errorSub = null;

    if (_currentObjectUrl != null) {
      try {
        html.Url.revokeObjectUrl(_currentObjectUrl!);
      } catch (_) {}
      _currentObjectUrl = null;
    }
  }

  @override
  Future<void> stop() async {
    _isPlaying = false;
    if (_audio != null) {
      try {
        _audio!.pause();
        _audio!.currentTime = 0;
        _audio!.src = '';
      } catch (_) {}
      _audio = null;
    }
    _cleanup();
  }
}

PlatformAudioPlayer createPlatformAudioPlayer() => WebAudioPlayer();
