import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/chat_models.dart';
import '../../../../core/services/gemini_service.dart';

/// State của màn hình Chat.
class ChatState {
  final List<ChatMessage> messages;
  final bool isTyping;

  ChatState({
    required this.messages,
    this.isTyping = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

/// Provider truyền scenario hiện tại vào (sẽ được override bằng ProviderScope hoặc truyền param).
/// Để đơn giản, ta sẽ dùng `.family` để truyền Scenario vào Notifier.
final chatProvider = NotifierProvider.family<ChatNotifier, ChatState, ChatScenario>(() {
  return ChatNotifier();
});

/// Quản lý danh sách tin nhắn và tương tác với Gemini.
class ChatNotifier extends FamilyNotifier<ChatState, ChatScenario> {
  GeminiService get _gemini => ref.read(geminiServiceProvider);

  @override
  ChatState build(ChatScenario arg) {
    // 1. Lấy Scenario từ argument
    final scenario = arg;

    // 2. Khởi tạo session với kịch bản tương ứng
    _gemini.startChat(scenario);

    // 3. Đưa tin nhắn chào mừng (initial message) vào State
    final initialMsg = ChatMessage(
      id: 'init_${DateTime.now().millisecondsSinceEpoch}',
      isUser: false,
      text: scenario.initialAiMessage,
      pinyin: scenario.initialAiPinyin,
      timestamp: DateTime.now(),
    );

    return ChatState(messages: [initialMsg]);
  }

  /// Gửi tin nhắn lên AI
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Thêm tin nhắn của User vào danh sách
    final userMsg = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      isUser: true,
      text: text,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isTyping: true, // Hiển thị AI đang gõ
    );

    // 2. Gọi Gemini API
    final aiResponse = await _gemini.sendMessage(text);

    // 3. Thêm phản hồi của AI vào danh sách, tắt isTyping
    state = state.copyWith(
      messages: [...state.messages, aiResponse],
      isTyping: false,
    );
  }
}
