// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import '../../core/constants/api_constants.dart';
import 'voice_recorder_interface.dart';

class WebVoiceRecorder implements PlatformVoiceRecorder {
  html.MediaStream? _stream;
  html.MediaRecorder? _mediaRecorder;
  final List<html.Blob> _audioChunks = [];
  bool _isRecording = false;
  bool _isPlayingAudio = false;
  Timer? _soundMonitorTimer;
  Timer? _silenceTimer;
  bool _userHasSpoken = false;

  html.AudioElement? _currentAudioElement;
  String? _currentAudioUrl;

  @override
  bool get isRecording => _isRecording;

  @override
  bool get isPlayingAudio => _isPlayingAudio;

  @override
  Future<bool> startRecording({
    required void Function() onStarted,
    required void Function(double soundLevel) onSoundLevel,
    required void Function(String error) onError,
    void Function()? onSilenceDetected,
  }) async {
    await cancel();
    _audioChunks.clear();
    _userHasSpoken = false;

    // Unlock audio context immediately during user click event to satisfy mobile autoplay policies
    _unlockAudioContext();

    try {
      html.window.console.log('[VoiceRecorder] Requesting microphone stream via getUserMedia...');

      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        throw Exception('navigator.mediaDevices is not available in this browser');
      }

      final stream = await mediaDevices.getUserMedia({'audio': true});
      _stream = stream;

      html.window.console.log('[VoiceRecorder] Microphone stream acquired successfully.');

      String mimeType = 'audio/webm';
      if (!html.MediaRecorder.isTypeSupported('audio/webm')) {
        mimeType = 'audio/mp4';
      }

      final recorder = html.MediaRecorder(stream, {'mimeType': mimeType});
      _mediaRecorder = recorder;

      recorder.addEventListener('dataavailable', (html.Event event) {
        final blobEvent = event as html.BlobEvent;
        if (blobEvent.data != null && blobEvent.data!.size > 0) {
          _audioChunks.add(blobEvent.data!);
          html.window.console.log('[VoiceRecorder] ondataavailable chunk: ${blobEvent.data!.size} bytes. Total chunks: ${_audioChunks.length}');
        }
      });

      recorder.start(250);
      _isRecording = true;
      html.window.console.log('[VoiceRecorder] MediaRecorder started ($mimeType). State: listening');

      _setupSoundLevelMonitoring(stream, onSoundLevel, onSilenceDetected);
      onStarted();
      return true;
    } catch (e) {
      _isRecording = false;
      html.window.console.log('[VoiceRecorder] Failed to start recording: $e');
      onError(e.toString());
      await cancel();
      return false;
    }
  }

  void _setupSoundLevelMonitoring(
    html.MediaStream stream,
    void Function(double level) onSoundLevel,
    void Function()? onSilenceDetected,
  ) {
    try {
      final audioCtxConstructor = js.context['AudioContext'] ?? js.context['webkitAudioContext'];
      if (audioCtxConstructor != null) {
        final audioCtx = js.JsObject(audioCtxConstructor, []);
        final source = audioCtx.callMethod('createMediaStreamSource', [stream]);
        final analyser = audioCtx.callMethod('createAnalyser', []);
        analyser['fftSize'] = 64;
        source.callMethod('connect', [analyser]);

        final int binCount = analyser['frequencyBinCount'] as int? ?? 32;
        final uint8Array = js.context['Uint8Array'];
        final jsBuffer = js.JsObject(uint8Array, [binCount]);

        _soundMonitorTimer?.cancel();
        _soundMonitorTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
          if (!_isRecording) return;
          try {
            analyser.callMethod('getByteFrequencyData', [jsBuffer]);
            double sum = 0.0;
            for (int i = 0; i < binCount; i++) {
              final val = (jsBuffer[i] as num?)?.toDouble() ?? 0.0;
              sum += val;
            }
            final avg = binCount > 0 ? (sum / binCount) : 0.0;
            final normalizedLevel = (avg / 255.0) * 15.0;
            onSoundLevel(normalizedLevel);

            if (normalizedLevel > 2.0) {
              _userHasSpoken = true;
              _silenceTimer?.cancel();
              _silenceTimer = null;
            } else if (_userHasSpoken && _silenceTimer == null) {
              _silenceTimer = Timer(const Duration(milliseconds: 1700), () {
                if (_isRecording && _userHasSpoken) {
                  html.window.console.log('[VoiceRecorder] Silence detected after speech. Stopping recording.');
                  onSilenceDetected?.call();
                }
              });
            }
          } catch (_) {}
        });
      }
    } catch (e) {
      html.window.console.log('[VoiceRecorder] AudioContext monitor notice: $e');
    }
  }

  @override
  Future<VoiceAskResult?> stopAndProcessPipeline({
    required String defaultLanguage,
    double? latitude,
    double? longitude,
    void Function(String message)? onStatusUpdate,
    void Function(String transcription, String language)? onTranscriptionReady,
    void Function(String answer)? onAnswerReady,
    void Function()? onAudioPlaybackStarted,
    void Function()? onAudioPlaybackEnded,
  }) async {
    if (!_isRecording && _audioChunks.isEmpty) {
      html.window.console.log('[VoiceRecorder] stopAndProcessPipeline called with no recording and empty chunks.');
      return null;
    }

    _soundMonitorTimer?.cancel();
    _soundMonitorTimer = null;
    _silenceTimer?.cancel();
    _silenceTimer = null;
    _isRecording = false;

    try {
      final recorder = _mediaRecorder;
      if (recorder != null && recorder.state != 'inactive') {
        html.window.console.log('[VoiceRecorder] Stopping MediaRecorder...');
        final stopCompleter = Completer<void>();
        recorder.addEventListener('stop', (_) {
          if (!stopCompleter.isCompleted) stopCompleter.complete();
        });
        recorder.stop();
        await stopCompleter.future.timeout(const Duration(seconds: 2), onTimeout: () {});
      }

      final mimeType = _mediaRecorder?.mimeType ?? 'audio/webm';
      final audioBlob = html.Blob(_audioChunks, mimeType);
      html.window.console.log('[VoiceRecorder] Audio blob ready: size=${audioBlob.size} bytes, type=$mimeType');

      _stopTracks();

      if (audioBlob.size == 0) {
        return VoiceAskResult(
          success: false,
          answer: defaultLanguage == 'gu'
              ? 'અવાજ રેકોર્ડ થયો નથી. કૃપા કરીને ફરી બોલો.'
              : 'No audio recorded. Please try speaking again.',
          error: 'Empty audio buffer',
        );
      }

      // ==========================================
      // STEP 1 (Transcribe):
      // POST raw audio Blob to /api/voice/transcribe
      // Headers: { "Content-Type": "audio/webm" }
      // Body: blob (Directly, NO FormData)
      // Returns JSON: { transcription: "user text", language: "gu" }
      // ==========================================
      onStatusUpdate?.call(
        defaultLanguage == 'gu' ? 'ઑડિયો ટ્રાંસ્ક્રાઇબ થઈ રહ્યું છે...' : 'Transcribing voice...',
      );

      html.window.console.log('[VoiceRecorder] STEP 1: POST raw Blob to ${ApiConstants.voiceTranscribeEndpoint} (size: ${audioBlob.size})');

      final transcribeReq = await html.HttpRequest.request(
        ApiConstants.voiceTranscribeEndpoint,
        method: 'POST',
        sendData: audioBlob,
        requestHeaders: {'Content-Type': mimeType},
      ).timeout(const Duration(seconds: 25));

      html.window.console.log('[VoiceRecorder] STEP 1 status: ${transcribeReq.status}');
      final transcribeBody = transcribeReq.responseText ?? '';
      html.window.console.log('[VoiceRecorder] STEP 1 body: $transcribeBody');

      String transcription = '';
      String currentLang = defaultLanguage;

      if (transcribeReq.status == 200 && transcribeBody.isNotEmpty) {
        try {
          final transcribeData = jsonDecode(transcribeBody) as Map<String, dynamic>;
          transcription = transcribeData['transcription']?.toString() ??
              transcribeData['text']?.toString() ??
              transcribeData['query']?.toString() ??
              '';
          if (transcribeData['language'] != null) {
            currentLang = transcribeData['language'].toString();
          }
        } catch (e) {
          html.window.console.log('[VoiceRecorder] JSON decode error in Step 1: $e');
        }
      }

      if (transcription.trim().isEmpty) {
        return VoiceAskResult(
          success: false,
          answer: defaultLanguage == 'gu'
              ? 'અવાજ બરાબર સંભળાયો નથી. કૃપા કરીને ફરી બોલો.'
              : 'Could not clearly recognize voice. Please try speaking again.',
          error: 'Empty transcription',
        );
      }

      onTranscriptionReady?.call(transcription.trim(), currentLang);

      // ==========================================
      // STEP 2 (Ask LLM):
      // POST transcription to /api/ask
      // Headers: { "Content-Type": "application/json" }
      // Body: { "question": transcription, "language": currentLang }
      // Returns JSON: { answer: "AI reply" }
      // ==========================================
      onStatusUpdate?.call(
        currentLang == 'gu' ? 'વેધરજીપીટી વિચારી રહ્યું છે...' : 'WeatherGPT is thinking...',
      );

      html.window.console.log('[VoiceRecorder] STEP 2: POST /api/ask for: $transcription ($currentLang)');

      final askMap = <String, dynamic>{
        'question': transcription.trim(),
        'language': currentLang,
      };
      if (latitude != null) askMap['latitude'] = latitude;
      if (longitude != null) askMap['longitude'] = longitude;
      final askPayload = jsonEncode(askMap);

      final askReq = await html.HttpRequest.request(
        ApiConstants.aiAskEndpoint,
        method: 'POST',
        sendData: askPayload,
        requestHeaders: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 25));

      html.window.console.log('[VoiceRecorder] STEP 2 status: ${askReq.status}');
      final askBody = askReq.responseText ?? '';
      html.window.console.log('[VoiceRecorder] STEP 2 body: $askBody');

      String answer = '';
      if (askReq.status == 200 && askBody.isNotEmpty) {
        try {
          final askData = jsonDecode(askBody) as Map<String, dynamic>;
          answer = askData['answer']?.toString() ??
              askData['response']?.toString() ??
              askData['message']?.toString() ??
              '';
          if (askData['language'] != null) {
            currentLang = askData['language'].toString();
          }
        } catch (e) {
          html.window.console.log('[VoiceRecorder] JSON decode error in Step 2: $e');
        }
      }

      if (answer.trim().isEmpty) {
        answer = currentLang == 'gu'
            ? 'હવામાન વિગતો મેળવી શકાઈ નથી. ફરી પૂછો.'
            : 'Weather details could not be retrieved right now.';
      }

      onAnswerReady?.call(answer.trim());

      // ==========================================
      // STEP 3 (Speak):
      // POST answer to /api/voice/speak
      // Headers: { "Content-Type": "application/json" }
      // Body: { "text": answer, "language": currentLang }
      // Returns Audio Blob.
      // Play this audio Blob via URL.createObjectURL(blob) + <audio> element.
      // When audio playback ends, automatically trigger onAudioPlaybackEnded (to restart Step 1).
      // Fallback: If speak API fails (e.g. 502/quota), return audioPlayed: false to use TTS.
      // ==========================================
      onStatusUpdate?.call(
        currentLang == 'gu' ? 'વેધરજીપીટી બોલી રહ્યું છે...' : 'WeatherGPT is speaking...',
      );

      html.window.console.log('[VoiceRecorder] STEP 3: Requesting speech blob from ${ApiConstants.voiceSpeakEndpoint}...');

      html.Blob? spokenAudioBlob;
      try {
        final speakCompleter = Completer<html.Blob?>();
        final speakXhr = html.HttpRequest();
        speakXhr.open('POST', ApiConstants.voiceSpeakEndpoint);
        speakXhr.responseType = 'blob';
        speakXhr.setRequestHeader('Content-Type', 'application/json');

        speakXhr.onLoad.listen((_) {
          if (speakXhr.status == 200 && speakXhr.response is html.Blob) {
            final blob = speakXhr.response as html.Blob;
            speakCompleter.complete(blob.size > 0 ? blob : null);
          } else {
            html.window.console.log('[VoiceRecorder] STEP 3 non-200 status: ${speakXhr.status}');
            speakCompleter.complete(null);
          }
        });

        speakXhr.onError.listen((_) => speakCompleter.complete(null));
        speakXhr.onTimeout.listen((_) => speakCompleter.complete(null));
        speakXhr.timeout = 20000;

        speakXhr.send(jsonEncode({
          'text': answer.trim(),
          'language': currentLang,
        }));

        spokenAudioBlob = await speakCompleter.future;
      } catch (e) {
        html.window.console.log('[VoiceRecorder] Exception requesting audio blob in Step 3: $e');
        spokenAudioBlob = null;
      }

      if (spokenAudioBlob != null && spokenAudioBlob.size > 0) {
        html.window.console.log('[VoiceRecorder] STEP 3: Audio Blob received (${spokenAudioBlob.size} bytes). Playing via HTML5 AudioElement...');
        stopPlayback();

        final audioUrl = html.Url.createObjectUrlFromBlob(spokenAudioBlob);
        _currentAudioUrl = audioUrl;
        final audio = html.AudioElement(audioUrl);
        _currentAudioElement = audio;
        _isPlayingAudio = true;

        audio.addEventListener('ended', (event) {
          html.window.console.log('[VoiceRecorder] Audio playback completed. Auto-restarting listening cycle...');
          stopPlayback();
          onAudioPlaybackEnded?.call();
        });

        audio.addEventListener('error', (event) {
          html.window.console.log('[VoiceRecorder] Audio element playback error.');
          stopPlayback();
          onAudioPlaybackEnded?.call();
        });

        onAudioPlaybackStarted?.call();
        bool playStarted = false;
        try {
          await audio.play();
          playStarted = true;
        } catch (playErr) {
          html.window.console.log('[VoiceRecorder] AudioElement play rejected ($playErr), trying Web Audio API buffer fallback...');
          playStarted = await _playBlobViaWebAudioApi(
            spokenAudioBlob,
            onStart: onAudioPlaybackStarted,
            onEnded: () {
              stopPlayback();
              onAudioPlaybackEnded?.call();
            },
          );
        }

        if (!playStarted) {
          html.window.console.log('[VoiceRecorder] Both HTML5 and Web Audio playback failed, falling back to local TTS.');
          return VoiceAskResult(
            success: true,
            answer: answer.trim(),
            question: transcription.trim(),
            language: currentLang,
            audioPlayed: false,
          );
        }

        return VoiceAskResult(
          success: true,
          answer: answer.trim(),
          question: transcription.trim(),
          language: currentLang,
          audioPlayed: true,
        );
      } else {
        html.window.console.log('[VoiceRecorder] STEP 3 speak blob unavailable. Gracefully delegating speech to local TTS.');
        return VoiceAskResult(
          success: true,
          answer: answer.trim(),
          question: transcription.trim(),
          language: currentLang,
          audioPlayed: false,
        );
      }
    } catch (e) {
      html.window.console.log('[VoiceRecorder] Exception during pipeline: $e');
      _stopTracks();
      return VoiceAskResult(
        success: false,
        answer: defaultLanguage == 'gu'
            ? 'નેટવર્ક સમસ્યા આવી છે. કૃપા કરીને ફરી બોલો.'
            : 'Voice pipeline network error. Please try speaking again.',
        error: e.toString(),
        audioPlayed: false,
      );
    }
  }

  @override
  Future<VoiceAskResult?> stopAndAsk({
    required String language,
    double? latitude,
    double? longitude,
  }) async {
    return stopAndProcessPipeline(
      defaultLanguage: language,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  void stopPlayback() {
    if (_currentAudioElement != null) {
      try {
        _currentAudioElement!.pause();
        _currentAudioElement!.src = '';
        _currentAudioElement!.remove();
      } catch (_) {}
      _currentAudioElement = null;
    }
    if (_currentAudioUrl != null) {
      try {
        html.Url.revokeObjectUrl(_currentAudioUrl!);
      } catch (_) {}
      _currentAudioUrl = null;
    }
    _isPlayingAudio = false;
  }

  void _stopTracks() {
    if (_stream != null) {
      try {
        _stream!.getTracks().forEach((track) {
          try {
            track.stop();
          } catch (_) {}
        });
      } catch (_) {}
      _stream = null;
    }
  }

  @override
  Future<void> cancel() async {
    _isRecording = false;
    _soundMonitorTimer?.cancel();
    _soundMonitorTimer = null;
    _silenceTimer?.cancel();
    _silenceTimer = null;

    if (_mediaRecorder != null) {
      try {
        if (_mediaRecorder!.state != 'inactive') {
          _mediaRecorder!.stop();
        }
      } catch (_) {}
      _mediaRecorder = null;
    }
    _stopTracks();
    _audioChunks.clear();
    stopPlayback();
    html.window.console.log('[VoiceRecorder] Recording and playback cancelled.');
  }

  void _unlockAudioContext() {
    try {
      final audioCtxConstructor = js.context['AudioContext'] ?? js.context['webkitAudioContext'];
      if (audioCtxConstructor != null) {
        final ctx = js.JsObject(audioCtxConstructor, []);
        if (ctx['state']?.toString() == 'suspended') {
          ctx.callMethod('resume', []);
        }
        final buffer = ctx.callMethod('createBuffer', [1, 1, 22050]);
        final source = ctx.callMethod('createBufferSource', []);
        source['buffer'] = buffer;
        source.callMethod('connect', [ctx['destination']]);
        source.callMethod('start', [0]);
      }
      final dummy = html.AudioElement();
      dummy.src = 'data:audio/wav;base64,UklGRigAAABXQVZFZm10IBIAAAABAAEARKwAAIhYAQACABAAAABkYXRhAgAAAAEA';
      dummy.play().then((_) {
        dummy.pause();
        dummy.currentTime = 0;
      }).catchError((_) {});
    } catch (_) {}
  }

  Future<bool> _playBlobViaWebAudioApi(
    html.Blob blob, {
    void Function()? onStart,
    void Function()? onEnded,
  }) async {
    try {
      final audioCtxConstructor = js.context['AudioContext'] ?? js.context['webkitAudioContext'];
      if (audioCtxConstructor == null) return false;

      final ctx = js.JsObject(audioCtxConstructor, []);
      if (ctx['state']?.toString() == 'suspended') {
        ctx.callMethod('resume', []);
      }

      final reader = html.FileReader();
      final readCompleter = Completer<dynamic>();
      reader.onLoadEnd.listen((_) => readCompleter.complete(reader.result));
      reader.onError.listen((_) => readCompleter.complete(null));
      reader.readAsArrayBuffer(blob);

      final arrayBuffer = await readCompleter.future;
      if (arrayBuffer == null) return false;

      final decodeCompleter = Completer<dynamic>();
      ctx.callMethod('decodeAudioData', [
        arrayBuffer,
        js.JsFunction.withThis((self, buffer) => decodeCompleter.complete(buffer)),
        js.JsFunction.withThis((self, err) => decodeCompleter.complete(null)),
      ]);

      final decodedBuffer = await decodeCompleter.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
      if (decodedBuffer == null) return false;

      final sourceNode = ctx.callMethod('createBufferSource', []);
      sourceNode['buffer'] = decodedBuffer;
      sourceNode.callMethod('connect', [ctx['destination']]);

      _isPlayingAudio = true;
      onStart?.call();

      sourceNode['onended'] = js.JsFunction.withThis((self, _) {
        _isPlayingAudio = false;
        onEnded?.call();
      });

      sourceNode.callMethod('start', [0]);
      return true;
    } catch (e) {
      html.window.console.log('[VoiceRecorder] _playBlobViaWebAudioApi error: $e');
      return false;
    }
  }
}

PlatformVoiceRecorder createPlatformVoiceRecorder() => WebVoiceRecorder();
