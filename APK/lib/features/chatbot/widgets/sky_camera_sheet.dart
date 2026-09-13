import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/image_compressor/image_compressor.dart';

class SkyCameraSheet extends StatefulWidget {
  final Function(String base64Image, String imageName, String suggestedPrompt) onImageSelected;

  const SkyCameraSheet({super.key, required this.onImageSelected});

  @override
  State<SkyCameraSheet> createState() => _SkyCameraSheetState();
}

class _SkyCameraSheetState extends State<SkyCameraSheet> {
  bool _isCompressing = false;
  String _statusText = 'Optimizing image...';

  static final List<Map<String, String>> skyPresets = [
    {
      'title': 'Cumulonimbus (Rain Cloud)',
      'desc': 'Towering vertical storm clouds',
      'icon': '⛈️',
      'base64': 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
    },
    {
      'title': 'Altocumulus (Overcast)',
      'desc': 'Fluffy roll clouds in layers',
      'icon': '🌥️',
      'base64': 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
    },
    {
      'title': 'Clear Blue Sky',
      'desc': 'Sunny with minimal wispy clouds',
      'icon': '☀️',
      'base64': 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
    },
  ];

  Future<void> _pickFromSource(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 60,
      );

      if (photo != null) {
        setState(() {
          _isCompressing = true;
          _statusText = 'Compressing & preparing image for AI...';
        });

        final bytes = await photo.readAsBytes();
        final compressor = getImageCompressor();
        final compressedB64 = await compressor.compressImage(
          bytes,
          maxWidth: 800,
          maxHeight: 800,
          quality: 0.6,
        );

        if (!mounted) return;
        Navigator.pop(context);
        widget.onImageSelected(
          compressedB64,
          photo.name,
          'Analyze this sky photo for cloud formation and rain risk.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCompressing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera/Gallery error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(100),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0x1A0EA5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0EA5E9), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Weather Lens (Sky Camera)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        Text('AI cloud identification and rain probability', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              if (_isCompressing)
                Container(
                  padding: const EdgeInsets.all(28),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF0EA5E9), strokeWidth: 3),
                      const SizedBox(height: 16),
                      Text(
                        _statusText,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else ...[
                // Option 1: Camera
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF0EA5E9),
                      child: Icon(Icons.photo_camera, color: Colors.white, size: 20),
                    ),
                    title: const Text('Take Live Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Snap the sky above you with your camera', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    onTap: () => _pickFromSource(ImageSource.camera),
                  ),
                ),
                const SizedBox(height: 8),

                // Option 2: Gallery
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF6366F1),
                      child: Icon(Icons.photo_library, color: Colors.white, size: 20),
                    ),
                    title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Pick a sky photo from your phone storage', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    onTap: () => _pickFromSource(ImageSource.gallery),
                  ),
                ),
                const SizedBox(height: 16),

                // Option 3: Presets
                const Text('Or Select Sample Cloud Preset:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: skyPresets.length,
                    itemBuilder: (context, i) {
                      final p = skyPresets[i];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: Text(p['icon']!),
                          label: Text(p['title']!, style: const TextStyle(fontSize: 11)),
                          backgroundColor: theme.cardColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onImageSelected(
                              p['base64']!,
                              p['title']!,
                              'Analyze this ${p['title']} cloud formation.',
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
