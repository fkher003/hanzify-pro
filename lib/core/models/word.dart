import 'package:hive_flutter/hive_flutter.dart';

part 'word.g.dart';

/// Model đại diện cho một từ vựng Hán-Việt trong từ điển.
/// Chứa đầy đủ thông tin ngôn ngữ cần thiết để học và ôn tập.
/// Sử dụng Hive TypeAdapter (typeId: 0) để lưu trữ offline.
@HiveType(typeId: 0)
class Word extends HiveObject {
  /// ID duy nhất của từ (UUID hoặc Firestore document ID)
  @HiveField(0)
  final String id;

  /// Chữ Hán (ví dụ: 你好, 中文, 学习)
  @HiveField(1)
  final String hanzi;

  /// Phiên âm Pinyin với dấu thanh (ví dụ: nǐ hǎo, zhōng wén)
  @HiveField(2)
  final String pinyin;

  /// Nghĩa tiếng Việt của từ
  @HiveField(3)
  final String meaning;

  /// Câu ví dụ sử dụng từ trong ngữ cảnh thực tế
  @HiveField(4)
  final String example;

  /// Phiên âm Pinyin của câu ví dụ
  @HiveField(5)
  final String examplePinyin;

  /// Cấp độ HSK (1-6, hoặc 0 nếu chưa phân loại)
  @HiveField(6)
  final int hskLevel;

  /// Khởi tạo một đối tượng Word với đầy đủ thông tin từ vựng.
  Word({
    required this.id,
    required this.hanzi,
    required this.pinyin,
    required this.meaning,
    required this.example,
    required this.examplePinyin,
    required this.hskLevel,
  });

  /// Tạo đối tượng Word từ Map (dùng khi đọc từ Firestore hoặc JSON).
  factory Word.fromMap(Map<String, dynamic> map) {
    return Word(
      id: map['id'] as String,
      hanzi: map['hanzi'] as String,
      pinyin: map['pinyin'] as String,
      meaning: map['meaning'] as String,
      example: map['example'] as String? ?? '',
      examplePinyin: map['examplePinyin'] as String? ?? '',
      hskLevel: map['hskLevel'] as int? ?? 0,
    );
  }

  /// Chuyển đối tượng Word thành Map để lưu vào Firestore hoặc Hive.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hanzi': hanzi,
      'pinyin': pinyin,
      'meaning': meaning,
      'example': example,
      'examplePinyin': examplePinyin,
      'hskLevel': hskLevel,
    };
  }

  /// Tạo bản sao Word với một số trường được cập nhật.
  Word copyWith({
    String? id,
    String? hanzi,
    String? pinyin,
    String? meaning,
    String? example,
    String? examplePinyin,
    int? hskLevel,
  }) {
    return Word(
      id: id ?? this.id,
      hanzi: hanzi ?? this.hanzi,
      pinyin: pinyin ?? this.pinyin,
      meaning: meaning ?? this.meaning,
      example: example ?? this.example,
      examplePinyin: examplePinyin ?? this.examplePinyin,
      hskLevel: hskLevel ?? this.hskLevel,
    );
  }

  @override
  String toString() {
    return 'Word(id: $id, hanzi: $hanzi, pinyin: $pinyin, hskLevel: HSK$hskLevel)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Word && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
