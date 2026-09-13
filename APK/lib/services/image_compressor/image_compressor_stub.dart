import 'dart:convert';
import 'dart:typed_data';
import 'image_compressor_interface.dart';

class StubImageCompressor implements PlatformImageCompressor {
  @override
  Future<String> compressImage(
    Uint8List bytes, {
    int maxWidth = 800,
    int maxHeight = 800,
    double quality = 0.6,
  }) async {
    // Non-web platform: image_picker already applies maxWidth/maxHeight/imageQuality
    final b64 = base64Encode(bytes);
    return 'data:image/jpeg;base64,$b64';
  }
}

PlatformImageCompressor createPlatformImageCompressor() => StubImageCompressor();
