import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../features/stroke/presentation/stroke_screen.dart';
import '../../providers/flashcard_provider.dart';

/// Màn hình Flashcard với hiệu ứng lật thẻ 3D và tích hợp thuật toán SM-2.
class FlashcardScreen extends ConsumerStatefulWidget {
  const FlashcardScreen({super.key});

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _animation;

  /// Trạng thái lưu cục bộ để quản lý chiều lật thẻ (true = mặt trước)
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  /// Lật thẻ. Gọi TTS nếu lật ra mặt sau.
  void _toggleCard(String wordHanzi) {
    if (!mounted) return;
    setState(() {
      _isFront = !_isFront;
      if (_isFront) {
        _flipController.reverse();
      } else {
        _flipController.forward();
        // Phát âm chữ Hán khi mở đáp án
        ref.read(ttsServiceProvider).speak(wordHanzi);
      }
    });
  }

  /// Xử lý khi chọn Đúng / Sai
  Future<void> _answerCard(bool isCorrect) async {
    // 1. Cập nhật state + lưu Hive qua Riverpod (async)
    await ref.read(flashcardProvider.notifier).answerCard(isCorrect);
    
    // 2. Reset thẻ về mặt trước (lập tức, không có animation)
    if (!mounted) return;
    setState(() {
      _isFront = true;
      _flipController.value = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final flashcardState = ref.watch(flashcardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Ôn tập từ vựng',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: flashcardState.isFinished
          ? _buildFinishedScreen()
          : _buildFlashcardView(flashcardState),
    );
  }

  /// Giao diện khi học xong tất cả các thẻ
  Widget _buildFinishedScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.done_all, size: 80, color: AppColors.primary),
          const SizedBox(height: 24),
          const Text(
            'Hoàn thành xuất sắc!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bạn đã ôn tập xong tất cả thẻ cho hôm nay.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              ref.read(flashcardProvider.notifier).resetDeck();
            },
            child: const Text(
              'Ôn lại từ đầu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          )
        ],
      ),
    );
  }

  /// Khung hiển thị Flashcard (Animation 3D lật thẻ)
  Widget _buildFlashcardView(FlashcardState state) {
    final currentItem = state.currentItem!;
    
    return Column(
      children: [
        // Thanh tiến trình trên cùng
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: state.deck.isEmpty 
                      ? 0 
                      : state.currentIndex / state.deck.length,
                    minHeight: 8,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${state.currentIndex}/${state.deck.length}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Thẻ Flashcard chính giữa
        Expanded(
          child: Center(
            child: GestureDetector(
              onTap: () => _toggleCard(currentItem.word.hanzi),
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  final angle = _animation.value * pi;
                  final isBackVisible = angle >= (pi / 2);

                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // perspective
                      ..rotateY(angle),
                    alignment: Alignment.center,
                    child: isBackVisible
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(pi),
                            child: _buildBackCard(currentItem),
                          )
                        : _buildFrontCard(currentItem),
                  );
                },
              ),
            ),
          ),
        ),

        // Khu vực nút điều khiển (Chỉ hiện khi đang ở mặt sau)
        AnimatedOpacity(
          opacity: _isFront ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E1E2E),
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isFront ? null : () => _answerCard(false),
                    child: const Text(
                      'Sai',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isFront ? null : () => _answerCard(true),
                    child: const Text(
                      'Đúng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Giao diện MẶT TRƯỚC (chỉ có chữ Hán)
  Widget _buildFrontCard(FlashcardItem item) {
    return Container(
      width: 320,
      height: 400,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Text(
          item.word.hanzi,
          style: const TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  /// Giao diện MẶT SAU (Pinyin, Nghĩa, Câu ví dụ)
  Widget _buildBackCard(FlashcardItem item) {
    return Container(
      width: 320,
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Chữ Hán
          Text(
            item.word.hanzi,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          
          // Row chứa Pinyin và nút Loa
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.word.pinyin,
                style: const TextStyle(
                  fontSize: 24,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
                onPressed: () {
                  ref.read(ttsServiceProvider).speak(item.word.hanzi);
                },
              ),
              // Nút luyện viết chữ — điều hướng sang StrokeScreen
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                onPressed: () {
                  context.push(kRouteStroke, extra: item.word);
                },
                tooltip: 'Luyện viết',
              ),
            ],
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: AppColors.border),
          ),
          
          // Nghĩa tiếng Việt
          Text(
            item.word.meaning,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Ví dụ (nếu có)
          if (item.word.example.isNotEmpty) ...[
            Text(
              item.word.example,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              item.word.examplePinyin,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
