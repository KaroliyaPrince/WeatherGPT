// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'image_compressor_interface.dart';

class WebImageCompressor implements PlatformImageCompressor {
  @override
  Future<String> compressImage(
    Uint8List bytes, {
    int maxWidth = 800,
    int maxHeight = 800,
    double quality = 0.6,
  }) async {
    final blob = html.Blob([bytes]);
    final blobUrl = html.Url.createObjectUrlFromBlob(blob);
    try {
      final image = html.ImageElement();
      final completer = Completer<void>();
      image.onLoad.listen((_) {
        if (!completer.isCompleted) completer.complete();
      });
      image.onError.listen((e) {
        if (!completer.isCompleted) {
          completer.completeError('Failed to load image for compression');
        }
      });
      image.src = blobUrl;
      await completer.future;

      int origW = (image.naturalWidth > 0) ? image.naturalWidth : maxWidth;
      int origH = (image.naturalHeight > 0) ? image.naturalHeight : maxHeight;

      int targetW = origW;
      int targetH = origH;

      if (targetW > maxWidth || targetH > maxHeight) {
        final double ratio = origW / origH;
        if (origW >= origH) {
          targetW = maxWidth;
          targetH = (maxWidth / ratio).round();
        } else {
          targetH = maxHeight;
          targetW = (maxHeight * ratio).round();
        }
      }

      final canvas = html.CanvasElement(width: targetW, height: targetH);
      final ctx = canvas.context2D;
      ctx.drawImageScaled(image, 0, 0, targetW, targetH);

      // Export as canvas.toDataURL('image/jpeg', 0.6)
      final dataUrl = canvas.toDataUrl('image/jpeg', quality);
      return dataUrl;
    } finally {
      html.Url.revokeObjectUrl(blobUrl);
    }
  }
}

PlatformImageCompressor createPlatformImageCompressor() => WebImageCompressor();
