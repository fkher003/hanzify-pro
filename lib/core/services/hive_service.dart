import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

  /// Nạp dữ liệu từ file JSON offline nếu box đang rỗng.
  Future<void> seedDataIfEmpty() async {
    if (_wordBox.isNotEmpty) return;

    try {
      // Đọc file JSON từ assets
      final jsonString = await rootBundle.loadString('assets/hsk4_vocab.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);

      // Parse JSON sang List<Word>
      final List<Word> wordsToSeed = jsonList.map((json) => Word.fromMap(json as Map<String, dynamic>)).toList();

      // Lưu vào Hive box
      await saveWords(wordsToSeed);

      // Tạo FlashCard tương ứng cho mỗi từ (chưa từng học)
      for (final word in wordsToSeed) {
        if (!_flashcardBox.containsKey(word.id)) {
          await _flashcardBox.put(word.id, FlashCard.newCard(wordId: word.id));
        }
      }
    } catch (e) {
      debugPrint('Lỗi khi seed dữ liệu: $e');
    }
  }

  // ─── Reset / Clear Operations ────────────────────────────────────────────

  /// Xóa toàn bộ tiến trình học tập (FlashCard và Word) rồi nạp lại từ JSON.
  /// Dùng khi người dùng muốn bắt đầu từ đầu.
  Future<void> clearAllProgressAndReseed() async {
    // Xóa toàn bộ dữ liệu trong 3 box
    await _flashcardBox.clear();
    await _wordBox.clear();
    await _settingsBox.clear();

    // Nạp lại 100 từ vựng mặc định từ file JSON
    await seedDataIfEmpty();
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
