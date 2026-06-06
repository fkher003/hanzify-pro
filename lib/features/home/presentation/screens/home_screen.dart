import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_buttons.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../providers/home_provider.dart';

// ─── Màu sắc cục bộ cho biểu đồ ─────────────────────────────────────────────
const _neonBlue = Color(0xFF00D4FF);
const _orangeAccent = Color(0xFFFF6B35);
const _chartGray = Color(0xFF2A2A3E);

/// Màn hình Trang chủ Dashboard của HanzifyPro.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final displayName =
        user?.displayName ?? user?.email?.split('@').first ?? 'Học viên';
    final stats = ref.watch(homeStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Header / Greeting ─────────────────────────────────
                _buildHeader(displayName, stats.streakDays),

                const SizedBox(height: 24),

                // ── 2. Donut Chart (HSK4 Progress) ────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildDonutSection(stats),
                ),

                const SizedBox(height: 24),

                // ── 3. BarChart (Hoạt động 7 ngày) ───────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildBarChartSection(stats.weeklyActivity),
                ),

                const SizedBox(height: 24),

                // ── 4. Nút "Tiếp tục học" ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AppPrimaryButton(
                    label: 'Tiếp tục học  →',
                    onPressed: () => context.go('/flashcard'),
                  ),
                ),

                const SizedBox(height: 24),

                // ── 5. 2 Card thống kê dưới cùng ─────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildBottomStats(stats),
                ),

                // ── 6. Từ hôm nay ────────────────────────────────────────
                const SizedBox(height: 24),
                _buildTodayWordsSection(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 1. Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader(String displayName, int streakDays) {
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $displayName! 👋',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Hôm nay học gì nhỉ?',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          // Streak badge (đọc từ Hive thực)
          _StreakBadge(days: streakDays),
        ],
      ),
    );
  }

  // ─── 2. Donut Chart ────────────────────────────────────────────────────────

  Widget _buildDonutSection(HomeStats stats) {
    // Dữ liệu cố định HSK4: tổng 600 từ
    const totalHsk4 = 600;
    final learned = stats.totalWordsLearned.clamp(0, totalHsk4);
    final remaining = totalHsk4 - learned;
    final percent = ((learned / totalHsk4) * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề section
          const Row(
            children: [
              Icon(Icons.track_changes_rounded, size: 18, color: _neonBlue),
              SizedBox(width: 8),
              Text(
                'Mục tiêu HSK 4',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              // ── Donut Chart ──────────────────────────────────────────────
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 42,
                        startDegreeOffset: -90,
                        sections: [
                          // Phần đã học — xanh neon
                          PieChartSectionData(
                            value: learned.toDouble(),
                            color: _neonBlue,
                            radius: 18,
                            showTitle: false,
                          ),
                          // Phần chưa học — xám tối
                          PieChartSectionData(
                            value: remaining.toDouble(),
                            color: _chartGray,
                            radius: 16,
                            showTitle: false,
                          ),
                        ],
                      ),
                    ),
                    // Text giữa vòng donut
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$percent%',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Text(
                          'HSK 4',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // ── Chú thích bên phải ───────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegendItem(
                      color: _neonBlue,
                      label: 'Đã học',
                      value: '$learned từ',
                    ),
                    const SizedBox(height: 10),
                    _LegendItem(
                      color: _chartGray,
                      label: 'Còn lại',
                      value: '$remaining từ',
                    ),
                    const SizedBox(height: 10),
                    _LegendItem(
                      color: _orangeAccent,
                      label: 'Tổng mục tiêu',
                      value: '$totalHsk4 từ',
                    ),
                    const SizedBox(height: 14),
                    // Thanh progress phụ
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: learned / totalHsk4,
                        minHeight: 6,
                        backgroundColor: _chartGray,
                        valueColor: const AlwaysStoppedAnimation<Color>(_neonBlue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 3. Bar Chart ──────────────────────────────────────────────────────────

  Widget _buildBarChartSection(List<double> weeklyData) {
    final today = DateTime.now().weekday - 1; // 0=T2, 6=CN
    const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded, size: 18, color: _orangeAccent),
              SizedBox(width: 8),
              Text(
                'Hoạt động tuần này',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                // ── Tắt viền & lưới ────────────────────────────────────────
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),

                // ── Trục ───────────────────────────────────────────────────
                titlesData: FlTitlesData(
                  // Chỉ giữ nhãn dưới (T2-CN)
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        final isToday = idx == today;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[idx],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isToday
                                  ? _orangeAccent
                                  : AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                barGroups: List.generate(7, (i) {
                  final isToday = i == today;
                  final value = weeklyData[i];
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: value == 0 ? 0.5 : value, // Giá trị tối thiểu 0.5 để cột rỗng vẫn thấy
                        width: 16,
                        borderRadius: BorderRadius.circular(6),
                        // ── Gradient: hôm nay = cam, còn lại = xám/xanh ───
                        gradient: isToday
                            ? const LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Color(0xFFFF6B35), Color(0xFFFFAA5C)],
                              )
                            : LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: value > 0
                                    ? [
                                        const Color(0xFF1A56A4),
                                        const Color(0xFF2E7DE9),
                                      ]
                                    : [_chartGray, _chartGray],
                              ),
                      ),
                    ],
                  );
                }),

                maxY: (weeklyData.reduce((a, b) => a > b ? a : b) + 4).clamp(10, 20),
                barTouchData: BarTouchData(enabled: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 5. Bottom Stats Cards ─────────────────────────────────────────────────

  Widget _buildBottomStats(HomeStats stats) {
    final retentionPct = (stats.retentionRate * 100).round();

    return Row(
      children: [
        // Card 1: Từ vựng đã học
        Expanded(
          child: _StatsCard(
            icon: Icons.book_rounded,
            iconColor: _neonBlue,
            value: '${stats.totalWordsLearned}',
            label: 'Từ vựng đã học',
            subtitle: 'trong Hive offline',
          ),
        ),
        const SizedBox(width: 16),
        // Card 2: Tỷ lệ nhớ
        Expanded(
          child: _StatsCard(
            icon: Icons.psychology_rounded,
            iconColor: _orangeAccent,
            value: '$retentionPct%',
            label: 'Tỷ lệ nhớ',
            subtitle: 'đã thuộc ≥ 2 lần',
          ),
        ),
      ],
    );
  }

  // ─── 6. Today's Words ─────────────────────────────────────────────────────

  Widget _buildTodayWordsSection() {
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
                    '5 từ cần ôn tập',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(fontSize: 13, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: sampleWords.length,
            itemBuilder: (context, index) {
              final word = sampleWords[index];
              return _WordCard(
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
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

/// Badge streak ở góc phải header.
class _StreakBadge extends StatelessWidget {
  final int days;
  const _StreakBadge({required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, size: 18, color: Color(0xFFFF6B35)),
          const SizedBox(width: 4),
          Text(
            '$days ngày',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6B35),
            ),
          ),
        ],
      ),
    );
  }
}

/// Legend item cho Donut chart.
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _LegendItem({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

/// Card thống kê lớn dưới cùng.
class _StatsCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String subtitle;

  const _StatsCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Thẻ từ vựng trong horizontal scroll.
class _WordCard extends StatelessWidget {
  final String char;
  final String pinyin;
  final String meaning;

  const _WordCard({
    required this.char,
    required this.pinyin,
    required this.meaning,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            char,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pinyin,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            meaning,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
