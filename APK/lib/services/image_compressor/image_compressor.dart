import 'image_compressor_interface.dart';
import 'image_compressor_stub.dart'
    if (dart.library.html) 'image_compressor_web.dart';

PlatformImageCompressor getImageCompressor() => createPlatformImageCompressor();
