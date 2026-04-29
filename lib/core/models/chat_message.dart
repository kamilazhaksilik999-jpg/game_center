class ChatMessage {
  final String id;
  final String fromUid;
  final String text;
  final DateTime createdAt;
  final bool read;

  ChatMessage({
    required this.id,
    required this.fromUid,
    required this.text,
    required this.createdAt,
    required this.read,
  });

  factory ChatMessage.fromMap(String id, Map<String, dynamic> data) {
    return ChatMessage(
      id: id,
      fromUid: data['fromUid'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      read: data['read'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'fromUid': fromUid,
    'text': text,
    'createdAt': createdAt,
    'read': read,
  };
}