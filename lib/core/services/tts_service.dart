import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Provider cung cấp instance duy nhất của TtsService.
final ttsServiceProvider = Provider<TtsService>((ref) {
  return TtsService();
});

/// Dịch vụ Text-to-Speech (TTS) chuyên dùng để phát âm tiếng Trung.
/// 
/// Đã được cấu hình tự động chọn ngôn ngữ zh-CN và tối ưu cho Hán ngữ.
class TtsService {
  final FlutterTts _flutterTts;
  bool _isInitialized = false;

  TtsService() : _flutterTts = FlutterTts() {
    _initTts();
  }

  /// Khởi tạo và cấu hình cài đặt mặc định cho TTS.
  Future<void> _initTts() async {
    // Đặt ngôn ngữ mặc định là tiếng Trung (Trung Quốc đại lục)
    await _flutterTts.setLanguage("zh-CN");
    
    // Đặt tốc độ đọc (0.0 đến 1.0) — tốc độ chậm rãi một chút để học viên nghe rõ
    await _flutterTts.setSpeechRate(0.45);
    
    // Đặt cao độ
    await _flutterTts.setPitch(1.0);
    
    // Bật chế độ âm thanh nền an toàn (không ngắt hẳn nhạc nếu có) trên iOS
    await _flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers
        ]);

    _isInitialized = true;
  }

  /// Phát âm thanh văn bản [text].
  /// Tự động dừng âm thanh đang phát trước khi phát mới.
  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    
    if (!_isInitialized) {
      await _initTts();
    }

    // Dừng âm cũ trước khi đọc âm mới
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  /// Dừng phát âm thanh hiện tại.
  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
