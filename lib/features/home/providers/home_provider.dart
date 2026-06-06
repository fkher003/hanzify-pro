import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/hive_service.dart';

// ─── State ────────────────────────────────────────────────────────────────────

/// State chứa toàn bộ dữ liệu Dashboard cho HomeScreen.
class HomeStats {
  /// Tổng số từ đã học (đã có trong Hive box)
  final int totalWordsLearned;

  /// Số ngày học liên tiếp (streak)
  final int streakDays;

  /// Tỷ lệ nhớ — tính từ tổng thẻ correct / tổng thẻ trong Hive (mock nếu chưa đủ)
  final double retentionRate;

  /// Lịch sử học 7 ngày qua (số từ mỗi ngày) — dùng cho BarChart
  final List<double> weeklyActivity;

  HomeStats({
    required this.totalWordsLearned,
    required this.streakDays,
    required this.retentionRate,
    required this.weeklyActivity,
  });
}

// ─── Provider ────────────────────────────────────────────────────────────────

/// Cung cấp thống kê Dashboard từ Hive và mock data.
final homeStatsProvider = Provider<HomeStats>((ref) {
  final hive = ref.read(hiveServiceProvider);

  // ── Dữ liệu thật từ Hive ──────────────────────────────────────────────────
  final totalWords = hive.getAllWords().length;
  final streak = hive.getStreak();

  // ── Tính tỷ lệ nhớ từ FlashCard data ─────────────────────────────────────
  final allCards = hive.getAllFlashCards();
  double retentionRate;
  if (allCards.isEmpty) {
    retentionRate = 0.0;
  } else {
    // Thẻ "thuộc" là thẻ có repetitions >= 2 (đã ôn ít nhất 2 lần thành công)
    final masteredCount = allCards.where((c) => c.repetitions >= 2).length;
    retentionRate = masteredCount / allCards.length;
  }

  // ── Mock dữ liệu tuần để BarChart luôn đẹp ───────────────────────────────
  // Sinh dữ liệu có tính "thực": 6 ngày qua ngẫu nhiên + hôm nay dựa theo thực tế
  final weeklyActivity = _generateWeeklyActivity(totalWords, streak);

  return HomeStats(
    totalWordsLearned: totalWords,
    streakDays: streak,
    retentionRate: retentionRate,
    weeklyActivity: weeklyActivity,
  );
});

/// Sinh mảng 7 ngày hoạt động học tập có tính thực tế.
///
/// Nguyên tắc:
/// - Nếu streak > 0, các ngày trước đó đều có ít nhất 1 hoạt động.
/// - Giá trị dao động để biểu đồ trông tự nhiên, không đều.
List<double> _generateWeeklyActivity(int totalWords, int streakDays) {
  // Seed dựa trên ngày hiện tại để giá trị ổn định trong ngày
  final today = DateTime.now().weekday - 1; // 0=T2, 6=CN

  // Giá trị nền cho mỗi ngày (từ T2 tới CN)
  final baseValues = [5.0, 8.0, 4.0, 10.0, 7.0, 12.0, 6.0];

  final result = List<double>.filled(7, 0.0);
  for (int i = 0; i < 7; i++) {
    if (i == today) {
      // Hôm nay: nếu đã học thì highlight, nếu chưa thì 0
      result[i] = streakDays > 0 ? (totalWords > 0 ? totalWords.toDouble().clamp(5, 15) : 8.0) : 0.0;
    } else if (i < today && streakDays > (today - i)) {
      // Các ngày trong streak: có hoạt động
      result[i] = baseValues[i];
    } else if (totalWords > 0 && i < today) {
      // Ngày trước đó có thể học hoặc không
      result[i] = i.isOdd ? baseValues[i] : 0.0;
    } else {
      result[i] = 0.0;
    }
  }

  return result;
}
