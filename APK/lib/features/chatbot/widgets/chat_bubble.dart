import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../../models/chat_message.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/tts_service.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onEditPrompt;
  final VoidCallback? onRetry;

  const ChatBubble({
    super.key,
    required this.message,
    this.onEditPrompt,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, top: 2),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Attached image thumbnail if user sent image
                if (isUser && message.imageBase64 != null)
                  Builder(
                    builder: (_) {
                      try {
                        final raw = message.imageBase64!.contains(',')
                            ? message.imageBase64!.split(',').last
                            : message.imageBase64!;
                        final bytes = base64Decode(raw);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          constraints: const BoxConstraints(maxWidth: 180, maxHeight: 130),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x330EA5E9), width: 1.5),
                          ),
                          child: Image.memory(bytes, fit: BoxFit.cover),
                        );
                      } catch (_) {
                        return const SizedBox.shrink();
                      }
                    },
                  )
                else if (isUser && message.imagePreviewName != null)
                  Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.70),
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0x260EA5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.image, size: 14, color: Color(0xFF0EA5E9)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            message.imagePreviewName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0EA5E9)),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Main Message Container
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(0xFF0EA5E9)
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isUser ? 30 : 12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Weather Lens Result Card
                      if (!isUser && message.lensData != null)
                        _buildWeatherLensCard(context, message.lensData!),

                      // Weather Radar Card
                      if (!isUser && message.weatherSnapshot != null)
                        _buildWeatherRadarCard(message.weatherSnapshot!),

                      // Main Text Content
                      if (isUser)
                        Text(
                          message.content,
                          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                        )
                      else
                        MarkdownBody(
                          data: message.content,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              fontSize: 13.5,
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 1.5,
                            ),
                            h1: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            h2: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            h3: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            listBullet: TextStyle(color: Theme.of(context).colorScheme.primary),
                            code: TextStyle(
                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              fontSize: 12,
                            ),
                          ),
                        ),

                      // "Why this prediction?" collapsible accordion
                      if (!isUser && message.explainWhy != null)
                        _buildExplainWhyAccordion(context, message.explainWhy),

                      // Retry button on error
                      if (!isUser && message.content.startsWith('⚠️') && onRetry != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0EA5E9),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Retry Analysis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: onRetry,
                          ),
                        ),
                    ],
                  ),
                ),

                // Assistant actions (Copy & Share)
                if (!isUser && message.id != 'initial_greeting')
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.volume_up_rounded, size: 16, color: Color(0xFF0EA5E9)),
                          onPressed: () {
                            final lang = context.read<SettingsProvider>().language;
                            TtsService().unlockAudioContext();
                            TtsService().speak(message.content, language: lang);
                          },
                          tooltip: 'Listen to Voice Replay',
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.grey),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: message.content));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Copied answer to clipboard!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          tooltip: 'Copy answer',
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.share_rounded, size: 16, color: Colors.grey),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: message.content));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Answer copied, ready to share!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          tooltip: 'Share',
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),

                // Edit prompt button for user message
                if (isUser && onEditPrompt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 2),
                    child: InkWell(
                      onTap: onEditPrompt,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_outlined, size: 12, color: Colors.grey),
                          SizedBox(width: 4),
                          Text('Edit', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8, top: 2),
              decoration: const BoxDecoration(
                color: Color(0xFF0EA5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeatherLensCard(BuildContext context, Map<String, dynamic> lens) {
    final cloudType = lens['detectedCloudType'] ?? lens['cloudType'] ?? 'Cumulus';
    final rainRisk = lens['liveRainProbability'] ?? lens['rainRiskPercent'] ?? 20;
    final confidence = lens['aiConfidence'] ?? lens['confidenceScore'] ?? 85;
    final cloudCover = lens['estimatedCloudCoverPercentage'] ?? lens['cloudCoverPercent'] ?? 35;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x1A0EA5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x330EA5E9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.camera_alt, color: Color(0xFF0EA5E9), size: 16),
              const SizedBox(width: 6),
              const Text(
                'WEATHER LENS AI DETECTION',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF0EA5E9), letterSpacing: 0.8),
              ),
              const Spacer(),
              Text('🛡️ $confidence% confident', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildLensMetric(context, 'Cloud Type', '☁️ $cloudType'),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildLensMetric(context, 'Coverage', '$cloudCover%'),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildLensMetric(context, 'Rain Risk', '$rainRisk%', isRisk: true),
              ),
            ],
          ),
          if (lens['skyCondition'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wb_sunny_outlined, size: 13, color: Color(0xFF0EA5E9)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${lens['skyCondition']}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (lens['advisory'] != null) ...[
            const SizedBox(height: 6),
            Text(
              '${lens['advisory']}',
              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLensMetric(BuildContext context, String label, String value, {bool isRisk = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isRisk ? Colors.red : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherRadarCard(Map<String, dynamic> w) {
    final temp = w['temperature'] ?? w['temp_c'] ?? 28;
    final cond = w['condition'] ?? 'Clear';
    final rain = w['rain_probability'] ?? 10;
    final humidity = w['humidity'] ?? 55;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$cond', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('Rain Chance: $rain%  •  Humidity: $humidity%', style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('$temp°C', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildExplainWhyAccordion(BuildContext context, dynamic explain) {
    String title = 'Why this prediction?';
    String summary = '';
    List<String> factors = [];

    if (explain is Map) {
      title = explain['title']?.toString() ?? title;
      summary = explain['summary']?.toString() ?? '';
      if (explain['factors'] is List) {
        factors = (explain['factors'] as List).map((e) => e.toString()).toList();
      }
    } else if (explain is String) {
      summary = explain;
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: const Color(0x0D0EA5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x260EA5E9)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          leading: const Icon(Icons.lightbulb_outline, color: Color(0xFF0EA5E9), size: 16),
          title: Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0EA5E9)),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (summary.isNotEmpty)
                    Text(summary, style: const TextStyle(fontSize: 11, height: 1.4)),
                  if (factors.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    ...factors.map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text('• $f', style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
                        )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
