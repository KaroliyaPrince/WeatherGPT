import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_session.dart';
import '../../providers/chat_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/settings_provider.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/sky_camera_sheet.dart';
import 'widgets/voice_assistant_sheet.dart';
import 'live_call_screen.dart';
import '../../services/tts_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _selectedImageBase64;
  String? _selectedImageName;

  static const Map<String, Map<String, String>> _personas = {
    'general': {'title': 'General', 'icon': '🌐', 'desc': 'Everyday weather advice'},
    'farmer': {'title': 'Farmer', 'icon': '🌾', 'desc': 'Kisan advisory & crops'},
    'traveler': {'title': 'Traveler', 'icon': '🧳', 'desc': 'Road & outdoor conditions'},
    'student': {'title': 'Student', 'icon': '🎒', 'desc': 'School & transit forecasts'},
    'elderly': {'title': 'Elderly', 'icon': '👴', 'desc': 'Health, heat & air quality'},
    'outdoor_worker': {'title': 'Worker', 'icon': '👷', 'desc': 'Sun exposure & rain risk'},
  };

  static const List<String> _quickPrompts = [
    '☀️ What is the weather today?',
    '🌧️ Will it rain this evening?',
    '👕 What should I wear today?',
    '☂️ Do I need an umbrella?',
    '🌾 Farming advice for crops',
    '🚗 Is it safe to travel tomorrow?',
  ];

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend([String? overrideText, bool speakReply = false]) async {
    final text = (overrideText ?? _controller.text).trim();
    if (text.isEmpty && _selectedImageBase64 == null) return;

    if (speakReply) {
      TtsService().unlockAudioContext();
    }

    final chatProvider = context.read<ChatProvider>();
    final locProvider = context.read<LocationProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    final image = _selectedImageBase64;
    final imageName = _selectedImageName;

    setState(() {
      _controller.clear();
      _selectedImageBase64 = null;
      _selectedImageName = null;
    });

    final assistantMsg = await chatProvider.sendMessage(
      question: text,
      location: locProvider.currentLocation,
      language: settingsProvider.language,
      imageBase64: image,
      imageName: imageName,
    );

    _scrollToBottom();

    if (speakReply && assistantMsg != null && mounted) {
      TtsService().speak(assistantMsg.content, language: settingsProvider.language);
    }
  }

  void _showPersonaPicker() {
    final chatProvider = context.read<ChatProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.75,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: 24 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
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
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Select AI Persona',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Personalize weather insights for your daily activities',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ..._personas.entries.map((p) {
                    final isSelected = chatProvider.selectedPersona == p.key;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0x260EA5E9)
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(p.value['icon']!, style: const TextStyle(fontSize: 20)),
                      ),
                      title: Text(
                        p.value['title']!,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? const Color(0xFF0EA5E9) : null,
                        ),
                      ),
                      subtitle: Text(p.value['desc']!, style: const TextStyle(fontSize: 12)),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Color(0xFF0EA5E9))
                          : null,
                      onTap: () {
                        chatProvider.setPersona(p.key);
                        Navigator.pop(ctx);
                      },
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCameraSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SkyCameraSheet(
        onImageSelected: (base64, name, prompt) {
          setState(() {
            _selectedImageBase64 = base64;
            _selectedImageName = name;
            _controller.text = prompt;
          });
          // Automatically dispatch Weather Lens analysis
          _handleSend(prompt);
        },
      ),
    );
  }

  void _openLiveCall() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LiveCallScreen()),
    );
  }

  void _startRealVoiceAssistant() {
    TtsService().unlockAudioContext();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => VoiceAssistantSheet(
        onSendQuery: (query) {
          _handleSend(query, true);
        },
        onOpenLiveCall: _openLiveCall,
      ),
    );
  }

  String _formatSessionTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}';
  }

  void _confirmDeleteSession(BuildContext context, ChatSession session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Conversation?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text('Are you sure you want to delete "${session.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ChatProvider>().deleteSession(session.id);
            },
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Clear All Conversations?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: const Text('This will delete all saved chat history. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              context.read<ChatProvider>().clearAllHistory();
            },
            child: const Text('Clear All', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryDrawer(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final sessions = chatProvider.sessions;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 10, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.history_rounded, color: Color(0xFF0EA5E9), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Chat History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 0.8),

            // Start New Chat Button in Drawer
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  chatProvider.startNewChat();
                  _controller.clear();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0EA5E9).withAlpha(50),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Start New Chat',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Sessions List
            Expanded(
              child: sessions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 40, color: Colors.grey.withAlpha(120)),
                          const SizedBox(height: 10),
                          Text(
                            'No previous chats',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      itemCount: sessions.length,
                      itemBuilder: (ctx, idx) {
                        final s = sessions[idx];
                        final isActive = s.id == chatProvider.currentSessionId;
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 3.5),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF0EA5E9).withAlpha(isDark ? 40 : 25)
                                : (isDark ? const Color(0x15FFFFFF) : const Color(0x0A000000)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive
                                  ? const Color(0xFF0EA5E9).withAlpha(120)
                                  : Colors.transparent,
                              width: 1.2,
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.only(left: 12, right: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            leading: Icon(
                              isActive
                                  ? Icons.chat_rounded
                                  : Icons.chat_bubble_outline_rounded,
                              size: 18,
                              color: isActive ? const Color(0xFF0EA5E9) : Colors.grey.shade500,
                            ),
                            title: Text(
                              s.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                color: isActive
                                    ? (isDark ? Colors.lightBlueAccent : const Color(0xFF0284C7))
                                    : null,
                              ),
                            ),
                            subtitle: Text(
                              '${_formatSessionTime(s.updatedAt)} • ${s.messages.length} msgs',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18),
                              color: Colors.grey.shade500,
                              tooltip: 'Delete',
                              onPressed: () => _confirmDeleteSession(context, s),
                            ),
                            onTap: () {
                              chatProvider.loadSession(s.id);
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
            ),

            // Bottom Clear All & Count Section
            const Divider(height: 1, thickness: 0.8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 10),
              child: Row(
                children: [
                  Text(
                    '${sessions.length} ${sessions.length == 1 ? 'chat' : 'chats'} saved',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: sessions.length <= 1 && sessions.every((s) => s.messages.length <= 1)
                        ? null
                        : () => _confirmClearAll(context),
                    icon: const Icon(Icons.delete_sweep_rounded, size: 16, color: Colors.redAccent),
                    label: const Text(
                      'Clear All',
                      style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final messages = chatProvider.messages;
    final isTyping = chatProvider.isTyping;
    final persona = _personas[chatProvider.selectedPersona] ?? _personas['general']!;

    return Scaffold(
      drawer: _buildHistoryDrawer(context),
      appBar: AppBar(
        titleSpacing: 0,
        centerTitle: false,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.history_rounded, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            tooltip: 'Chat History',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(3.5),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 13),
            ),
            const SizedBox(width: 5),
            const Flexible(
              child: Text(
                'WeatherGPT',
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        actions: [
          // Live Call Phone Button
          IconButton(
            icon: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF10B981), size: 19),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Live AI Voice Call',
            onPressed: _openLiveCall,
          ),
          const SizedBox(width: 3),
          // Persona Selector
          GestureDetector(
            onTap: _showPersonaPicker,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0x1A0EA5E9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x330EA5E9)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(persona['icon']!, style: const TextStyle(fontSize: 11)),
                  const SizedBox(width: 2),
                  Text(
                    persona['title']!,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0EA5E9)),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 13, color: Color(0xFF0EA5E9)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          // New Chat Button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: ElevatedButton.icon(
              onPressed: () {
                chatProvider.startNewChat();
                _controller.clear();
              },
              icon: const Icon(Icons.add_rounded, size: 14),
              label: const Text('New Chat', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 0),
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final msg = messages[i];
                return ChatBubble(
                  message: msg,
                  onEditPrompt: () => _controller.text = msg.content,
                  onRetry: msg.content.startsWith('⚠️')
                      ? () {
                          final userMsgs = messages.where((m) => m.isUser).toList();
                          if (userMsgs.isNotEmpty) {
                            final lastUser = userMsgs.last;
                            if (lastUser.imageBase64 != null) {
                              setState(() {
                                _selectedImageBase64 = lastUser.imageBase64;
                                _selectedImageName = lastUser.imagePreviewName;
                              });
                            }
                            _handleSend(lastUser.content);
                          }
                        }
                      : null,
                );
              },
            ),
          ),

          // Typing Loader
          if (isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0EA5E9)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    chatProvider.isAnalyzingSky
                        ? 'Analyzing sky...'
                        : 'WeatherGPT is forecasting...',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                ],
              ),
            ),

          // Suggestion Chips (when user is starting conversation)
          if (messages.length <= 2 && !isTyping)
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: _quickPrompts.length,
                itemBuilder: (context, i) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(_quickPrompts[i], style: const TextStyle(fontSize: 11.5)),
                      backgroundColor: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: const Color(0xFF0EA5E9).withAlpha(50)),
                      ),
                      onPressed: () => _handleSend(_quickPrompts[i]),
                    ),
                  );
                },
              ),
            ),

          // Attached Image Preview Bar
          if (_selectedImageBase64 != null)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 6, 14, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0x260EA5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x4D0EA5E9)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.camera_alt, size: 16, color: Color(0xFF0EA5E9)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ready to analyze: $_selectedImageName',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0EA5E9)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Color(0xFF0EA5E9)),
                    onPressed: () => setState(() {
                      _selectedImageBase64 = null;
                      _selectedImageName = null;
                    }),
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

          // Input Bar
          Builder(
            builder: (context) {
              final viewInsets = View.of(context).viewInsets.bottom;
              final mediaInsets = MediaQuery.of(context).viewInsets.bottom;
              final isKeyboardOpen = viewInsets > 0 || mediaInsets > 0;
              final bottomPad = isKeyboardOpen ? 6.0 : 88.0;

              return Container(
                padding: EdgeInsets.fromLTRB(10, 8, 10, bottomPad),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: const [
                    BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, -2)),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: Row(
                children: [
                  // Camera / Sky Lens Button
                  IconButton(
                    icon: Icon(
                      Icons.camera_alt_outlined,
                      color: _selectedImageBase64 != null ? const Color(0xFF0EA5E9) : Colors.grey.shade600,
                    ),
                    tooltip: 'Weather Lens (Camera / Presets)',
                    onPressed: _showCameraSheet,
                  ),

                  // Mic Button
                  IconButton(
                    icon: const Icon(
                      Icons.mic_none_rounded,
                      color: Color(0xFF0EA5E9),
                    ),
                    tooltip: 'Voice Assistant',
                    onPressed: _startRealVoiceAssistant,
                  ),

                  // Text Field
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _handleSend(),
                        decoration: InputDecoration(
                          hintText: _selectedImageBase64 != null
                              ? 'Ask about this sky...'
                              : 'Ask WeatherGPT anything...',
                          hintStyle: const TextStyle(fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send Button
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF0EA5E9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: isTyping ? null : () => _handleSend(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ],
  ),
);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
