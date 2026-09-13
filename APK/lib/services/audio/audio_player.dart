import 'audio_player_interface.dart';
import 'audio_player_stub.dart'
    if (dart.library.html) 'audio_player_web.dart';

PlatformAudioPlayer getAudioPlayer() => createPlatformAudioPlayer();
