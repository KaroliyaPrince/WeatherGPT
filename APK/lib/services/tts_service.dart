import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'audio/audio_player.dart';
import 'audio/audio_player_interface.dart';

/// Text-To-Speech Service utilizing the backend's OpenAI MP3 generation API
/// (https://weathergpt-backend-46or.onrender.com/api/voice/speak)
/// and playing the resulting MP3 audio blob via HTML5 Audio.
/// Features a seamless fallback if the backend TTS returns an error or is unreachable.
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final PlatformAudioPlayer _player = getAudioPlayer();
  final http.Client _client = http.Client();
  FlutterTts? _fallbackTts;
  FlutterTts get _ttsInstance => _fallbackTts ??= FlutterTts();
  bool _fallbackInitialized = false;

  static const String voiceApiUrl = 'https://weathergpt-backend-46or.onrender.com/api/voice/speak';

  bool _isFetchingOrPlaying = false;
  int _utteranceId = 0;
  Function()? onStart;
  Function()? onCompletion;

  bool get isPlaying => _isFetchingOrPlaying || _player.isPlaying;

  Future<void> init() async {
    // Ready
  }

  /// Unlocks the audio engine during user click/touch events to allow auto-play
  void unlockAudioContext() {
    _player.unlockAudioContext();
  }

  /// Speaks text aloud by fetching high-quality MP3 audio from the backend
  /// and playing it through the HTML5 Audio element.
  /// If the backend is unavailable or returns 500, gracefully falls back to native speech.
  /// Speaks text aloud.
  /// On native mobile platforms (Android/iOS), uses FlutterTts directly for loud, instant, native audio.
  /// On Web, attempts backend OpenAI MP3 generation via HTML5 Audio and falls back to Web Speech.
  Future<void> speak(String text, {String language = 'en'}) async {
    // 1. Stop any currently playing audio
    await stop();

    final spokenText = _extractSpokenText(text);
    final cleanText = _stripMarkdown(spokenText);
    if (cleanText.isEmpty) {
      onCompletion?.call();
      return;
    }

    _utteranceId++;
    final currentUtterance = _utteranceId;
    _isFetchingOrPlaying = true;

    // On mobile platforms (Android/iOS), use FlutterTts directly for guaranteed native audio playback
    if (!kIsWeb) {
      await _fallbackNativeSpeak(cleanText, language: language, utteranceId: currentUtterance);
      return;
    }

    try {
      // 2. On Web: Send POST request to backend voice MP3 generation API
      final response = await _client.post(
        Uri.parse(voiceApiUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'audio/mpeg, audio/*; q=0.9, */*; q=0.1',
        },
        body: jsonEncode({'text': cleanText}),
      ).timeout(const Duration(seconds: 8));

      if (currentUtterance != _utteranceId) {
        return;
      }

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        // 3. Backend returned MP3 audio blob. Play using HTML5 Audio element
        await _player.playMp3Bytes(
          response.bodyBytes,
          onStart: () {
            _isFetchingOrPlaying = true;
            onStart?.call();
          },
          onEnded: () {
            if (currentUtterance == _utteranceId) {
              _isFetchingOrPlaying = false;
              onCompletion?.call();
            }
          },
          onError: (err) {
            debugPrint('Audio playback error: $err. Using fallback.');
            if (currentUtterance == _utteranceId) {
              _fallbackNativeSpeak(cleanText, language: language, utteranceId: currentUtterance);
            }
          },
        );
        return;
      } else {
        debugPrint('Voice speak API status ${response.statusCode}: ${response.body}. Using fallback.');
        if (currentUtterance == _utteranceId) {
          await _fallbackNativeSpeak(cleanText, language: language, utteranceId: currentUtterance);
        }
      }
    } catch (e) {
      debugPrint('Voice API exception: $e. Using fallback.');
      if (currentUtterance == _utteranceId) {
        await _fallbackNativeSpeak(cleanText, language: language, utteranceId: currentUtterance);
      }
    }
  }

  Future<void> _fallbackNativeSpeak(String text, {required String language, required int utteranceId}) async {
    try {
      final tts = _ttsInstance;
      if (!_fallbackInitialized) {
        await tts.setSpeechRate(0.48);
        await tts.setVolume(1.0);
        await tts.setPitch(1.0);
        try {
          await tts.awaitSpeakCompletion(false);
        } catch (_) {}
        tts.setStartHandler(() {
          _isFetchingOrPlaying = true;
          onStart?.call();
        });
        // Important: Handler must not capture a stale utteranceId in closure
        tts.setCompletionHandler(() {
          _isFetchingOrPlaying = false;
          onCompletion?.call();
        });
        tts.setErrorHandler((err) {
          debugPrint('[TTS] FlutterTts error: $err');
          _isFetchingOrPlaying = false;
          onCompletion?.call();
        });
        _fallbackInitialized = true;
      }

      String effectiveLang = language;
      if (effectiveLang == 'auto') {
        if (RegExp(r'[\u0A80-\u0AFF]').hasMatch(text)) {
          effectiveLang = 'gu';
        } else if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) {
          effectiveLang = 'hi';
        } else {
          effectiveLang = 'en';
        }
      }

      if (effectiveLang == 'gu') {
        bool guSet = false;
        try {
          final isAvailable = await tts.isLanguageAvailable('gu-IN');
          final ok = (isAvailable is int && isAvailable >= 0) || isAvailable == true || isAvailable == 1;
          if (ok) {
            await tts.setLanguage('gu-IN');
            guSet = true;
          }
        } catch (_) {}
        if (!guSet) {
          try {
            await tts.setLanguage('hi-IN');
          } catch (_) {
            await tts.setLanguage('en-US');
          }
        }
      } else if (effectiveLang == 'hi') {
        try {
          await tts.setLanguage('hi-IN');
        } catch (_) {
          await tts.setLanguage('en-US');
        }
      } else {
        await tts.setLanguage('en-US');
      }

      _isFetchingOrPlaying = true;
      onStart?.call();

      // Watchdog timer: guarantees onCompletion fires even if native TTS engine fails to emit completion event
      final watchdogMs = ((text.length * 60) + 2000).clamp(2500, 25000);
      Timer(Duration(milliseconds: watchdogMs), () {
        if (utteranceId == _utteranceId && _isFetchingOrPlaying) {
          debugPrint('[TTS] Watchdog timer completed speech.');
          _isFetchingOrPlaying = false;
          onCompletion?.call();
        }
      });

      try {
        tts.speak(text);
      } catch (e) {
        debugPrint('[TTS] Speak invocation error: $e');
      }
    } catch (e) {
      debugPrint('Native TTS exception: $e');
      onStart?.call();
      final waitMs = (text.length * 50).clamp(1800, 10000);
      Timer(Duration(milliseconds: waitMs), () {
        if (utteranceId == _utteranceId) {
          _isFetchingOrPlaying = false;
          onCompletion?.call();
        }
      });
    }
  }

  Future<void> stop() async {
    _utteranceId++;
    _isFetchingOrPlaying = false;
    await _player.stop();
    if (_fallbackTts != null) {
      try {
        await _fallbackTts!.stop();
      } catch (_) {}
    }
  }

  /// Extracts the conversational body for natural speech synthesis
  String _extractSpokenText(String text) {
    String spoken = text;
    final citationMarkers = [
      '\n\n📚',
      '\n📚',
      '📚 **',
      '\n\n**નિષ્ણાત',
      '\n\n**विशेषज्ञ',
      '\n\n**Expert',
      '\n_સ્ત્રોત:',
      '\n_स्रोत:',
      '\n_Source:',
      '\n\nSource:',
    ];
    for (final marker in citationMarkers) {
      if (spoken.contains(marker)) {
        spoken = spoken.split(marker).first.trim();
      }
    }
    return spoken.isNotEmpty ? spoken : text;
  }

  /// Cleans markdown formatting while safely preserving Gujarati, Hindi,
  /// English, punctuation, and all valid Unicode characters.
  String _stripMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*([^*]+)\*'), r'$1')
        .replaceAll(RegExp(r'#+\s*'), '')
        .replaceAll(RegExp(r'`([^`]+)`'), r'$1')
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1')
        .replaceAll(RegExp(r'[#*_~`>]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
