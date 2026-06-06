import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_models.dart';

// Đọc API Key từ arguments khi build: --dart-define=GEMINI_KEY=xxxx
const String _apiKey = String.fromEnvironment('GEMINI_KEY', defaultValue: '');

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

class GeminiService {
  ChatSession? _chatSession;

  /// Bắt đầu phiên chat mới với kịch bản (system instruction).
  void startChat(ChatScenario scenario) {
    if (_apiKey.isEmpty) {
      throw Exception('Không tìm thấy GEMINI_KEY. Hãy chạy app với --dart-define=GEMINI_KEY=...');
    }

    // Khởi tạo model Gemini 1.5 Flash
    final model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: _apiKey,
      systemInstruction: Content.system(scenario.systemInstruction),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );

    // Tạo session mới và bắt đầu với lịch sử rỗng.
    // Lịch sử thật sẽ được quản lý bởi Riverpod provider và đồng bộ sang session này
    // thông qua sendMessage.
    _chatSession = model.startChat(history: []);
  }

  /// Gửi tin nhắn lên Gemini và nhận về response đã parse.
  Future<ChatMessage> sendMessage(String text) async {
    if (_chatSession == null) {
      throw Exception('Vui lòng gọi startChat() trước.');
    }

    try {
      final response = await _chatSession!.sendMessage(Content.text(text));
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        throw Exception('Phản hồi rỗng từ Gemini.');
      }

      // Parse JSON từ Gemini
      final data = jsonDecode(responseText) as Map<String, dynamic>;

      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        isUser: false,
        text: data['hanzi'] as String? ?? '...',
        pinyin: data['pinyin'] as String?,
        vietnamese: data['vietnamese'] as String?,
        grammarNote: data['grammarNote'] as String?,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        isUser: false,
        text: 'Xin lỗi, tôi đang gặp lỗi kết nối hoặc xử lý.',
        grammarNote: 'Chi tiết lỗi: $e',
        timestamp: DateTime.now(),
      );
    }
  }
}
