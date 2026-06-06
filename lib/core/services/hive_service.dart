import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/flashcard.dart';
import '../models/word.dart';

// ─── Hằng tên Box ────────────────────────────────────────────────────────────

/// Box lưu trữ danh sách từ vựng Word.
const String kBoxWords = 'words';

/// Box lưu trữ tiến trình Flashcard (SM-2 data).
const String kBoxFlashcards = 'flashcards';

/// Box lưu trữ cài đặt chung (streak, thống kê học tập).
const String kBoxSettings = 'settings';

/// Key lưu số ngày streak trong settings box.
const String kKeyStreak = 'streak';

/// Key lưu ngày học cuối cùng trong settings box.
const String kKeyLastStudyDate = 'last_study_date';

// ─── Provider ────────────────────────────────────────────────────────────────

/// Provider cung cấp HiveService đã khởi tạo cho toàn app.
final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

// ─── Service ─────────────────────────────────────────────────────────────────

/// Service quản lý toàn bộ thao tác với Hive local database.
///
/// Cách sử dụng:
/// 1. Gọi [HiveService.initialize()] trong `main()` TRƯỚC `runApp()`.
/// 2. Inject qua [hiveServiceProvider] trong các Riverpod provider/notifier.
class HiveService {
  // ─── Getters box (đã mở sẵn từ initialize) ─────────────────────────────

  Box<Word> get _wordBox => Hive.box<Word>(kBoxWords);
  Box<FlashCard> get _flashcardBox => Hive.box<FlashCard>(kBoxFlashcards);
  Box<dynamic> get _settingsBox => Hive.box<dynamic>(kBoxSettings);

  // ─── Khởi tạo (gọi trong main) ──────────────────────────────────────────

  /// Đăng ký TypeAdapter và mở tất cả các box.
  /// Phải được await trước khi gọi runApp().
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Đăng ký TypeAdapter — được sinh tự động bởi build_runner
    if (!Hive.isAdapterRegistered(WordAdapter().typeId)) {
      Hive.registerAdapter(WordAdapter());
    }
    if (!Hive.isAdapterRegistered(FlashCardAdapter().typeId)) {
      Hive.registerAdapter(FlashCardAdapter());
    }

    // Mở các box
    await Future.wait([
      Hive.openBox<Word>(kBoxWords),
      Hive.openBox<FlashCard>(kBoxFlashcards),
      Hive.openBox<dynamic>(kBoxSettings),
    ]);
  }

  // ─── Word Operations ─────────────────────────────────────────────────────

  /// Lấy tất cả từ vựng đã lưu trong box.
  List<Word> getAllWords() => _wordBox.values.toList();

  /// Lấy một Word theo ID.
  Word? getWordById(String id) {
    try {
      return _wordBox.values.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Lưu danh sách từ vựng vào box (dùng wordId làm key).
  Future<void> saveWords(List<Word> words) async {
    final map = {for (final w in words) w.id: w};
    await _wordBox.putAll(map);
  }

  /// Nạp dữ liệu mẫu (seed) nếu box đang rỗng.
  /// Dữ liệu mẫu này sẽ được thay bằng dữ liệu Firestore ở giai đoạn sau.
  Future<void> seedSampleWordsIfEmpty() async {
    if (_wordBox.isNotEmpty) return;

    final sampleWords = [
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
      Word(
        id: 'w4',
        hanzi: '练习',
        pinyin: 'liànxí',
        meaning: 'luyện tập',
        example: '每天练习很重要。',
        examplePinyin: 'Měitiān liànxí hěn zhòngyào.',
        hskLevel: 2,
      ),
      Word(
        id: 'w5',
        hanzi: '文化',
        pinyin: 'wénhuà',
        meaning: 'văn hoá',
        example: '中国文化很丰富。',
        examplePinyin: 'Zhōngguó wénhuà hěn fēngfù.',
        hskLevel: 2,
      ),
    ];

    await saveWords(sampleWords);

    // Tạo FlashCard tương ứng cho mỗi từ nếu chưa có
    for (final word in sampleWords) {
      if (!_flashcardBox.containsKey(word.id)) {
        await _flashcardBox.put(word.id, FlashCard.newCard(wordId: word.id));
      }
    }
  }

  // ─── FlashCard Operations ─────────────────────────────────────────────────

  /// Lấy tất cả FlashCard.
  List<FlashCard> getAllFlashCards() => _flashcardBox.values.toList();

  /// Lấy các FlashCard cần ôn tập hôm nay (isDueToday == true).
  List<FlashCard> getDueFlashCards() {
    return _flashcardBox.values.where((c) => c.isDueToday).toList();
  }

  /// Lưu (upsert) một FlashCard — dùng wordId làm key.
  Future<void> saveFlashCard(FlashCard card) async {
    await _flashcardBox.put(card.wordId, card);
  }

  // ─── Streak Operations ────────────────────────────────────────────────────

  /// Lấy số ngày học liên tiếp hiện tại.
  int getStreak() => _settingsBox.get(kKeyStreak, defaultValue: 0) as int;

  /// Cập nhật streak và ngày học cuối cùng.
  /// Tự động tính toán: nếu học liên tiếp ngày hôm trước → tăng streak,
  /// nếu gián đoạn → reset về 1.
  Future<void> updateStreak() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final lastStudyStr = _settingsBox.get(kKeyLastStudyDate) as String?;
    int currentStreak = getStreak();

    if (lastStudyStr != null) {
      final lastStudy = DateTime.parse(lastStudyStr);
      final lastDay = DateTime(lastStudy.year, lastStudy.month, lastStudy.day);
      final diff = today.difference(lastDay).inDays;

      if (diff == 0) {
        // Đã học hôm nay rồi — không tăng thêm
        return;
      } else if (diff == 1) {
        // Học liên tiếp ngày hôm trước → tăng streak
        currentStreak++;
      } else {
        // Gián đoạn → reset
        currentStreak = 1;
      }
    } else {
      // Lần đầu học
      currentStreak = 1;
    }

    await _settingsBox.put(kKeyStreak, currentStreak);
    await _settingsBox.put(kKeyLastStudyDate, today.toIso8601String());
  }
}
