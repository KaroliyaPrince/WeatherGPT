class VoiceAskResult {
  final bool success;
  final String answer;
  final String? question;
  final String? language;
  final String? error;
  final bool audioPlayed;

  VoiceAskResult({
    required this.success,
    required this.answer,
    this.question,
    this.language,
    this.error,
    this.audioPlayed = false,
  });
}

abstract class PlatformVoiceRecorder {
  bool get isRecording;
  bool get isPlayingAudio;

  /// Requests microphone via navigator.mediaDevices.getUserMedia({ audio: true })
  /// and starts recording with MediaRecorder.
  Future<bool> startRecording({
    required void Function() onStarted,
    required void Function(double soundLevel) onSoundLevel,
    required void Function(String error) onError,
    void Function()? onSilenceDetected,
  });

  /// Sequential 3-Step Voice Pipeline:
  /// STEP 1 (Transcribe): When MediaRecorder stops, POST raw audio Blob to /api/voice/transcribe
  /// STEP 2 (Ask LLM): POST { question, language } to /api/ask
  /// STEP 3 (Speak): POST { text, language } to /api/voice/speak -> returns Audio Blob, plays via <audio>
  /// When audio playback ends, automatically triggers onAudioPlaybackEnded to restart listening.
  Future<VoiceAskResult?> stopAndProcessPipeline({
    required String defaultLanguage,
    double? latitude,
    double? longitude,
    void Function(String message)? onStatusUpdate,
    void Function(String transcription, String language)? onTranscriptionReady,
    void Function(String answer)? onAnswerReady,
    void Function()? onAudioPlaybackStarted,
    void Function()? onAudioPlaybackEnded,
  });

  /// Legacy/direct stop and ask convenience method
  Future<VoiceAskResult?> stopAndAsk({
    required String language,
    double? latitude,
    double? longitude,
  });

  /// Immediately stop active audio playback (e.g. user interruption)
  void stopPlayback();

  /// Cancels recording and stops all microphone stream tracks.
  Future<void> cancel();
}
