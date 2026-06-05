import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/flashcard.dart';
import '../../../core/models/word.dart';
import '../../../core/utils/srs_algorithm.dart';

// ─── Models State ─────────────────────────────────────────────────────────

/// Data class dùng để truyền cặp Word - Flashcard xuống UI
class FlashcardItem {
  final Word word;
  final FlashCard card;

  FlashcardItem({required this.word, required this.card});
}

/// State của màn hình Flashcard
class FlashcardState {
  final List<FlashcardItem> deck;
  final int currentIndex;

  FlashcardState({
    required this.deck,
    this.currentIndex = 0,
  });

  /// Kiểm tra xem đã học hết danh sách chưa
  bool get isFinished => currentIndex >= deck.length;

  /// Lấy thẻ hiện tại
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

// ─── Mock Data ────────────────────────────────────────────────────────────

final _mockWords = [
  Word(
    id: 'w1',
    hanzi: '学习',
    pinyin: 'xuéxí',
    meaning: 'học tập, nghiên cứu',
    example: '我在学习中文。',
    examplePinyin: 'Wǒ zài xuéxí zhōngwén.',
    hskLevel: 1,
  ),
  Word(
    id: 'w2',
    hanzi: '语言',
    pinyin: 'yǔyán',
    meaning: 'ngôn ngữ',
    example: '语言是沟通的工具。',
    examplePinyin: 'Yǔyán shì gōutōng de gōngjù.',
    hskLevel: 2,
  ),
  Word(
    id: 'w3',
    hanzi: '汉字',
    pinyin: 'hànzì',
    meaning: 'chữ Hán',
    example: '写汉字很难。',
    examplePinyin: 'Xiě hànzì hěn nán.',
    hskLevel: 1,
  ),
];

final _mockCards = _mockWords.map((w) => FlashCard.newCard(wordId: w.id)).toList();

final _initialDeck = List.generate(
  _mockWords.length,
  (i) => FlashcardItem(word: _mockWords[i], card: _mockCards[i]),
);

// ─── Notifier ─────────────────────────────────────────────────────────────

/// Quản lý trạng thái danh sách Flashcard và xử lý thuật toán SM-2.
class FlashcardNotifier extends Notifier<FlashcardState> {
  @override
  FlashcardState build() {
    // Khởi tạo state với dữ liệu mock
    return FlashcardState(deck: _initialDeck);
  }

  /// Gọi khi người dùng nhấn nút Đúng hoặc Sai.
  /// [isCorrect]: true nếu nhấn "Đúng", false nếu nhấn "Sai".
  void answerCard(bool isCorrect) {
    if (state.isFinished) return;

    final currentItem = state.currentItem!;
    
    // Quy đổi nút bấm ra chất lượng (qualityScore) cho thuật toán SM-2
    // Đúng -> điểm 4 (tốt), Sai -> điểm 1 (nhớ ra khi thấy đáp án)
    final score = isCorrect ? 4 : 1;

    // Cập nhật flashcard thông qua SM-2
    final updatedCard = SrsAlgorithm.processReview(
      card: currentItem.card,
      qualityScore: score,
    );

    // Tạo item mới với card đã cập nhật
    final updatedItem = FlashcardItem(
      word: currentItem.word,
      card: updatedCard,
    );

    // Cập nhật deck
    final newDeck = List<FlashcardItem>.from(state.deck);
    newDeck[state.currentIndex] = updatedItem;

    // TODO: Ở bước tiếp theo (khi có Backend/DB), gọi hàm lưu updatedCard vào Hive hoặc Firestore.

    // Chuyển sang thẻ tiếp theo
    state = state.copyWith(
      deck: newDeck,
      currentIndex: state.currentIndex + 1,
    );
  }

  /// Reset lại tiến trình bài học (dùng khi xem xong màn hình hoàn thành)
  void resetDeck() {
    state = state.copyWith(currentIndex: 0);
  }
}

/// Provider phơi bày FlashcardNotifier ra toàn app.
final flashcardProvider = NotifierProvider<FlashcardNotifier, FlashcardState>(() {
  return FlashcardNotifier();
});
