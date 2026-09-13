import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../models/weather_data.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/settings_provider.dart';

class WeatherGptAiCard extends StatefulWidget {
  final WeatherData data;
  final VoidCallback? onOpenChatbot;

  const WeatherGptAiCard({
    super.key,
    required this.data,
    this.onOpenChatbot,
  });

  @override
  State<WeatherGptAiCard> createState() => _WeatherGptAiCardState();
}

class _WeatherGptAiCardState extends State<WeatherGptAiCard> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final List<String> _suggestedPrompts = [
    '🌧️ Will it rain today?',
    '👕 What to wear now?',
    '🌾 Outdoor & crop advice',
    '☂️ Need an umbrella?',
    '🏃 Good for a run?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitPrompt(String query, ChatProvider chatProvider, LocationProvider locProvider, SettingsProvider settingsProvider) {
    if (query.trim().isEmpty) return;
    _focusNode.unfocus();
    _controller.clear();

    chatProvider.sendMessage(
      question: query,
      location: locProvider.currentLocation,
      language: settingsProvider.language,
    );
  }

  String _getSmartContextSummary(WeatherData data) {
    final temp = data.temperature.round();
    final cond = data.condition.toLowerCase();
    final rain = data.hourly.isNotEmpty ? data.hourly.first.rainProbability : 0;

    if (rain > 50 || cond.contains('rain') || cond.contains('drizzle')) {
      return 'Elevated precipitation risk detected ($rain%). Expect wet roads; carry an umbrella and plan travel safely.';
    } else if (temp > 35) {
      return 'High thermal conditions ($temp°C). Stay hydrated and avoid strenuous outdoor activity during midday peak.';
    } else if (temp < 15) {
      return 'Cooler weather ($temp°C). A light jacket is recommended for early morning and evening commute.';
    } else if (data.humidity > 75) {
      return 'High atmospheric moisture (${data.humidity}%). Apparent temperature feels warmer at ${data.apparentTemperature.round()}°C.';
    } else {
      return 'Optimal weather with $cond ($temp°C). UV index is ${data.uvIndex}. Excellent window for daily outdoor routines.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final locProvider = context.watch<LocationProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    final assistantMessages = chatProvider.messages.where((m) => m.role == 'assistant').toList();
    final latestAiMessage = assistantMessages.isNotEmpty
        ? assistantMessages.last.content
        : null;

    final isTyping = chatProvider.isTyping;

    return GlassContainer(
      level: GlassLevel.dark,
      borderRadius: 24.0,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Sparkle + Title + Full Chat Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.windCyan.withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.windCyan.withAlpha(80),
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: AppColors.windCyan,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WeatherGPT AI Assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.curveActive,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Powered by Gemini 2.5',
                            style: TextStyle(
                              color: Colors.white.withAlpha(190),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              if (widget.onOpenChatbot != null)
                GestureDetector(
                  onTap: widget.onOpenChatbot,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withAlpha(30),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Full Chat',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // AI Response or Synthesized Context
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withAlpha(15),
              ),
            ),
            child: isTyping
                ? const Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.windCyan),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'WeatherGPT is generating meteorological advice...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  )
                : Text(
                    latestAiMessage ?? _getSmartContextSummary(widget.data),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),

          const SizedBox(height: 12),

          // Prompt Suggestion Chips
          SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _suggestedPrompts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = _suggestedPrompts[index];
                return GestureDetector(
                  onTap: () => _submitPrompt(prompt, chatProvider, locProvider, settingsProvider),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withAlpha(30),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        prompt,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Quick Query Input Field
          Container(
            height: 42,
            padding: const EdgeInsets.only(left: 12, right: 4),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(21),
              border: Border.all(
                color: Colors.white.withAlpha(35),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 15,
                  color: Colors.white.withAlpha(180),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (val) => _submitPrompt(val, chatProvider, locProvider, settingsProvider),
                    decoration: InputDecoration(
                      hintText: 'Ask WeatherGPT anything about today...',
                      hintStyle: TextStyle(
                        color: Colors.white.withAlpha(140),
                        fontSize: 12,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _submitPrompt(_controller.text, chatProvider, locProvider, settingsProvider),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      color: Color(0xFF1D4ED8),
                      size: 17,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
