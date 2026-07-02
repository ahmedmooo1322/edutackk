enum ChatRole { user, assistant, system }

class ChatMessage {
  ChatMessage({
    this.id,
    required this.role,
    required this.text,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final int? id;
  final ChatRole role;
  final String text;
  final DateTime createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final rawRole = '${json['role'] ?? 'system'}';
    final role = rawRole == 'user'
        ? ChatRole.user
        : rawRole == 'assistant'
            ? ChatRole.assistant
            : ChatRole.system;
    return ChatMessage(
      id: int.tryParse('${json['id'] ?? ''}'),
      role: role,
      text: '${json['message'] ?? json['message_text'] ?? ''}',
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
    );
  }
}
