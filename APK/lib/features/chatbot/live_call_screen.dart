import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../providers/chat_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/tts_service.dart';
import '../../services/voice_recorder/voice_recorder.dart';
import '../../services/voice_recorder/voice_recorder_interface.dart';

enum CallStatus { connecting, listening, thinking, speaking }

class LiveCallTurn {
  final String sender; // 'user' or 'ai'
  String text;
  final DateTime time;
  bool isStreaming;

  LiveCallTurn({
    required this.sender,
    required this.text,
    this.isStreaming = false,
    DateTime? time,
  }) : time = time ?? DateTime.now();
}

class LiveCallScreen extends StatefulWidget {
  const LiveCallScreen({super.key});

  @override
  State<LiveCallScreen> createState() => _LiveCallScreenState();
}

class _LiveCallScreenState extends State<LiveCallScreen> with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TtsService _tts = TtsService();
  final PlatformVoiceRecorder _recorder = getVoiceRecorder();
  final ScrollController _transcriptScrollController = ScrollController();
  final List<LiveCallTurn> _callHistory = [];

  CallStatus _status = CallStatus.connecting;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  String _currentTranscript = '';
  double _soundLevel = 0.0;
  int _callDurationSeconds = 0;
  Timer? _durationTimer;
  Timer? _silenceTimer;
  Timer? _typewriterTimer;
  bool _isProcessingQuery = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startDurationTimer();
    _startCallSession();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _silenceTimer?.cancel();
    _typewriterTimer?.cancel();
    _pulseController.dispose();
    _transcriptScrollController.dispose();
    _tts.stop();
    _safeStopSpeech();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_transcriptScrollController.hasClients) {
        _transcriptScrollController.animateTo(
          _transcriptScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _callDurationSeconds++);
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _safeStopSpeech() async {
    _recorder.stopPlayback();
    await _recorder.cancel();
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
      await _speech.cancel();
    } catch (_) {}
  }

  Future<void> _startCallSession() async {
    final settingsProvider = context.read<SettingsProvider>();
    final lang = settingsProvider.language;
    _tts.unlockAudioContext();
    await _tts.init();
    if (!mounted) return;

    final String greeting;
    if (lang == 'gu') {
      greeting = "નમસ્તે! વેધરજીપીટી લાઈવ શરૂ થઈ ગયું છે. હવામાન અથવા વરસાદ વિશે કંઈપણ પૂછો.";
    } else if (lang == 'hi') {
      greeting = "नमस्ते! वेदरजीपीटी लाइव कनेक्ट हो गया है। मौसम या बारिश के बारे में कुछ भी पूछें।";
    } else {
      greeting = "Hello! WeatherGPT Live is connected. Ask me anything about the weather, rain forecast, or travel safety.";
    }
    await _speakWithLiveTypewriter(greeting, language: lang);
  }

  Future<void> _speakWithLiveTypewriter(String fullText, {String? language}) async {
    _typewriterTimer?.cancel();

    final turn = LiveCallTurn(
      sender: 'ai',
      text: '',
      isStreaming: true,
    );

    if (mounted) {
      setState(() {
        _status = CallStatus.speaking;
        _callHistory.add(turn);
      });
      _scrollToBottom();
    }

    void startTypewriter() {
      _typewriterTimer?.cancel();
      int charIndex = 0;
      const tickInterval = Duration(milliseconds: 45);

      _typewriterTimer = Timer.periodic(tickInterval, (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (charIndex < fullText.length) {
          charIndex++;
          setState(() {
            turn.text = fullText.substring(0, charIndex);
          });
          _scrollToBottom();
        } else {
          timer.cancel();
          setState(() {
            turn.text = fullText;
            turn.isStreaming = false;
          });
          _scrollToBottom();
        }
      });
    }

    startTypewriter();

    _tts.onStart = () {
      if (mounted) {
        setState(() => _status = CallStatus.speaking);
      }
    };

    _tts.onCompletion = () {
      _typewriterTimer?.cancel();
      if (mounted) {
        setState(() {
          turn.text = fullText;
          turn.isStreaming = false;
        });
        _scrollToBottom();
      }
      _isProcessingQuery = false;
      if (mounted && _status == CallStatus.speaking) {
        // Critical: Allow Android AudioTrack to cleanly release audio focus before opening AudioRecord
        Future.delayed(const Duration(milliseconds: 380), () {
          if (mounted && !_isProcessingQuery && !_tts.isPlaying) {
            _listenForUserSpeech();
          }
        });
      }
    };

    if (_isSpeakerOn) {
      await _tts.speak(fullText, language: language ?? 'en');
    } else {
      startTypewriter();
      final totalWaitMs = (fullText.length * 45) + 1200;
      Future.delayed(Duration(milliseconds: totalWaitMs), () {
        _typewriterTimer?.cancel();
        if (mounted) {
          setState(() {
            turn.text = fullText;
            turn.isStreaming = false;
          });
          _scrollToBottom();
        }
        _isProcessingQuery = false;
        if (mounted && _status == CallStatus.speaking) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && !_isProcessingQuery && !_tts.isPlaying) {
              _listenForUserSpeech();
            }
          });
        }
      });
    }
  }

  bool _speechInitialized = false;

  bool _hasUserSpoken(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    final placeholders = [
      'Listening',
      'Connecting',
      'Initializing',
      'સાંભળી',
      'सुन',
      'Tap orb',
      'બોલવા',
      'બોલો',
      'बोलें',
      'Speak now',
    ];
    return !placeholders.any((p) => trimmed.startsWith(p));
  }

  Future<bool> _initSpeech() async {
    if (_speechInitialized && _speech.isAvailable) return true;
    try {
      _speechInitialized = await _speech.initialize(
        onStatus: (status) {
          debugPrint('[LiveCall] Speech status: $status');
          if (!mounted) return;
          if (status == 'notListening' || status == 'done') {
            if (_status == CallStatus.listening && !_isProcessingQuery && !_tts.isPlaying) {
              if (_hasUserSpoken(_currentTranscript)) {
                _submitUserSpeech(_currentTranscript.trim());
              } else if (!_isMuted) {
                // Keep live call alive: if user didn't speak before phone recognizer timed out, restart listening
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted && _status == CallStatus.listening && !_isProcessingQuery && !_tts.isPlaying) {
                    _listenForUserSpeech();
                  }
                });
              }
            }
          }
        },
        onError: (err) {
          debugPrint('[LiveCall] Speech error: ${err.errorMsg}');
          if (!mounted) return;
          if (_status == CallStatus.listening && !_isProcessingQuery) {
            if (_hasUserSpoken(_currentTranscript)) {
              _submitUserSpeech(_currentTranscript.trim());
            } else if (!_isMuted) {
              Future.delayed(const Duration(milliseconds: 400), () {
                if (mounted && _status == CallStatus.listening && !_isProcessingQuery && !_tts.isPlaying) {
                  _listenForUserSpeech();
                }
              });
            }
          }
        },
        debugLogging: false,
      );
      return _speechInitialized;
    } catch (e) {
      debugPrint('[LiveCall] Speech init exception: $e');
      return false;
    }
  }

  Future<void> _listenForUserSpeech() async {
    if (_isMuted || !mounted) return;

    // Do NOT enter listening mode if GPT is still actively speaking
    if (_tts.isPlaying || _recorder.isPlayingAudio) return;

    _silenceTimer?.cancel();
    _currentTranscript = '';

    final settingsProvider = context.read<SettingsProvider>();
    final lang = settingsProvider.language;
    final initialText = lang == 'gu'
        ? 'સાંભળી રહ્યું છે... હવે બોલો'
        : (lang == 'hi'
            ? 'सुन रहा हूँ... अब बोलें'
            : (lang == 'auto'
                ? 'Listening... બોલો / बोलें / Speak now'
                : 'Listening... Speak now'));

    setState(() {
      _status = CallStatus.listening;
      _currentTranscript = initialText;
      _soundLevel = 0.0;
    });
    _scrollToBottom();

    if (kIsWeb) {
      _listenWithRecorderFallback();
      return;
    }

    final ready = await _initSpeech();
    if (!ready || !mounted) {
      if (mounted) {
        setState(() {
          _status = CallStatus.listening;
          _currentTranscript = lang == 'gu'
              ? 'માઇક્રોફોન પરવાનગી આપવા માટે ઑર્બ ટેપ કરો'
              : (lang == 'hi' ? 'माइक अनुमति देने के लिए टैप करें' : 'Tap orb to grant mic permission');
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
        (loc) => loc.localeId.toLowerCase().replaceAll('-', '_').startsWith(lang.toLowerCase()) ||
                 loc.localeId.toLowerCase().replaceAll('-', '_').contains(lang.toLowerCase()),
      );
      if (matchingLocales.isNotEmpty) {
        targetLocale = matchingLocales.first.localeId;
      }
    } catch (_) {}

    try {
      if (_speech.isListening) {
        await _speech.stop();
        await Future.delayed(const Duration(milliseconds: 200));
      } else {
        await Future.delayed(const Duration(milliseconds: 150));
      }

      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() {
            _currentTranscript = result.recognizedWords;
          });
          _scrollToBottom();

          // Silence detection: automatically trigger answer after 1.4s of silence
          _silenceTimer?.cancel();
          if (result.recognizedWords.trim().isNotEmpty) {
            _silenceTimer = Timer(const Duration(milliseconds: 1400), () {
              if (mounted && _status == CallStatus.listening && !_isProcessingQuery && !_tts.isPlaying) {
                _submitUserSpeech(result.recognizedWords.trim());
              }
            });
          }
        },
        onSoundLevelChange: (level) {
          if (mounted && _status == CallStatus.listening && !_tts.isPlaying) {
            setState(() {
              _soundLevel = level.clamp(0, 15);
            });
          }
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
          onDevice: false,
          localeId: targetLocale,
          listenFor: const Duration(seconds: 45),
          pauseFor: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      debugPrint('[LiveCall] Speech listen error: $e');
      if (mounted && !_isMuted) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted && _status == CallStatus.listening && !_isProcessingQuery && !_tts.isPlaying) {
            _listenForUserSpeech();
          }
        });
      }
    }
  }

  Future<void> _listenWithRecorderFallback() async {
    try {
      final started = await _recorder.startRecording(
        onStarted: () {
          if (mounted) {
            setState(() {
              _status = CallStatus.listening;
              _currentTranscript = 'Listening... Speak now';
              _soundLevel = 0.0;
            });
            _scrollToBottom();
          }
        },
        onSoundLevel: (level) {
          if (mounted && _status == CallStatus.listening && !_tts.isPlaying) {
            setState(() => _soundLevel = level);
          }
        },
        onSilenceDetected: () {
          if (mounted && _status == CallStatus.listening && !_isProcessingQuery && !_tts.isPlaying) {
            _stopRecordingAndSubmit();
          }
        },
        onError: (err) {
          if (mounted) {
            setState(() {
              _status = CallStatus.listening;
              _currentTranscript = 'Tap mic or speak: $err';
            });
          }
        },
      );
      if (!started && mounted) {
        setState(() {
          _status = CallStatus.listening;
          _currentTranscript = 'Tap orb to start microphone';
        });
      }
    } catch (_) {}
  }

  Future<void> _submitUserSpeech(String questionText) async {
    if (_isProcessingQuery || questionText.trim().isEmpty) return;
    _isProcessingQuery = true;
    _silenceTimer?.cancel();

    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _status = CallStatus.thinking;
      _soundLevel = 0.0;
      _currentTranscript = '';
      _callHistory.add(LiveCallTurn(sender: 'user', text: questionText));
    });
    _scrollToBottom();

    final chatProvider = context.read<ChatProvider>();
    final locProvider = context.read<LocationProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    try {
      final loc = locProvider.currentLocation;
      final response = await chatProvider.repository.sendMessage(
        question: questionText,
        location: loc,
        persona: chatProvider.selectedPersona,
        language: settingsProvider.language,
      );

      final answerText = response.content.isNotEmpty
          ? response.content
          : (settingsProvider.language == 'gu'
              ? 'હવામાન માહિતી મળી શકી નથી. કૃપા કરીને ફરી પૂછો.'
              : (settingsProvider.language == 'hi'
                  ? 'मौसम की जानकारी नहीं मिल सकी। कृपया पुनः पूछें।'
                  : 'Weather details could not be retrieved. Please ask again.'));

      if (mounted) {
        await _speakWithLiveTypewriter(answerText, language: settingsProvider.language);
      } else {
        _isProcessingQuery = false;
      }
    } catch (e) {
      debugPrint('[LiveCall] AI query error: $e');
      if (mounted) {
        final errorMsg = settingsProvider.language == 'gu'
            ? 'માફ કરશો, નેટવર્ક સમસ્યા આવી છે. કૃપા કરીને ફરી બોલો.'
            : (settingsProvider.language == 'hi'
                ? 'माफ़ कीजिए, नेटवर्क त्रुटि हुई। कृपया दोबारा बोलें।'
                : 'Sorry, a network error occurred. Please try speaking again.');
        await _speakWithLiveTypewriter(errorMsg, language: settingsProvider.language);
      } else {
        _isProcessingQuery = false;
      }
    }
  }

  Future<void> _stopRecordingAndSubmit() async {
    if (_isProcessingQuery) return;
    _silenceTimer?.cancel();

    if (_hasUserSpoken(_currentTranscript)) {
      await _submitUserSpeech(_currentTranscript.trim());
      return;
    }

    if (_recorder.isRecording) {
      _isProcessingQuery = true;
      if (!mounted) return;
      setState(() {
        _status = CallStatus.thinking;
        _soundLevel = 0.0;
        _currentTranscript = '';
      });
      _scrollToBottom();

      final settingsProvider = context.read<SettingsProvider>();
      final locProvider = context.read<LocationProvider>();

      try {
        final loc = locProvider.currentLocation;
        LiveCallTurn? aiTurn;

        final result = await _recorder.stopAndProcessPipeline(
          defaultLanguage: settingsProvider.language,
          latitude: loc.latitude,
          longitude: loc.longitude,
          onStatusUpdate: (msg) {
            if (mounted) {
              setState(() {
                _status = CallStatus.thinking;
                _currentTranscript = msg;
              });
            }
          },
          onTranscriptionReady: (transcription, lang) {
            if (mounted) {
              setState(() {
                _callHistory.add(LiveCallTurn(sender: 'user', text: transcription));
              });
              _scrollToBottom();
            }
          },
          onAnswerReady: (answer) {
            if (mounted) {
              aiTurn = LiveCallTurn(sender: 'ai', text: '', isStreaming: true);
              setState(() {
                _callHistory.add(aiTurn!);
              });
              _scrollToBottom();
              _runTypewriter(aiTurn!, answer);
            }
          },
          onAudioPlaybackStarted: () {
            if (mounted) {
              setState(() => _status = CallStatus.speaking);
            }
          },
          onAudioPlaybackEnded: () {
            if (mounted) {
              if (aiTurn != null) {
                setState(() => aiTurn!.isStreaming = false);
              }
              _isProcessingQuery = false;
              // Audio ended: auto-restart Step 1 (listening)
              Future.delayed(const Duration(milliseconds: 350), () {
                if (mounted && !_isProcessingQuery && !_tts.isPlaying && !_recorder.isPlayingAudio) {
                  _listenForUserSpeech();
                }
              });
            }
          },
        );

        if (result != null && result.success) {
          if (!result.audioPlayed) {
            // Speak blob was unavailable (e.g. 502/quota limit) -> Fallback to local TtsService!
            if (mounted) {
              await _speakWithLiveTypewriter(
                result.answer,
                language: result.language ?? settingsProvider.language,
              );
            }
          }
        } else {
          final errorMsg = result?.answer ??
              (settingsProvider.language == 'gu'
                  ? 'માફ કરશો, નેટવર્ક સમસ્યા આવી છે. કૃપા કરીને ફરી બોલો.'
                  : 'Sorry, could not process voice request. Please speak again.');
          if (mounted) {
            await _speakWithLiveTypewriter(errorMsg, language: settingsProvider.language);
          }
        }
      } catch (e) {
        if (mounted) {
          final errorMsg = settingsProvider.language == 'gu'
              ? 'માફ કરશો, નેટવર્ક સમસ્યા આવી છે. કૃપા કરીને ફરી બોલો.'
              : 'Sorry, could not process voice request right now. Please speak again.';
          await _speakWithLiveTypewriter(errorMsg);
        } else {
          _isProcessingQuery = false;
        }
      }
    } else {
      await _listenForUserSpeech();
    }
  }

  void _runTypewriter(LiveCallTurn turn, String fullText) {
    _typewriterTimer?.cancel();
    int charIndex = 0;
    const tickInterval = Duration(milliseconds: 35);

    _typewriterTimer = Timer.periodic(tickInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (charIndex < fullText.length) {
        charIndex++;
        setState(() {
          turn.text = fullText.substring(0, charIndex);
        });
        _scrollToBottom();
      } else {
        timer.cancel();
        setState(() {
          turn.text = fullText;
          turn.isStreaming = false;
        });
        _scrollToBottom();
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      if (_isMuted) {
        _safeStopSpeech();
        _status = CallStatus.listening;
      } else {
        _listenForUserSpeech();
      }
    });
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
      if (!_isSpeakerOn) {
        _tts.stop();
      }
    });
  }

  void _endCall() {
    _durationTimer?.cancel();
    _silenceTimer?.cancel();
    _typewriterTimer?.cancel();
    _tts.stop();
    _safeStopSpeech();
    Navigator.pop(context);
  }

  Color _getStatusColor() {
    switch (_status) {
      case CallStatus.connecting:
        return const Color(0xFF94A3B8);
      case CallStatus.listening:
        return const Color(0xFF0EA5E9);
      case CallStatus.thinking:
        return const Color(0xFF8B5CF6);
      case CallStatus.speaking:
        return const Color(0xFF10B981);
    }
  }

  String _getStatusTitle(String lang) {
    switch (_status) {
      case CallStatus.connecting:
        return lang == 'gu' ? 'કનેક્ટ થઈ રહ્યું છે...' : (lang == 'hi' ? 'कनेक्ट हो रहा है...' : 'Connecting...');
      case CallStatus.listening:
        return _isMuted
            ? (lang == 'gu' ? 'માઇક્રોફોન મ્યૂટ છે' : (lang == 'hi' ? 'माइक म्यूट है' : 'Microphone Muted'))
            : (lang == 'gu' ? 'સાંભળી રહ્યું છે... બોલો' : (lang == 'hi' ? 'सुन रहा हूँ... बोलें' : (lang == 'auto' ? 'Auto Detect: Listening...' : 'Listening... Speak now')));
      case CallStatus.thinking:
        return lang == 'gu' ? 'વેધરજીપીટી વિચારી રહ્યું છે...' : (lang == 'hi' ? 'वेदरજીપીટી सोच रहा है...' : 'WeatherGPT is thinking...');
      case CallStatus.speaking:
        return lang == 'gu' ? 'વેધરજીપીટી બોલી રહ્યું છે...' : (lang == 'hi' ? 'वेदरજીપીટી बोल रहा है...' : 'WeatherGPT is speaking...');
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final persona = chatProvider.selectedPersona;
    final statusColor = _getStatusColor();

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
            // Top Header: Minimize, Title, Duration, Live Badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 28),
                    onPressed: _endCall,
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withAlpha(180),
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'WeatherGPT Live',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDuration(_callDurationSeconds),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Persona Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      persona.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF0EA5E9),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Center: Glowing AI Audio Orb with Tap Interruption / Direct Send
            Center(
              child: GestureDetector(
                onTap: () {
                  if (_status == CallStatus.speaking) {
                    // Tap to interrupt AI and immediately start listening
                    _recorder.stopPlayback();
                    _tts.stop();
                    _typewriterTimer?.cancel();
                    Future.delayed(const Duration(milliseconds: 250), () {
                      if (mounted) _listenForUserSpeech();
                    });
                  } else if (_status == CallStatus.listening) {
                    // 3. Clear mechanism to STOP recording: tap orb to stop and send
                    _stopRecordingAndSubmit();
                  }
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glowing ripple reacting to decibels or status
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 170 + (_status == CallStatus.listening ? (_soundLevel.clamp(0, 15) * 4.5) : 10),
                      height: 170 + (_status == CallStatus.listening ? (_soundLevel.clamp(0, 15) * 4.5) : 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor.withAlpha(_status == CallStatus.speaking ? 35 : 20),
                      ),
                    ),
                    // Middle glowing pulsing circle
                    ScaleTransition(
                      scale: _status == CallStatus.thinking ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                      child: Container(
                        width: 135,
                        height: 135,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              statusColor.withAlpha(100),
                              statusColor.withAlpha(20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Center Core Orb
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            statusColor,
                            statusColor.withAlpha(200),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withAlpha(150),
                            blurRadius: 28,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          _status == CallStatus.speaking
                              ? Icons.volume_up_rounded
                              : (_status == CallStatus.thinking
                                  ? Icons.auto_awesome
                                  : (_isMuted ? Icons.mic_off_rounded : Icons.mic_rounded)),
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Status Title
            Text(
              _getStatusTitle(context.watch<SettingsProvider>().language),
              style: TextStyle(
                color: statusColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _status == CallStatus.speaking
                  ? (context.watch<SettingsProvider>().language == 'gu'
                      ? 'અટકાવવા માટે ઑર્બ ટેપ કરો'
                      : (context.watch<SettingsProvider>().language == 'hi' ? 'रोकने के लिए टैप करें' : 'Tap orb to interrupt'))
                  : (_status == CallStatus.listening
                      ? (context.watch<SettingsProvider>().language == 'gu'
                          ? 'મોકલવા માટે ઑર્બ ટેપ કરો • અથવા થોભો'
                          : (context.watch<SettingsProvider>().language == 'hi'
                              ? 'भेजने के लिए टैપ करें • या रुकें'
                              : 'Tap orb to STOP & send • Or pause speaking'))
                      : (_status == CallStatus.thinking
                          ? (context.watch<SettingsProvider>().language == 'gu'
                              ? 'વેધરજીપીટી જવાબ વિચારી રહ્યું છે...'
                              : (context.watch<SettingsProvider>().language == 'hi'
                                  ? 'उत्तर तैयार हो रहा है...'
                                  : 'Processing voice with WeatherGPT...'))
                          : (context.watch<SettingsProvider>().language == 'gu'
                              ? 'માઇક્રોફોન શરૂ થઈ રહ્યું છે...'
                              : 'Connecting microphone...'))),
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),

            const Spacer(),

            // Real-Time Scrollable Transcript Display Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 90, maxHeight: 210),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: SingleChildScrollView(
                  controller: _transcriptScrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_callHistory.isEmpty && _currentTranscript.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'Listening for your voice...',
                              style: TextStyle(color: Colors.white38, fontSize: 13),
                            ),
                          ),
                        ),

                      for (final item in _callHistory) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(top: 2, right: 8),
                                decoration: BoxDecoration(
                                  color: item.sender == 'user'
                                      ? const Color(0xFF0EA5E9).withAlpha(35)
                                      : const Color(0xFF10B981).withAlpha(35),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: item.sender == 'user'
                                        ? const Color(0xFF0EA5E9).withAlpha(120)
                                        : const Color(0xFF10B981).withAlpha(120),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  item.sender == 'user' ? 'YOU' : 'AI',
                                  style: TextStyle(
                                    color: item.sender == 'user'
                                        ? const Color(0xFF38BDF8)
                                        : const Color(0xFF34D399),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      color: item.sender == 'user' ? Colors.white : Colors.white.withAlpha(230),
                                      fontSize: 13,
                                      height: 1.35,
                                    ),
                                    children: [
                                      TextSpan(text: item.text),
                                      if (item.isStreaming)
                                        const TextSpan(
                                          text: ' ▋',
                                          style: TextStyle(
                                            color: Color(0xFF34D399),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (_currentTranscript.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(top: 2, right: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0EA5E9).withAlpha(40),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'YOU...',
                                  style: TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _currentTranscript,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Call Controls: Mute, End Call, Speaker
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute / Unmute
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _toggleMute,
                        iconSize: 28,
                        style: IconButton.styleFrom(
                          backgroundColor: _isMuted ? Colors.redAccent.withAlpha(40) : Colors.white12,
                          foregroundColor: _isMuted ? Colors.redAccent : Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                        icon: Icon(_isMuted ? Icons.mic_off_rounded : Icons.mic_rounded),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isMuted ? 'Unmute' : 'Mute',
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),

                  // Red End Call Button
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _endCall,
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.redAccent,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withAlpha(120),
                                blurRadius: 18,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.call_end_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'End Call',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),

                  // Speaker Toggle
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _toggleSpeaker,
                        iconSize: 28,
                        style: IconButton.styleFrom(
                          backgroundColor: !_isSpeakerOn ? Colors.amber.withAlpha(40) : Colors.white12,
                          foregroundColor: !_isSpeakerOn ? Colors.amber : Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                        icon: Icon(_isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isSpeakerOn ? 'Speaker' : 'Muted',
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
