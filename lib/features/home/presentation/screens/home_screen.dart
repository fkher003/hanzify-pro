import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_buttons.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Màn hình Trang chủ chính của HanzifyPro.
/// Thiết kế theo Stitch spec:
/// - Header với lời chào + gradient
/// - Streak card (ngày học liên tiếp)
/// - Tiến độ HSK4
/// - Nút "Tiếp tục học"
/// - Quick stats row
/// - Từ hôm nay (horizontal scroll)
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lấy thông tin user từ provider
    final user = ref.watch(currentUserProvider);
    final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'Học viên';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar ẩn (không cần title, header tự thiết kế) ────────
          const SliverToBoxAdapter(child: SizedBox.shrink()),

          // ── Toàn bộ nội dung trong một Sliver ────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Header / Greeting ─────────────────────────────────
                _buildHeader(displayName),

                // ── 2. Streak Card ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: _buildStreakCard(),
                ),

                const SizedBox(height: 16),

                // ── 3. HSK4 Progress Card ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildProgressCard(),
                ),

                const SizedBox(height: 20),

                // ── 4. Nút "Tiếp tục học" ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AppPrimaryButton(
                    label: 'Tiếp tục học  →',
                    onPressed: () {
                      // TODO: Điều hướng đến Flashcard tab ở sprint sau
                      context.go('/flashcard');
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // ── 5. Quick Stats Row ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildQuickStats(),
                ),

                const SizedBox(height: 24),

                // ── 6. Từ hôm nay ────────────────────────────────────────
                _buildTodayWordsSection(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 1. Header Greeting ───────────────────────────────────────────────────

  /// Header với gradient nền và lời chào theo giờ trong ngày.
  Widget _buildHeader(String displayName) {
    // Lấy lời chào phù hợp theo giờ
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Chào buổi sáng'
        : hour < 18
            ? 'Chào buổi chiều'
            : 'Chào buổi tối';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F0F0F), Color(0xFF1A1A2E)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dòng chào + emoji
          Row(
            children: [
              Expanded(
                child: Text(
                  '$greeting, $displayName! 👋',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              // Logo Hán tự nhỏ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.chineseRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '汉字',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.chineseRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Sub-text
          const Text(
            'Hôm nay học gì nhỉ?',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 2. Streak Card ───────────────────────────────────────────────────────

  /// Thẻ đếm chuỗi ngày học liên tiếp.
  /// Gradient xanh đậm, icon lửa, số ngày to.
  Widget _buildStreakCard() {
    // TODO: Lấy streak thực từ Firestore/Hive ở sprint sau
    const streakDays = 7;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A56A4), Color(0xFF0D47A1)],
        ),
        borderRadius: BorderRadius.circular(16),
        // Viền glow nhẹ
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cột thông tin streak
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label trên
                const Text(
                  'Chuỗi học liên tiếp',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xCCFFFFFF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                // Số ngày to
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      '$streakDays',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'ngày',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xCCFFFFFF),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Lời động viên
                const Text(
                  'Tuyệt vời! Giữ vững nhé 💪',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xB3FFFFFF),
                  ),
                ),
              ],
            ),
          ),

          // Icon lửa bên phải
          Stack(
            alignment: Alignment.center,
            children: [
              // Vòng tròn mờ trang trí
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              const Icon(
                Icons.local_fire_department,
                size: 48,
                color: Color(0xFFFF6B35),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 3. HSK4 Progress Card ────────────────────────────────────────────────

  /// Thẻ tiến độ HSK4 với thanh progress bar.
  Widget _buildProgressCard() {
    // TODO: Lấy tiến độ thực từ Firestore ở sprint sau
    const totalWords = 600;
    const learnedWords = 320;
    const progress = learnedWords / totalWords; // 0.533...

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: tiêu đề + badge phần trăm
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Tiêu đề
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tiến độ HSK 4',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$learnedWords / $totalWords từ đã học',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              // Badge phần trăm
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '53%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Thanh progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),

          const SizedBox(height: 12),

          // Phân chia level phụ (HSK 4 breakdown)
          Row(
            children: [
              _buildMiniStat('Đã thuộc', '256', AppColors.primary),
              const SizedBox(width: 16),
              _buildMiniStat('Cần ôn', '64', const Color(0xFFFF6B35)),
              const SizedBox(width: 16),
              _buildMiniStat('Chưa học', '280', AppColors.textSecondary),
            ],
          ),
        ],
      ),
    );
  }

  /// Mini stat item bên trong card tiến độ
  Widget _buildMiniStat(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$value $label',
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }

  // ─── 5. Quick Stats Row ───────────────────────────────────────────────────

  /// Hàng 3 thẻ thống kê nhanh: Từ đã học, Độ chính xác, Thời gian hôm nay.
  Widget _buildQuickStats() {
    return Row(
      children: [
        _buildStatCard(
          icon: '📚',
          value: '120',
          label: 'Từ đã học',
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: '⭐',
          value: '85%',
          label: 'Chính xác',
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: '⏱️',
          value: '24p',
          label: 'Hôm nay',
        ),
      ],
    );
  }

  /// Thẻ thống kê nhỏ
  Widget _buildStatCard({
    required String icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── 6. Today's Words Section ─────────────────────────────────────────────

  /// Section "Từ hôm nay" với horizontal scroll cards.
  Widget _buildTodayWordsSection() {
    // Dữ liệu mẫu — sẽ thay bằng dữ liệu từ Hive/Firestore ở sprint sau
    final sampleWords = [
      {'char': '学习', 'pinyin': 'xuéxí', 'meaning': 'học tập'},
      {'char': '语言', 'pinyin': 'yǔyán', 'meaning': 'ngôn ngữ'},
      {'char': '汉字', 'pinyin': 'hànzì', 'meaning': 'chữ Hán'},
      {'char': '练习', 'pinyin': 'liànxí', 'meaning': 'luyện tập'},
      {'char': '文化', 'pinyin': 'wénhuà', 'meaning': 'văn hoá'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header của section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Từ hôm nay',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '5 từ mới cần ôn',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              // Nút "Xem tất cả"
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Horizontal scrolling word cards
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: sampleWords.length,
            itemBuilder: (context, index) {
              final word = sampleWords[index];
              return _buildWordCard(
                char: word['char']!,
                pinyin: word['pinyin']!,
                meaning: word['meaning']!,
              );
            },
          ),
        ),
      ],
    );
  }

  /// Thẻ từ vựng trong horizontal scroll
  Widget _buildWordCard({
    required String char,
    required String pinyin,
    required String meaning,
  }) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Chữ Hán
          Text(
            char,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          // Pinyin
          Text(
            pinyin,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          // Nghĩa tiếng Việt
          Text(
            meaning,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
