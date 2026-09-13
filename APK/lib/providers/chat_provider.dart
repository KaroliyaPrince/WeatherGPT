import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../models/location_model.dart';
import '../repositories/chat_repository.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _repository;

  List<ChatSession> _sessions = [];
  String _currentSessionId = '';
  bool _isTyping = false;
  bool _isAnalyzingSky = false;
  String _selectedPersona = 'general';
  String? _error;

  ChatProvider(this._repository) {
    _loadInitialSessions();
  }

  List<ChatSession> get sessions => List.unmodifiable(_sessions);
  String get currentSessionId => _currentSessionId;
  ChatRepository get repository => _repository;

  ChatSession? get currentSession {
    final idx = _sessions.indexWhere((s) => s.id == _currentSessionId);
    return idx != -1 ? _sessions[idx] : (_sessions.isNotEmpty ? _sessions.first : null);
  }

  List<ChatMessage> get messages {
    final session = currentSession;
    return session != null ? List.unmodifiable(session.messages) : const [];
  }

  bool get isTyping => _isTyping;
  bool get isAnalyzingSky => _isAnalyzingSky;
  String get selectedPersona => _selectedPersona;
  String? get error => _error;

  ChatMessage _createGreeting() {
    return ChatMessage(
      id: 'greeting_${DateTime.now().millisecondsSinceEpoch}',
      role: 'assistant',
      content: 'Hello! I am **WeatherGPT**, your meteorological AI assistant.\n\nAsk me about current conditions, rain forecasts, travel safety, agricultural advice, or snap a sky photo with the camera!',
      timestamp: DateTime.now(),
    );
  }

  void _loadInitialSessions() {
    try {
      final saved = _repository.storageService.getChatSessions();
      if (saved.isNotEmpty) {
        _sessions = saved;
        _currentSessionId = _sessions.first.id;
      } else {
        final newSession = ChatSession(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'New Conversation',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          messages: [_createGreeting()],
        );
        _sessions = [newSession];
        _currentSessionId = newSession.id;
        _repository.storageService.saveChatSessions(_sessions);
      }
    } catch (_) {
      final newSession = ChatSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'New Conversation',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        messages: [_createGreeting()],
      );
      _sessions = [newSession];
      _currentSessionId = newSession.id;
    }
  }

  void setPersona(String persona) {
    _selectedPersona = persona;
    notifyListeners();
  }

  Future<void> startNewChat() async {
    // If current session already has only the initial greeting and no other messages, keep it
    if (currentSession != null &&
        currentSession!.messages.length <= 1 &&
        currentSession!.messages.every((m) => m.role == 'assistant')) {
      return;
    }

    final newSession = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Conversation',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: [_createGreeting()],
    );

    _sessions.insert(0, newSession);
    _currentSessionId = newSession.id;
    _repository.clearConversation();
    notifyListeners();
    await _repository.storageService.saveChatSessions(_sessions);
  }

  void loadSession(String sessionId) {
    if (_currentSessionId == sessionId) return;
    final exists = _sessions.any((s) => s.id == sessionId);
    if (exists) {
      _currentSessionId = sessionId;
      notifyListeners();
    }
  }

  Future<void> deleteSession(String sessionId) async {
    _sessions.removeWhere((s) => s.id == sessionId);
    if (_sessions.isEmpty) {
      final newSession = ChatSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'New Conversation',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        messages: [_createGreeting()],
      );
      _sessions.add(newSession);
      _currentSessionId = newSession.id;
      _repository.clearConversation();
    } else if (_currentSessionId == sessionId) {
      _currentSessionId = _sessions.first.id;
    }
    notifyListeners();
    await _repository.storageService.saveChatSessions(_sessions);
  }

  Future<void> clearAllHistory() async {
    await _repository.clearConversation();
    await _repository.storageService.clearChatSessions();
    final newSession = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Conversation',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: [_createGreeting()],
    );
    _sessions = [newSession];
    _currentSessionId = newSession.id;
    notifyListeners();
    await _repository.storageService.saveChatSessions(_sessions);
  }

  Future<ChatMessage?> sendMessage({
    required String question,
    WeatherLocation? location,
    String language = 'en',
    String? imageBase64,
    String? imageName,
  }) async {
    final query = question.trim();
    if (query.isEmpty && imageBase64 == null) return null;
    if (_isTyping) return null;

    final sessionIdx = _sessions.indexWhere((s) => s.id == _currentSessionId);
    if (sessionIdx == -1) return null;

    final currentSes = _sessions[sessionIdx];
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: query.isEmpty ? 'Analyze sky cloud formation' : query,
      imagePreviewName: imageName,
      imageBase64: imageBase64,
      timestamp: DateTime.now(),
    );

    // Compute updated session title if it's default
    String updatedTitle = currentSes.title;
    if (updatedTitle == 'New Conversation' || updatedTitle == 'Weather Discussion') {
      final titleCandidate = query.isNotEmpty ? query : (imageName ?? 'Sky Analysis');
      updatedTitle = titleCandidate.length > 28
          ? '${titleCandidate.substring(0, 28)}...'
          : titleCandidate;
    }

    final updatedMessages = List<ChatMessage>.from(currentSes.messages)..add(userMsg);
    _sessions[sessionIdx] = currentSes.copyWith(
      title: updatedTitle,
      updatedAt: DateTime.now(),
      messages: updatedMessages,
    );

    // Move active session to top if not already
    if (sessionIdx > 0) {
      final s = _sessions.removeAt(sessionIdx);
      _sessions.insert(0, s);
    }

    _isTyping = true;
    _isAnalyzingSky = (imageBase64 != null);
    _error = null;
    notifyListeners();
    _repository.storageService.saveChatSessions(_sessions);

    try {
      ChatMessage assistantMsg;
      if (imageBase64 != null) {
        assistantMsg = await _repository.sendWeatherLensImage(
          imageBase64: imageBase64,
          question: query,
          location: location,
          language: language,
        );
      } else {
        assistantMsg = await _repository.sendMessage(
          question: query,
          location: location,
          persona: _selectedPersona,
          language: language,
        );
      }

      final activeIdx = _sessions.indexWhere((s) => s.id == _currentSessionId);
      if (activeIdx != -1) {
        final ses = _sessions[activeIdx];
        final msgs = List<ChatMessage>.from(ses.messages)..add(assistantMsg);
        _sessions[activeIdx] = ses.copyWith(
          updatedAt: DateTime.now(),
          messages: msgs,
        );
      }
      return assistantMsg;
    } catch (e) {
      final errorMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'assistant',
        content: '⚠️ **Error**: Unable to reach WeatherGPT AI right now. Please verify your connection or try again.',
        timestamp: DateTime.now(),
      );

      final activeIdx = _sessions.indexWhere((s) => s.id == _currentSessionId);
      if (activeIdx != -1) {
        final ses = _sessions[activeIdx];
        final msgs = List<ChatMessage>.from(ses.messages)..add(errorMsg);
        _sessions[activeIdx] = ses.copyWith(
          updatedAt: DateTime.now(),
          messages: msgs,
        );
      }
      _error = e.toString();
      return errorMsg;
    } finally {
      _isTyping = false;
      _isAnalyzingSky = false;
      notifyListeners();
      _repository.storageService.saveChatSessions(_sessions);
    }
  }

  Future<void> clearConversation() async {
    await startNewChat();
  }
}
