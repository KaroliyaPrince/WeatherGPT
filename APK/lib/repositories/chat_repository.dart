import '../models/chat_message.dart';
import '../models/location_model.dart';
import '../services/storage_service.dart';
import '../services/weather_api_service.dart';

class ChatRepository {
  final WeatherApiService apiService;
  final StorageService storageService;

  ChatRepository({
    required this.apiService,
    required this.storageService,
  });

  String? get conversationId => storageService.conversationId;

  Future<void> setConversationId(String id) async {
    await storageService.setConversationId(id);
  }

  Future<void> clearConversation() async {
    await storageService.clearConversationId();
  }

  /// Send user message to WeatherGPT
  Future<ChatMessage> sendMessage({
    required String question,
    WeatherLocation? location,
    String persona = 'general',
    String language = 'en',
  }) async {
    final res = await apiService.askAssistant(
      question: question,
      latitude: location?.latitude,
      longitude: location?.longitude,
      locationName: location?.name,
      persona: persona,
      language: language,
      conversationId: storageService.conversationId,
    );

    // Update conversation context id
    if (res['conversationId'] != null) {
      await storageService.setConversationId(res['conversationId'].toString());
    } else if (res['conversationContext']?['id'] != null) {
      await storageService.setConversationId(res['conversationContext']['id'].toString());
    }

    final answerText = res['answer']?.toString() ??
        res['error']?.toString() ??
        'Sorry, could not retrieve weather forecast right now.';

    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'assistant',
      content: answerText,
      weatherSnapshot: res['weather'] as Map<String, dynamic>?,
      explainWhy: res['explainWhy'],
      timestamp: DateTime.now(),
    );
  }

  /// Send image to Weather Lens AI
  Future<ChatMessage> sendWeatherLensImage({
    required String imageBase64,
    required String question,
    WeatherLocation? location,
    String language = 'gu',
  }) async {
    final res = await apiService.analyzeWeatherLens(
      imageBase64: imageBase64,
      question: question,
      latitude: location?.latitude,
      longitude: location?.longitude,
      locationName: location?.name,
      language: language,
    );

    final weatherLensMap = (res['weatherLens'] as Map<String, dynamic>?) ?? res;
    final answer = weatherLensMap['answer']?.toString() ??
        res['answer']?.toString() ??
        'Based on cloud formation analysis, rain risk is moderate.';

    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'assistant',
      content: answer,
      lensData: weatherLensMap,
      timestamp: DateTime.now(),
    );
  }
}
