import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/chat_models.dart';
import '../../../../core/services/tts_service.dart';
import '../../providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final ChatScenario scenario;

  const ChatScreen({super.key, required this.scenario});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;

    _textController.clear();
    // Gửi message thông qua provider family
    ref.read(chatProvider(widget.scenario).notifier).sendMessage(text);

    // Cuộn xuống cuối
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Theo dõi state của provider theo kịch bản hiện tại
    final chatState = ref.watch(chatProvider(widget.scenario));

    // Lắng nghe sự thay đổi độ dài tin nhắn để tự động cuộn xuống
    ref.listen<ChatState>(chatProvider(widget.scenario), (previous, next) {
      if (previous == null || next.messages.length > previous.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text(
              widget.scenario.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const Text(
              'AI Gia Sư',
              style: TextStyle(fontSize: 12, color: AppColors.primary),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Danh sách tin nhắn ────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: chatState.messages.length + (chatState.isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                // Hiển thị Typing Indicator ở cuối cùng nếu đang gõ
                if (index == chatState.messages.length) {
                  return _buildTypingIndicator();
                }

                final msg = chatState.messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // ── Thanh nhập liệu ───────────────────────────────────────────────
          _buildInputBar(),
        ],
      ),
    );
  }

  /// Xây dựng bong bóng tin nhắn (User hoặc AI)
  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            // Avatar AI
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.surface,
              child: Icon(Icons.smart_toy_rounded, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: isUser
                ? _buildUserBubble(message)
                : _buildAIBubble(message),
          ),
          
          if (isUser) ...[
            const SizedBox(width: 8),
            // Avatar User
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person_rounded, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  /// Bong bóng tin nhắn của User (Xanh)
  Widget _buildUserBubble(ChatMessage message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: Text(
        message.text,
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }

  /// Bong bóng tin nhắn của AI (Phức tạp hơn: có Pinyin và Grammar Note)
  Widget _buildAIBubble(ChatMessage message) {
    final hasGrammarNote = message.grammarNote != null && message.grammarNote!.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(20),
        ),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phần 1: Chữ Hán và Pinyin
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.pinyin != null)
                  Text(
                    message.pinyin!,
                    style: const TextStyle(fontSize: 14, color: AppColors.primary),
                  ),
                const SizedBox(height: 4),
                Text(
                  message.text,
                  style: const TextStyle(fontSize: 18, color: AppColors.textPrimary),
                ),
                if (message.vietnamese != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    message.vietnamese!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFAAAAAA), // Xám nhạt — tương phản tốt trên nền dark
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Nút phát âm
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: IconButton(
              icon: const Icon(Icons.volume_up_rounded, size: 20, color: AppColors.textSecondary),
              onPressed: () {
                ref.read(ttsServiceProvider).speak(message.text);
              },
            ),
          ),

          // Phần 2: Ghi chú ngữ pháp (Chỉ hiển thị nếu có)
          if (hasGrammarNote) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF232336), // Nền xám tối/tím nhạt
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(20),
                ),
                border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_outline_rounded, size: 16, color: Color(0xFFFFD700)),
                      SizedBox(width: 6),
                      Text(
                        'Nhận xét ngữ pháp',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message.grammarNote!,
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  /// Indicator nhấp nháy khi AI đang gõ
  Widget _buildTypingIndicator() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 24, left: 40),
      child: Row(
        children: [
          Text(
            'AI đang gõ...',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  /// Thanh Input dưới cùng
  Widget _buildInputBar() {
    final chatState = ref.watch(chatProvider(widget.scenario));

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.mic_none_rounded, color: AppColors.textSecondary),
            onPressed: () {
              // TODO: Tích hợp Speech-to-Text
            },
          ),
          IconButton(
            icon: const Icon(Icons.translate_rounded, color: AppColors.textSecondary),
            onPressed: () {
              // TODO: Dịch thuật nháp
            },
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF141420),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: AppColors.textPrimary),
                maxLines: 4,
                minLines: 1,
                decoration: const InputDecoration(
                  hintText: 'Nhập tin nhắn (tiếng Trung)...',
                  hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: chatState.isTyping ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
