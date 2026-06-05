/// Model đại diện cho một Flashcard trong hệ thống ôn tập SRS (Spaced Repetition System).
/// Dựa trên thuật toán SM-2 để tính toán lịch ôn tập tối ưu.
class FlashCard {
  /// ID của từ vựng liên kết với flashcard này (khóa ngoại đến Word.id)
  final String wordId;

  /// Hệ số dễ dàng — đánh giá mức độ dễ nhớ của thẻ (mặc định: 2.5).
  /// Giá trị tối thiểu là 1.3, không có giới hạn trên.
  final double easinessFactor;

  /// Khoảng thời gian (số ngày) đến lần ôn tập tiếp theo.
  /// Lần đầu = 1 ngày, lần hai = 6 ngày, sau đó tăng theo easinessFactor.
  final int interval;

  /// Số lần ôn tập thành công liên tiếp (không reset nếu sai).
  final int repetitions;

  /// Ngày ôn tập tiếp theo (so sánh với ngày hiện tại để xác định thẻ cần ôn).
  final DateTime nextReviewDate;

  /// Khởi tạo FlashCard với thông tin tiến trình học tập.
  const FlashCard({
    required this.wordId,
    this.easinessFactor = 2.5,
    this.interval = 0,
    this.repetitions = 0,
    required this.nextReviewDate,
  });

  /// Tạo FlashCard mới cho một từ, chưa từng được ôn tập.
  /// Lần ôn tập đầu tiên sẽ là ngay hôm nay.
  factory FlashCard.newCard({required String wordId}) {
    return FlashCard(
      wordId: wordId,
      easinessFactor: 2.5,
      interval: 0,
      repetitions: 0,
      nextReviewDate: DateTime.now(),
    );
  }

  /// Tạo FlashCard từ Map (dùng khi đọc từ Hive hoặc Firestore).
  factory FlashCard.fromMap(Map<String, dynamic> map) {
    return FlashCard(
      wordId: map['wordId'] as String,
      easinessFactor: (map['easinessFactor'] as num?)?.toDouble() ?? 2.5,
      interval: map['interval'] as int? ?? 0,
      repetitions: map['repetitions'] as int? ?? 0,
      nextReviewDate: DateTime.parse(map['nextReviewDate'] as String),
    );
  }

  /// Chuyển FlashCard thành Map để lưu vào Hive hoặc Firestore.
  Map<String, dynamic> toMap() {
    return {
      'wordId': wordId,
      'easinessFactor': easinessFactor,
      'interval': interval,
      'repetitions': repetitions,
      'nextReviewDate': nextReviewDate.toIso8601String(),
    };
  }

  /// Kiểm tra xem thẻ này có cần ôn tập hôm nay không.
  bool get isDueToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reviewDate = DateTime(
      nextReviewDate.year,
      nextReviewDate.month,
      nextReviewDate.day,
    );
    return !reviewDate.isAfter(today);
  }

  /// Tạo bản sao FlashCard với một số trường được cập nhật (sau khi ôn tập).
  FlashCard copyWith({
    String? wordId,
    double? easinessFactor,
    int? interval,
    int? repetitions,
    DateTime? nextReviewDate,
  }) {
    return FlashCard(
      wordId: wordId ?? this.wordId,
      easinessFactor: easinessFactor ?? this.easinessFactor,
      interval: interval ?? this.interval,
      repetitions: repetitions ?? this.repetitions,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
    );
  }

  @override
  String toString() {
    return 'FlashCard(wordId: $wordId, interval: $interval ngày, '
        'repetitions: $repetitions, nextReview: $nextReviewDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlashCard && other.wordId == wordId;
  }

  @override
  int get hashCode => wordId.hashCode;
}
