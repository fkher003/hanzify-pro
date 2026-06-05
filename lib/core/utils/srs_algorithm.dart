import '../models/flashcard.dart';

/// Triển khai thuật toán SM-2 (SuperMemo 2) cho Spaced Repetition System (SRS).
///
/// Thuật toán SM-2 tính toán lịch ôn tập tối ưu dựa trên chất lượng
/// trả lời của người dùng. Điểm chất lượng từ 0-5:
/// - 5: Trả lời hoàn hảo, không do dự
/// - 4: Trả lời đúng, có chút do dự nhỏ
/// - 3: Trả lời đúng nhưng khó khăn
/// - 2: Trả lời sai nhưng thấy đáp án quen thuộc
/// - 1: Trả lời sai, nhớ ra khi thấy đáp án
/// - 0: Hoàn toàn không nhớ
class SrsAlgorithm {
  /// Điểm chất lượng tối thiểu để được coi là "trả lời đúng".
  /// Điểm dưới ngưỡng này sẽ reset repetitions về 0.
  static const int kMinPassingScore = 3;

  /// Hệ số dễ dàng tối thiểu — không được giảm xuống dưới 1.3.
  static const double kMinEasinessFactor = 1.3;

  /// Hệ số dễ dàng mặc định cho thẻ mới.
  static const double kDefaultEasinessFactor = 2.5;

  /// Tính toán và cập nhật trạng thái FlashCard sau một lần ôn tập.
  ///
  /// Tham số:
  /// - [card]: Thẻ flashcard cần cập nhật
  /// - [qualityScore]: Điểm chất lượng trả lời (0-5)
  ///
  /// Trả về: FlashCard mới với thông tin SRS đã được cập nhật.
  static FlashCard processReview({
    required FlashCard card,
    required int qualityScore,
  }) {
    // Kiểm tra đầu vào hợp lệ
    assert(qualityScore >= 0 && qualityScore <= 5,
        'Điểm chất lượng phải trong khoảng 0-5');

    // Tính hệ số dễ dàng mới theo công thức SM-2
    final newEasinessFactor = _calculateNewEasinessFactor(
      currentFactor: card.easinessFactor,
      qualityScore: qualityScore,
    );

    // Tính interval và repetitions mới
    final int newRepetitions;
    final int newInterval;

    if (qualityScore < kMinPassingScore) {
      // Trả lời sai — reset về đầu
      newRepetitions = 0;
      newInterval = 1;
    } else {
      // Trả lời đúng — tăng interval theo SM-2
      newRepetitions = card.repetitions + 1;
      newInterval = _calculateNextInterval(
        repetitions: newRepetitions,
        currentInterval: card.interval,
        easinessFactor: newEasinessFactor,
      );
    }

    // Tính ngày ôn tập tiếp theo
    final nextReviewDate = DateTime.now().add(Duration(days: newInterval));

    return card.copyWith(
      easinessFactor: newEasinessFactor,
      interval: newInterval,
      repetitions: newRepetitions,
      nextReviewDate: nextReviewDate,
    );
  }

  /// Tính hệ số dễ dàng mới theo công thức SM-2:
  /// EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
  static double _calculateNewEasinessFactor({
    required double currentFactor,
    required int qualityScore,
  }) {
    final q = qualityScore.toDouble();
    final newFactor =
        currentFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));

    // Đảm bảo không giảm xuống dưới mức tối thiểu
    return newFactor < kMinEasinessFactor ? kMinEasinessFactor : newFactor;
  }

  /// Tính interval (số ngày) cho lần ôn tập tiếp theo.
  ///
  /// - Lần 1 (repetitions = 1): 1 ngày
  /// - Lần 2 (repetitions = 2): 6 ngày
  /// - Lần 3+: interval trước × EasinessFactor
  static int _calculateNextInterval({
    required int repetitions,
    required int currentInterval,
    required double easinessFactor,
  }) {
    switch (repetitions) {
      case 1:
        return 1;
      case 2:
        return 6;
      default:
        // Làm tròn lên để tránh interval = 0
        return (currentInterval * easinessFactor).ceil();
    }
  }

  /// Ước tính mức độ thành thạo của thẻ (0.0 - 1.0).
  ///
  /// Dựa vào easinessFactor và repetitions để đưa ra một con số trực quan
  /// thể hiện mức độ người dùng đã nắm vững từ này.
  static double calculateMasteryLevel(FlashCard card) {
    // Tối đa 10 lần repetitions được coi là "thành thạo hoàn toàn"
    const maxRepetitions = 10;
    final repetitionScore = (card.repetitions / maxRepetitions).clamp(0.0, 1.0);

    // Normalize easinessFactor từ [1.3, 3.5] về [0.0, 1.0]
    const minEF = kMinEasinessFactor;
    const maxEF = 3.5;
    final efScore =
        ((card.easinessFactor - minEF) / (maxEF - minEF)).clamp(0.0, 1.0);

    // Kết hợp hai chỉ số (repetitions quan trọng hơn)
    return (repetitionScore * 0.7 + efScore * 0.3);
  }
}
