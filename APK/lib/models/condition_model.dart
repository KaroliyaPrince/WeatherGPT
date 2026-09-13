class ConditionModel {
  final String text;
  final String icon;
  final int code;

  const ConditionModel({
    required this.text,
    required this.icon,
    required this.code,
  });

  factory ConditionModel.fromJson(dynamic json) {
    if (json == null) {
      return const ConditionModel(
        text: 'Clear',
        icon: 'sunny',
        code: 1000,
      );
    }

    if (json is String) {
      return ConditionModel(
        text: json,
        icon: 'cloud',
        code: 1000,
      );
    }

    if (json is Map) {
      return ConditionModel(
        text: json['text']?.toString() ?? json['description']?.toString() ?? 'Clear',
        icon: json['icon']?.toString() ?? 'sunny',
        code: (json['code'] as num?)?.toInt() ?? 1000,
      );
    }

    return const ConditionModel(text: 'Clear', icon: 'sunny', code: 1000);
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'icon': icon,
        'code': code,
      };
}
