import 'dart:async';
import 'voice_recorder_interface.dart';

class StubVoiceRecorder implements PlatformVoiceRecorder {
  bool _isRecording = false;
  bool _isPlayingAudio = false;

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
    _isRecording = true;
    onStarted();
    return true;
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
    _isRecording = false;
    onStatusUpdate?.call('Transcribing...');
    const transcription = 'What is the weather today?';
    onTranscriptionReady?.call(transcription, defaultLanguage);

    onStatusUpdate?.call('Thinking...');
    const answer = 'Current weather is sunny and clear.';
    onAnswerReady?.call(answer);

    return VoiceAskResult(
      success: true,
      answer: answer,
      question: transcription,
      language: defaultLanguage,
      audioPlayed: false,
    );
  }

  @override
  Future<VoiceAskResult?> stopAndAsk({
    required String language,
    double? latitude,
    double? longitude,
  }) async {
    _isRecording = false;
    return VoiceAskResult(
      success: true,
      answer: 'This is a simulated voice response.',
      question: 'What is the weather today?',
      language: language,
      audioPlayed: false,
    );
  }

  @override
  void stopPlayback() {
    _isPlayingAudio = false;
  }

  @override
  Future<void> cancel() async {
    _isRecording = false;
    _isPlayingAudio = false;
  }
}

PlatformVoiceRecorder createPlatformVoiceRecorder() => StubVoiceRecorder();
