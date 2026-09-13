import 'dart:typed_data';

abstract class PlatformImageCompressor {
  /// Compresses the image bytes using client-side canvas/native techniques.
  /// Enforces maximum width and height bounds (default 800px) and JPEG quality (0.6).
  /// Returns the base64 or data URL representation.
  Future<String> compressImage(
    Uint8List bytes, {
    int maxWidth = 800,
    int maxHeight = 800,
    double quality = 0.6,
  });
}
