class ChatMessage {
  final String id;
  final String role; // 'user' | 'assistant'
  final String content;
  final String? imagePreviewName;
  final String? imageBase64;
  final Map<String, dynamic>? weatherSnapshot;
  final Map<String, dynamic>? lensData;
  final dynamic explainWhy;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.imagePreviewName,
    this.imageBase64,
    this.weatherSnapshot,
    this.lensData,
    this.explainWhy,
    required this.timestamp,
  });

  bool get isUser => role == 'user';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      role: json['role']?.toString() ?? 'assistant',
      content: json['content']?.toString() ?? '',
      imagePreviewName: json['imagePreviewName']?.toString(),
      imageBase64: json['imageBase64']?.toString(),
      weatherSnapshot: json['weatherSnapshot'] as Map<String, dynamic>?,
      lensData: json['lensData'] as Map<String, dynamic>?,
      explainWhy: json['explainWhy'],
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'imagePreviewName': imagePreviewName,
      'imageBase64': imageBase64,
      'weatherSnapshot': weatherSnapshot,
      'lensData': lensData,
      'explainWhy': explainWhy,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
