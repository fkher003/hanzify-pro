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

    // Khởi tạo model Gemini Pro (1.0)
    final model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: _apiKey,
    );

    // Truyền system instruction thông qua lịch sử (history)
    // vì gemini-pro không hỗ trợ tham số systemInstruction
    _chatSession = model.startChat(history: [
      Content.text('${scenario.systemInstruction}\n\nIMPORTANT: You must respond in ONLY valid JSON format.'),
      Content.model([TextPart('Đã hiểu. Tôi sẽ chỉ trả lời bằng JSON.')]),
    ]);
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

      // Parse JSON từ Gemini. Lọc bỏ markdown code block nếu có.
      String jsonStr = responseText;
      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
        if (jsonStr.endsWith('```')) {
          jsonStr = jsonStr.substring(0, jsonStr.length - 3);
        }
      } else if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.substring(3);
        if (jsonStr.endsWith('```')) {
          jsonStr = jsonStr.substring(0, jsonStr.length - 3);
        }
      }
      
      final data = jsonDecode(jsonStr.trim()) as Map<String, dynamic>;

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
