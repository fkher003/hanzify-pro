import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/flashcard.dart';
import '../../../core/models/word.dart';
import '../../../core/services/hive_service.dart';
import '../../../core/utils/srs_algorithm.dart';

// ─── Models State ─────────────────────────────────────────────────────────

/// Cặp Word + FlashCard để truyền xuống UI.
class FlashcardItem {
  final Word word;
  final FlashCard card;

  FlashcardItem({required this.word, required this.card});
}

/// State của màn hình Flashcard.
class FlashcardState {
  final List<FlashcardItem> deck;
  final int currentIndex;

  FlashcardState({
    required this.deck,
    this.currentIndex = 0,
  });

  /// Kiểm tra đã học hết chưa.
  bool get isFinished => currentIndex >= deck.length;

  /// Thẻ hiện tại.
  FlashcardItem? get currentItem => isFinished ? null : deck[currentIndex];

  FlashcardState copyWith({
    List<FlashcardItem>? deck,
    int? currentIndex,
  }) {
    return FlashcardState(
      deck: deck ?? this.deck,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────

/// Quản lý vòng đời Flashcard với Hive persistence + thuật toán SM-2.
///
/// Luồng dữ liệu:
/// 1. `build()`: đọc FlashCard từ Hive, join với Word data → tạo deck hôm nay
/// 2. `answerCard()`: gọi SM-2, lưu kết quả xuống Hive, chuyển thẻ tiếp theo
/// 3. `resetDeck()`: làm mới lại danh sách để ôn tập lại
class FlashcardNotifier extends Notifier<FlashcardState> {
  /// Lấy HiveService từ Riverpod container.
  HiveService get _hive => ref.read(hiveServiceProvider);

  @override
  FlashcardState build() {
    // Đọc dữ liệu từ Hive và xây dựng deck
    return _buildDeckFromHive();
  }

  // ─── Đọc từ Hive ─────────────────────────────────────────────────────────

  /// Xây dựng danh sách thẻ cần học hôm nay từ Hive.
  FlashcardState _buildDeckFromHive() {
    final allCards = _hive.getDueFlashCards();
    final allWords = _hive.getAllWords();

    // Tạo map word để lookup O(1)
    final wordMap = {for (final w in allWords) w.id: w};

    // Join FlashCard với Word tương ứng
    final deck = allCards
        .where((card) => wordMap.containsKey(card.wordId))
        .map((card) => FlashcardItem(word: wordMap[card.wordId]!, card: card))
        .toList();

    // Nếu không có thẻ nào due today (ví dụ: mở app lần đầu chưa seed),
    // lấy tất cả thẻ để không bị màn hình trắng
    if (deck.isEmpty) {
      final allDeck = _hive.getAllFlashCards()
          .where((card) => wordMap.containsKey(card.wordId))
          .map((card) => FlashcardItem(word: wordMap[card.wordId]!, card: card))
          .toList();
      return FlashcardState(deck: allDeck);
    }

    return FlashcardState(deck: deck);
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  /// Xử lý khi người dùng nhấn Đúng hoặc Sai.
  ///
  /// 1. Tính qualityScore từ isCorrect (Đúng → 4, Sai → 1)
  /// 2. Gọi SrsAlgorithm.processReview() để cập nhật SM-2
  /// 3. Lưu FlashCard đã cập nhật xuống Hive
  /// 4. Cập nhật streak
  /// 5. Chuyển sang thẻ tiếp theo
  Future<void> answerCard(bool isCorrect) async {
    if (state.isFinished) return;

    final currentItem = state.currentItem!;

    // Quy đổi nút bấm ra qualityScore (theo thang SM-2: 0–5)
    final score = isCorrect ? 4 : 1;

    // Cập nhật SM-2
    final updatedCard = SrsAlgorithm.processReview(
      card: currentItem.card,
      qualityScore: score,
    );

    // ── Persist xuống Hive ──────────────────────────────────────────────────
    await _hive.saveFlashCard(updatedCard);

    // Cập nhật streak mỗi khi có hoạt động học tập
    await _hive.updateStreak();

    // ── Cập nhật state in-memory ────────────────────────────────────────────
    final newDeck = List<FlashcardItem>.from(state.deck);
    newDeck[state.currentIndex] = FlashcardItem(
      word: currentItem.word,
      card: updatedCard,
    );

    state = state.copyWith(
      deck: newDeck,
      currentIndex: state.currentIndex + 1,
    );
  }

  /// Reset để ôn tập lại từ đầu.
  /// Đọc lại từ Hive để lấy state mới nhất (vd: sau khi nhiều thẻ đã update).
  void resetDeck() {
    state = _buildDeckFromHive();
  }
}

/// Provider phơi bày FlashcardNotifier ra toàn app.
final flashcardProvider =
    NotifierProvider<FlashcardNotifier, FlashcardState>(() {
  return FlashcardNotifier();
});
