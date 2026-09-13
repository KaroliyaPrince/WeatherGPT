import 'voice_recorder_interface.dart';
import 'voice_recorder_stub.dart'
    if (dart.library.html) 'voice_recorder_web.dart';

PlatformVoiceRecorder getVoiceRecorder() => createPlatformVoiceRecorder();
