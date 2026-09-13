import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../providers/settings_provider.dart';
import '../../../services/tts_service.dart';
import '../../../services/voice_recorder/voice_recorder.dart';
import '../../../services/voice_recorder/voice_recorder_interface.dart';

class VoiceAssistantSheet extends StatefulWidget {
  final Function(String query) onSendQuery;
  final VoidCallback onOpenLiveCall;

  const VoiceAssistantSheet({
    super.key,
    required this.onSendQuery,
    required this.onOpenLiveCall,
  });

  @override
  State<VoiceAssistantSheet> createState() => _VoiceAssistantSheetState();
}

class _VoiceAssistantSheetState extends State<VoiceAssistantSheet> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final PlatformVoiceRecorder _recorder = getVoiceRecorder();
  bool _isListening = false;
  bool _isInitializing = false;
  String _recognizedWords = '';
  double _soundLevel = 0.0;
  String _statusText = 'Connecting to microphone...';
  bool _hasError = false;
  Timer? _silenceTimer;

  @override
  void initState() {
    super.initState();
    // Start listening cleanly once the bottom sheet has animated in
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) {
        _startListening();
      }
    });
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _safeStopSpeech();
    super.dispose();
  }

  Future<void> _safeStopSpeech() async {
    await _recorder.cancel();
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
      await _speech.cancel();
    } catch (_) {}
  }

  Future<void> _startListening() async {
    if (_isInitializing) return;

    // Unlock audio context on user interaction
    TtsService().unlockAudioContext();

    final settings = context.read<SettingsProvider>();
    final lang = settings.language;

    if (kIsWeb) {
      _startWebRecording(lang);
      return;
    }

    final initialText = lang == 'gu'
        ? 'સાંભળી રહ્યું છે... હવે બોલો'
        : (lang == 'hi' ? 'सुन रहा हूँ... अब बोलें' : 'Listening... Speak now');

    setState(() {
      _isInitializing = true;
      _hasError = false;
      _statusText = initialText;
    });

    try {
      // If already listening, stop first and wait briefly for native audio device to release
      if (_speech.isListening) {
        await _speech.stop();
        await Future.delayed(const Duration(milliseconds: 250));
      }

      bool available = _speech.isAvailable;
      if (!available) {
        available = await _speech.initialize(
          onStatus: (status) {
            debugPrint('[VoiceSheet] Status: $status');
            if (!mounted) return;
            if (status == 'done' || status == 'notListening') {
              setState(() {
                _isListening = false;
                _soundLevel = 0.0;
                if (_recognizedWords.trim().isNotEmpty) {
                  _statusText = lang == 'gu'
                      ? 'અવાજ નોંધાઈ ગયો! મોકલો પર ટેપ કરો.'
                      : (lang == 'hi' ? 'आवाज़ रिकॉर्ड हो गई! भेजें पर टैप करें।' : 'Voice captured! Tap Send or speak again.');
                } else {
                  _statusText = lang == 'gu'
                      ? 'બોલવા માટે માઇક પર ટેપ કરો'
                      : (lang == 'hi' ? 'बोलने के लिए माइक पर टैप करें' : 'Tap mic to speak');
                }
              });
            }
          },
          onError: (errorNotification) {
            debugPrint('[VoiceSheet] Error: ${errorNotification.errorMsg}');
            if (!mounted) return;
            setState(() {
              _isListening = false;
              _soundLevel = 0.0;
              _hasError = true;
              final code = errorNotification.errorMsg;
              if (code == 'error_no_match') {
                _statusText = lang == 'gu'
                    ? 'અવાજ ઓળખાયો નથી. કૃપા કરીને ફરી બોલો.'
                    : (lang == 'hi' ? 'आवाज़ समझ नहीं आई। कृपया दोबारा बोलें।' : "Didn't catch that. Speak closer to the mic.");
              } else if (code == 'error_speech_timeout') {
                _statusText = _recognizedWords.isNotEmpty
                    ? (lang == 'gu' ? 'સાંભળવાનું પૂર્ણ થયું.' : (lang == 'hi' ? 'सुनना समाप्त हुआ।' : 'Finished listening.'))
                    : (lang == 'gu' ? 'કોઈ અવાજ સંભળાયો નથી. ફરી પ્રયાસ કરો.' : (lang == 'hi' ? 'कोई आवाज़ नहीं सुनी। दोबारा प्रयास करें।' : 'No speech heard. Tap mic to retry.'));
              } else if (code == 'error_busy' || code == 'error_audio_error') {
                _statusText = lang == 'gu'
                    ? 'માઇક્રોફોન રિસેટ થયો. ફરી ટેપ કરો.'
                    : (lang == 'hi' ? 'माइक रीसेट हुआ। दोबारा टैप करें।' : 'Audio device reset. Tap mic to speak.');
                _speech.cancel();
              } else {
                _statusText = lang == 'gu'
                    ? 'ફરી બોલવા માટે માઇક ટેપ કરો.'
                    : (lang == 'hi' ? 'दोबारा बोलने के लिए माइक टैપ करें।' : 'Tap mic to speak again.');
              }
            });
          },
          debugLogging: false,
        );
      }

      if (!available) {
        if (mounted) {
          setState(() {
            _isListening = false;
            _isInitializing = false;
            _hasError = true;
            _statusText = lang == 'gu'
                ? 'માઇક્રોફોન ઉપલબ્ધ નથી. કૃપા કરીને પરવાનગી ચકાસો.'
                : (lang == 'hi' ? 'माइक उपलब्ध नहीं है। अनुमति की जांच करें।' : 'Speech recognition unavailable. Please check mic permissions.');
          });
        }
        return;
      }

      String targetLocale = 'en_US';
      if (lang == 'gu') {
        targetLocale = 'gu_IN';
      } else if (lang == 'hi') {
        targetLocale = 'hi_IN';
      }

      try {
        final locales = await _speech.locales();
        final matchingLocales = locales.where(
          (l) => l.localeId.toLowerCase().replaceAll('-', '_').startsWith(lang.toLowerCase()) ||
                 l.localeId.toLowerCase().replaceAll('-', '_').contains(lang.toLowerCase()),
        );
        if (matchingLocales.isNotEmpty) {
          targetLocale = matchingLocales.first.localeId;
        }
      } catch (_) {}

      // Short breathing pause for Android AudioRecord buffer
      await Future.delayed(const Duration(milliseconds: 200));

      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() {
            _recognizedWords = result.recognizedWords;
            _hasError = false;
            _statusText = result.recognizedWords;
          });

          // Automatically send query after a 1.6s speech pause
          _silenceTimer?.cancel();
          if (result.recognizedWords.trim().isNotEmpty) {
            _silenceTimer = Timer(const Duration(milliseconds: 1600), () {
              if (mounted && _recognizedWords.trim().isNotEmpty) {
                setState(() => _statusText = lang == 'gu' ? 'વેધરજીપીટીને મોકલી રહ્યું છે...' : (lang == 'hi' ? 'वेदरजीपीटी को भेजा जा रहा है...' : 'Sending to WeatherGPT...'));
                _sendAndClose(_recognizedWords.trim());
              }
            });
          }
        },
        onSoundLevelChange: (level) {
          if (!mounted) return;
          setState(() {
            _soundLevel = level.clamp(0, 15);
          });
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
          onDevice: false,
          listenFor: const Duration(seconds: 40),
          pauseFor: const Duration(seconds: 4),
          localeId: targetLocale,
        ),
      );

      if (mounted) {
        setState(() {
          _isListening = true;
          _isInitializing = false;
          _hasError = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _isInitializing = false;
          _hasError = true;
          _statusText = lang == 'gu' ? 'માઇક તૈયાર છે. બોલવા માટે ટેપ કરો.' : (lang == 'hi' ? 'माइक तैयार है। बोलने के लिए टैप करें।' : 'Mic ready. Tap mic to speak.');
        });
      }
    }
  }

  Future<void> _startWebRecording(String lang) async {
    setState(() {
      _isInitializing = true;
      _hasError = false;
      _statusText = lang == 'gu' ? 'સાંભળી રહ્યું છે... હવે બોલો' : (lang == 'hi' ? 'सुन रहा हूँ... अब बोलें' : 'Listening... Speak now');
    });

    final started = await _recorder.startRecording(
      onStarted: () {
        if (mounted) {
          setState(() {
            _isListening = true;
            _isInitializing = false;
          });
        }
      },
      onSoundLevel: (lvl) {
        if (mounted && _isListening) {
          setState(() => _soundLevel = lvl);
        }
      },
      onSilenceDetected: () {
        if (mounted && _isListening) {
          _stopWebRecordingAndTranscribe(lang);
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _isListening = false;
            _isInitializing = false;
            _hasError = true;
            _statusText = 'Mic: $err';
          });
        }
      },
    );

    if (!started && mounted) {
      setState(() {
        _isListening = false;
        _isInitializing = false;
        _hasError = true;
        _statusText = lang == 'gu' ? 'માઇક પરવાનગી ચકાસો' : 'Check mic permissions';
      });
    }
  }

  Future<void> _stopWebRecordingAndTranscribe(String lang) async {
    if (!_isListening && !_recorder.isRecording) return;
    setState(() {
      _isListening = false;
      _statusText = lang == 'gu' ? 'ઑડિયો ઓળખી રહ્યું છે...' : 'Recognizing voice...';
    });

    try {
      final result = await _recorder.stopAndProcessPipeline(
        defaultLanguage: lang,
        onTranscriptionReady: (text, detectedLang) {
          if (mounted) {
            setState(() {
              _recognizedWords = text;
              _statusText = text;
            });
          }
        },
      );

      if (result != null && result.question != null && result.question!.trim().isNotEmpty) {
        final q = result.question!.trim();
        if (mounted) {
          setState(() {
            _recognizedWords = q;
            _statusText = q;
          });
          _sendAndClose(q);
        }
      } else {
        if (mounted) {
          setState(() {
            _statusText = lang == 'gu' ? 'અવાજ સમજાયો નથી. ફરી પ્રયાસ કરો.' : 'Could not recognize speech. Tap mic to retry.';
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _statusText = 'Recognition error. Tap mic to retry.';
        });
      }
    }
  }

  void _handleMicTap() {
    _silenceTimer?.cancel();
    if (_isListening) {
      if (kIsWeb) {
        final lang = context.read<SettingsProvider>().language;
        _stopWebRecordingAndTranscribe(lang);
      } else {
        _speech.stop();
        setState(() {
          _isListening = false;
          _soundLevel = 0.0;
          _statusText = _recognizedWords.isNotEmpty ? 'Voice captured!' : 'Tap mic to speak';
        });
      }
    } else {
      _startListening();
    }
  }

  void _sendAndClose(String query) {
    _silenceTimer?.cancel();
    _safeStopSpeech();
    Navigator.pop(context);
    widget.onSendQuery(query);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasText = _recognizedWords.trim().isNotEmpty;
    final lang = context.watch<SettingsProvider>().language;

    final suggestions = lang == 'gu'
        ? [
            '🌧️ આજે વરસાદ પડશે?',
            '☀️ આજનું તાપમાન અને ભેજ',
            '🌾 ખેડૂત પાક સલાહ',
            '🚗 મુસાફરી અને રસ્તાની સલાહ',
          ]
        : (lang == 'hi'
            ? [
                '🌧️ क्या आज बारिश होगी?',
                '☀️ आज का तापमान और उमस',
                '🌾 किसान मौसम सलाह',
                '🚗 यात्रा एवं सड़क सुरक्षा',
              ]
            : [
                '🌧️ Will it rain today?',
                '☀️ Temperature & humidity',
                '🌾 Farming advisory',
                '🚗 Travel & road safety',
              ]);

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Top Row: Title + Live Call Switch Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.mic_rounded, color: Color(0xFF0EA5E9), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      lang == 'gu'
                          ? 'વૉઇસ આસિસ્ટન્ટ'
                          : (lang == 'hi' ? 'वॉयस असिस्टेंट' : 'Voice Assistant'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                // Live Call Switch Button
                InkWell(
                  onTap: () {
                    _safeStopSpeech();
                    Navigator.pop(context);
                    widget.onOpenLiveCall();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF0EA5E9)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withAlpha(60),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          lang == 'gu' ? 'લાઈવ કૉલ' : (lang == 'hi' ? 'लाइव कॉल' : 'Live Call'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Big Mic with Animated Live Sound Wave
            GestureDetector(
              onTap: _handleMicTap,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing audio wave ring
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: 86 + (_isListening ? (_soundLevel.clamp(0, 15) * 2.5) : 0),
                    height: 86 + (_isListening ? (_soundLevel.clamp(0, 15) * 2.5) : 0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0EA5E9).withAlpha(_isListening ? 45 : 0),
                    ),
                  ),
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _isListening
                            ? const [Color(0xFF0EA5E9), Color(0xFF6366F1)]
                            : const [Color(0xFF64748B), Color(0xFF475569)],
                      ),
                      boxShadow: _isListening
                          ? [
                              BoxShadow(
                                color: const Color(0xFF0EA5E9).withAlpha(120),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ),

            // Live Audio Bars
            if (_isListening) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    width: 3.5,
                    height: 10 + (_soundLevel.clamp(0, 15) * 1.2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    width: 3.5,
                    height: 14 + (_soundLevel.clamp(0, 20) * 1.6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    width: 3.5,
                    height: 10 + (_soundLevel.clamp(0, 15) * 1.2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 14),

            // Status Banner
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _statusText,
                key: ValueKey<String>(_statusText),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _hasError
                      ? Colors.amber.shade600
                      : (_isListening ? const Color(0xFF0EA5E9) : Colors.grey.shade400),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Recognized Speech Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isListening
                      ? const Color(0xFF0EA5E9).withAlpha(120)
                      : (isDark ? Colors.white12 : Colors.black12),
                ),
              ),
              child: Text(
                _recognizedWords.isNotEmpty
                    ? _recognizedWords
                    : (lang == 'gu'
                        ? 'તમારો પ્રશ્ન બોલો (દા.ત. "આજે રાજકોટમાં વરસાદ પડશે?")'
                        : (lang == 'hi'
                            ? 'अपना प्रश्न बोलें (जैसे "क्या आज राजकोट में बारिश होगी?")'
                            : 'Speak in English, Hindi, or Gujarati (e.g. "Will it rain today in Rajkot?")')),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: _recognizedWords.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                  color: _recognizedWords.isNotEmpty
                      ? (isDark ? Colors.white : Colors.black87)
                      : Colors.grey.shade500,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Quick Suggestions Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: suggestions.map((q) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(q, style: const TextStyle(fontSize: 11.5)),
                    onPressed: () => _sendAndClose(q),
                  ),
                )).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      _safeStopSpeech();
                      Navigator.pop(context);
                    },
                    child: Text(lang == 'gu' ? 'રદ કરો' : (lang == 'hi' ? 'रद्द करें' : 'Cancel')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      lang == 'gu' ? 'પ્રશ્ન મોકલો' : (lang == 'hi' ? 'भेजें' : 'Send Query'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onPressed: hasText
                        ? () => _sendAndClose(_recognizedWords.trim())
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
