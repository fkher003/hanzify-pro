import 'package:flutter/material.dart';

/// Đại diện cho một tin nhắn trong đoạn chat.
class ChatMessage {
  final String id;
  final bool isUser;
  
  /// Đối với User: Đây là văn bản do người dùng nhập.
  /// Đối với AI: Đây là nội dung chữ Hán (Hanzi).
  final String text;
  
  /// Phiên âm Pinyin (chỉ dành cho tin nhắn của AI).
  final String? pinyin;

  /// Nghĩa tiếng Việt nguyên văn câu AI vừa nói (chỉ dành cho tin nhắn của AI).
  final String? vietnamese;

  /// Ghi chú sửa lỗi ngữ pháp tiếng Việt (chỉ dành cho tin nhắn của AI).
  final String? grammarNote;
  
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.isUser,
    required this.text,
    this.pinyin,
    this.vietnamese,
    this.grammarNote,
    required this.timestamp,
  });
}

/// Đại diện cho một kịch bản chat.
class ChatScenario {
  final String id;
  final String title;
  final String pinyinTitle;
  final IconData icon;
  final Color color;
  final String systemInstruction;
  final String initialAiMessage;
  final String initialAiPinyin;

  const ChatScenario({
    required this.id,
    required this.title,
    required this.pinyinTitle,
    required this.icon,
    required this.color,
    required this.systemInstruction,
    required this.initialAiMessage,
    required this.initialAiPinyin,
  });
}

// ─── Dữ liệu Kịch bản Mẫu ─────────────────────────────────────────────────────

const String _baseInstruction = '''
Bạn là một người bản xứ Trung Quốc đang trò chuyện với một người học tiếng Trung.
Mục tiêu của bạn:
1. Đóng vai đúng với bối cảnh kịch bản được giao.
2. Trả lời một cách tự nhiên, dùng từ vựng phù hợp với người học (cỡ HSK 2-3).
3. LUÔN LUÔN kiểm tra lỗi ngữ pháp hoặc cách dùng từ của người dùng. Nếu có lỗi hoặc có cách diễn đạt tự nhiên hơn, hãy chỉ ra bằng tiếng Việt.

BẠN PHẢI LUÔN TRẢ VỀ DỮ LIỆU DƯỚI DẠNG JSON với cấu trúc sau:
{
  "hanzi": "Câu phản hồi của bạn bằng chữ Hán",
  "pinyin": "Phiên âm pinyin của câu phản hồi",
  "vietnamese": "Nghĩa tiếng Việt nguyên văn của câu bạn vừa nói",
  "grammarNote": "Chỉ ra lỗi và sửa lỗi ngữ pháp bằng tiếng Việt (nếu câu của người học hoàn hảo, hãy khen ngợi ngắn gọn bằng tiếng Việt)"
}
''';

final List<ChatScenario> sampleScenarios = [
  const ChatScenario(
    id: 's1',
    title: 'Giao tiếp hằng ngày',
    pinyinTitle: 'Rìcháng jiāojì',
    icon: Icons.coffee_rounded,
    color: Color(0xFFE28A3D),
    systemInstruction: '$_baseInstruction\nBối cảnh: Bạn là một người bạn mới quen tại quán cà phê. Hãy bắt chuyện và hỏi han về cuộc sống hằng ngày, sở thích của người dùng.',
    initialAiMessage: '你好！很高兴认识你。你平时喜欢做什么？',
    initialAiPinyin: 'Nǐ hǎo! Hěn gāoxìng rènshí nǐ. Nǐ píngshí xǐhuān zuò shénme?',
  ),
  const ChatScenario(
    id: 's2',
    title: 'Mua sắm',
    pinyinTitle: 'Gòuwù',
    icon: Icons.shopping_bag_rounded,
    color: Color(0xFF4FA071),
    systemInstruction: '$_baseInstruction\nBối cảnh: Bạn là nhân viên bán hàng tại một cửa hàng quần áo. Hãy hỏi xem người dùng cần tìm mua gì và tư vấn cho họ.',
    initialAiMessage: '欢迎光临！请问您需要买什么衣服？',
    initialAiPinyin: 'Huānyíng guānglín! Qǐngwèn nín xūyào mǎi shénme yīfú?',
  ),
  const ChatScenario(
    id: 's3',
    title: 'Phỏng vấn xin việc',
    pinyinTitle: 'Qiúzhuó miànshì',
    icon: Icons.work_rounded,
    color: Color(0xFF5D5FEF),
    systemInstruction: '$_baseInstruction\nBối cảnh: Bạn là một nhà tuyển dụng (HR) đang phỏng vấn ứng viên bằng tiếng Trung. Hãy hỏi các câu hỏi phỏng vấn cơ bản một cách chuyên nghiệp.',
    initialAiMessage: '你好，请先自我介绍一下。',
    initialAiPinyin: 'Nǐ hǎo, qǐng xiān zìwǒ jièshào yīxià.',
  ),
];
