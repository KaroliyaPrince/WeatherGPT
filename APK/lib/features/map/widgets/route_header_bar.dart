import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/route_weather_provider.dart';

class RouteHeaderBar extends StatefulWidget {
  final VoidCallback? onClose;

  const RouteHeaderBar({
    super.key,
    this.onClose,
  });

  @override
  State<RouteHeaderBar> createState() => _RouteHeaderBarState();
}

class _RouteHeaderBarState extends State<RouteHeaderBar> {
  late TextEditingController _sourceController;
  late TextEditingController _destController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<RouteWeatherProvider>();
    _sourceController = TextEditingController(text: provider.source);
    _destController = TextEditingController(text: provider.destination);
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _destController.dispose();
    super.dispose();
  }

  void _searchRoute() {
    FocusScope.of(context).unfocus();
    final provider = context.read<RouteWeatherProvider>();
    provider.calculateRoute(
      sourceOverride: _sourceController.text.trim(),
      destOverride: _destController.text.trim(),
    );
  }

  void _applyPreset(String from, String to) {
    _sourceController.text = from;
    _destController.text = to;
    _searchRoute();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RouteWeatherProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = provider.isLoading;

    // Keep controllers in sync if provider changed externally (e.g. swap)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_sourceController.text != provider.source && !FocusScope.of(context).hasFocus) {
        _sourceController.text = provider.source;
      }
      if (_destController.text != provider.destination && !FocusScope.of(context).hasFocus) {
        _destController.text = provider.destination;
      }
    });

    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2E000000),
              blurRadius: 18,
              offset: Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Title & Close Button
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.alt_route_rounded, color: Color(0xFF0EA5E9), size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Highway Route Weather',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  if (widget.onClose != null)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      tooltip: 'Exit Route Mode',
                      onPressed: widget.onClose,
                    ),
                ],
              ),
            ),

            // Source & Destination Input Fields with Swap & Search Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        // Source Field
                        Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: _sourceController,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'Source (e.g. Rajkot)',
                              hintStyle: TextStyle(fontSize: 12.5),
                              prefixIcon: Icon(Icons.trip_origin_rounded, color: Color(0xFF10B981), size: 15),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Destination Field
                        Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: _destController,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _searchRoute(),
                            decoration: const InputDecoration(
                              hintText: 'Destination (e.g. Ahmedabad)',
                              hintStyle: TextStyle(fontSize: 12.5),
                              prefixIcon: Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 15),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Actions: Swap & Search Button
                  Column(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        icon: const Icon(Icons.swap_vert_rounded, color: Color(0xFF0EA5E9), size: 22),
                        tooltip: 'Swap Source & Destination',
                        onPressed: () {
                          provider.swapSourceAndDestination();
                          _sourceController.text = provider.source;
                          _destController.text = provider.destination;
                        },
                      ),
                      const SizedBox(height: 4),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF0EA5E9),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(36, 36),
                        ),
                        icon: isLoading
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.search_rounded, size: 18),
                        onPressed: isLoading ? null : _searchRoute,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Horizontal Presets
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Row(
                children: [
                  _buildPresetChip('Morbi', 'Rajkot'),
                  _buildPresetChip('Rajkot', 'Ahmedabad'),
                  _buildPresetChip('Mumbai', 'Pune'),
                  _buildPresetChip('Surat', 'Vadodara'),
                  _buildPresetChip('Delhi', 'Agra'),
                  _buildPresetChip('Ahmedabad', 'Udaipur'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String from, String to) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => _applyPreset(from, to),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF0EA5E9).withAlpha(20),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF0EA5E9).withAlpha(50)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$from → $to',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0EA5E9)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
