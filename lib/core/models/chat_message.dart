/// Enum định nghĩa vai trò của người gửi tin nhắn trong cuộc hội thoại.
enum MessageRole {
  /// Tin nhắn do người dùng gửi
  user,

  /// Tin nhắn do AI (Gemini) trả lời
  model,

  /// Tin nhắn hệ thống (system prompt, thông báo nội bộ)
  system,
}

/// Model đại diện cho một tin nhắn trong cuộc trò chuyện với AI Gemini.
/// Hỗ trợ lưu trữ nội dung hội thoại và ghi chú ngữ pháp kèm theo.
class ChatMessage {
  /// ID duy nhất của tin nhắn (UUID)
  final String id;

  /// Nội dung văn bản của tin nhắn
  final String content;

  /// Vai trò người gửi: user (người dùng) hoặc model (AI Gemini)
  final MessageRole role;

  /// Thời điểm tin nhắn được tạo
  final DateTime timestamp;

  /// Ghi chú ngữ pháp do AI sinh ra (có thể null nếu không có phân tích ngữ pháp).
  /// Ví dụ: giải thích cấu trúc câu, lỗi ngữ pháp, gợi ý cải thiện.
  final String? grammarNote;

  /// Khởi tạo một tin nhắn trong cuộc hội thoại.
  const ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.grammarNote,
  });

  /// Tạo tin nhắn từ người dùng với ID và timestamp tự động.
  factory ChatMessage.fromUser({
    required String id,
    required String content,
  }) {
    return ChatMessage(
      id: id,
      content: content,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );
  }

  /// Tạo tin nhắn phản hồi từ AI Gemini với ID và timestamp tự động.
  factory ChatMessage.fromModel({
    required String id,
    required String content,
    String? grammarNote,
  }) {
    return ChatMessage(
      id: id,
      content: content,
      role: MessageRole.model,
      timestamp: DateTime.now(),
      grammarNote: grammarNote,
    );
  }

  /// Tạo ChatMessage từ Map (dùng khi đọc từ Firestore hoặc Hive).
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      content: map['content'] as String,
      role: MessageRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => MessageRole.user,
      ),
      timestamp: DateTime.parse(map['timestamp'] as String),
      grammarNote: map['grammarNote'] as String?,
    );
  }

  /// Chuyển ChatMessage thành Map để lưu vào Firestore hoặc Hive.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'role': role.name,
      'timestamp': timestamp.toIso8601String(),
      'grammarNote': grammarNote,
    };
  }

  /// Kiểm tra xem tin nhắn có phải từ người dùng không.
  bool get isFromUser => role == MessageRole.user;

  /// Kiểm tra xem tin nhắn có phải từ AI Gemini không.
  bool get isFromModel => role == MessageRole.model;

  /// Kiểm tra xem tin nhắn có kèm ghi chú ngữ pháp không.
  bool get hasGrammarNote => grammarNote != null && grammarNote!.isNotEmpty;

  /// Tạo bản sao ChatMessage với một số trường được cập nhật.
  ChatMessage copyWith({
    String? id,
    String? content,
    MessageRole? role,
    DateTime? timestamp,
    String? grammarNote,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      grammarNote: grammarNote ?? this.grammarNote,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, role: ${role.name}, '
        'content: ${content.substring(0, content.length > 50 ? 50 : content.length)}...)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
