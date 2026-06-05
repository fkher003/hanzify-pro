import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/word.dart';

// ─── Routing constant ─────────────────────────────────────────────────────────
/// Path của màn hình luyện viết — push lên trên MainScaffold, không có Bottom Nav.
const String kRouteStroke = '/stroke';

// ─── Stroke Data Model ────────────────────────────────────────────────────────

/// ChangeNotifier lưu trữ danh sách các nét vẽ.
///
/// **Chiến lược hiệu suất:**
/// Dùng ChangeNotifier thay vì Riverpod/setState vì notifyListeners()
/// kích hoạt trực tiếp CustomPainter.paint() mà KHÔNG rebuild widget tree.
/// Mỗi onPanUpdate có thể gọi 60+ lần/giây → đây là lựa chọn duy nhất không bị lag.
class StrokeNotifier extends ChangeNotifier {
  /// Danh sách các nét vẽ — mỗi nét là một `List<Offset>` liên tiếp.
  final List<List<Offset>> _strokes = [];

  /// Nét đang được vẽ hiện tại (chưa hoàn thành).
  List<Offset> _currentStroke = [];

  List<List<Offset>> get strokes => _strokes;
  List<Offset> get currentStroke => _currentStroke;

  /// Bắt đầu một nét vẽ mới tại vị trí [point].
  void startStroke(Offset point) {
    _currentStroke = [point];
    notifyListeners();
  }

  /// Thêm điểm vào nét đang vẽ.
  void addPoint(Offset point) {
    _currentStroke.add(point);
    notifyListeners();
  }

  /// Kết thúc nét vẽ, lưu vào danh sách tổng.
  void endStroke() {
    if (_currentStroke.isNotEmpty) {
      _strokes.add(List.from(_currentStroke));
    }
    _currentStroke = [];
    notifyListeners();
  }

  /// Xóa toàn bộ nét vẽ hiện tại.
  void clear() {
    _strokes.clear();
    _currentStroke = [];
    notifyListeners();
  }

  /// Xóa nét cuối cùng (undo).
  void undoLastStroke() {
    if (_strokes.isNotEmpty) {
      _strokes.removeLast();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _strokes.clear();
    super.dispose();
  }
}

// ─── CustomPainter ────────────────────────────────────────────────────────────

/// Painter vẽ lưới nền, chữ Hán mẫu mờ và các nét tay người dùng.
class _StrokeCanvasPainter extends CustomPainter {
  final StrokeNotifier notifier;
  final String guideCharacter;

  _StrokeCanvasPainter({
    required this.notifier,
    required this.guideCharacter,
  }) : super(repaint: notifier); // Tự động repaint khi notifier thay đổi

  @override
  void paint(Canvas canvas, Size size) {
    // ── 1. Vẽ Grid ─────────────────────────────────────────────────────────
    _drawGrid(canvas, size);

    // ── 2. Vẽ chữ Hán mẫu mờ (guide) ──────────────────────────────────────
    _drawGuideCharacter(canvas, size);

    // ── 3. Vẽ các nét đã hoàn thành ────────────────────────────────────────
    final strokePaint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in notifier.strokes) {
      _drawStroke(canvas, stroke, strokePaint);
    }

    // ── 4. Vẽ nét đang được vẽ (current) ────────────────────────────────────
    if (notifier.currentStroke.isNotEmpty) {
      final currentPaint = Paint()
        ..color = AppColors.primary
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      _drawStroke(canvas, notifier.currentStroke, currentPaint);
    }
  }

  /// Vẽ lưới 4×4 mờ bên trong canvas — giống ô luyện viết chữ Hán truyền thống.
  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF2D2D3D)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Viền ngoài
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      gridPaint,
    );

    // Đường chéo mờ
    final dashedPaint = Paint()
      ..color = const Color(0xFF2D2D3D).withValues(alpha: 0.5)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Đường ngang giữa
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      gridPaint,
    );

    // Đường dọc giữa
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      gridPaint,
    );

    // Đường chéo góc trên-trái → dưới-phải
    canvas.drawLine(
      const Offset(0, 0),
      Offset(size.width, size.height),
      dashedPaint,
    );

    // Đường chéo góc trên-phải → dưới-trái
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(0, size.height),
      dashedPaint,
    );
  }

  /// Vẽ chữ Hán mờ làm chữ mẫu để tô theo.
  void _drawGuideCharacter(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: guideCharacter,
        style: TextStyle(
          fontSize: size.width * 0.72, // Chiếm 72% chiều rộng canvas
          fontWeight: FontWeight.bold,
          color: const Color(0xFF2D2D3D).withValues(alpha: 0.45),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);

    // Căn giữa chữ mẫu trong canvas
    final offset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );
    textPainter.paint(canvas, offset);
  }

  /// Vẽ một nét liên tiếp qua các điểm Offset.
  void _drawStroke(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      // Chấm đơn — vẽ hình tròn nhỏ
      canvas.drawCircle(points.first, paint.strokeWidth / 2, paint);
      return;
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    // Dùng đường cong quadratic để nét vẽ mượt hơn đường thẳng
    for (int i = 1; i < points.length - 1; i++) {
      final midX = (points[i].dx + points[i + 1].dx) / 2;
      final midY = (points[i].dy + points[i + 1].dy) / 2;
      path.quadraticBezierTo(
        points[i].dx, points[i].dy,
        midX, midY,
      );
    }
    path.lineTo(points.last.dx, points.last.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_StrokeCanvasPainter oldDelegate) {
    // Luôn false vì việc repaint được kích hoạt tự động bởi StrokeNotifier (ChangeNotifier).
    // CustomPainter lắng nghe qua super(repaint: notifier).
    return false;
  }
}

// ─── Stroke Screen ────────────────────────────────────────────────────────────

/// Màn hình Canvas luyện viết chữ Hán.
/// Không có Bottom Navigation Bar — chiếm toàn màn hình để tối ưu không gian vẽ.
///
/// Cách điều hướng tới màn hình này:
/// ```dart
/// context.push(kRouteStroke, extra: currentWord);
/// ```
class StrokeScreen extends StatefulWidget {
  /// Từ vựng hiện tại cần luyện viết (được truyền từ FlashcardScreen qua extra).
  final Word word;

  const StrokeScreen({super.key, required this.word});

  @override
  State<StrokeScreen> createState() => _StrokeScreenState();
}

class _StrokeScreenState extends State<StrokeScreen> {
  /// Notifier quản lý toàn bộ dữ liệu nét vẽ.
  /// Khai báo ở đây để đảm bảo vòng đời được quản lý đúng (dispose khi unmount).
  late final StrokeNotifier _strokeNotifier;

  /// Index chữ hiện tại trong hanzi (nếu từ có nhiều ký tự)
  int _currentCharIndex = 0;

  @override
  void initState() {
    super.initState();
    _strokeNotifier = StrokeNotifier();
  }

  @override
  void dispose() {
    _strokeNotifier.dispose();
    super.dispose();
  }

  /// Chữ đang được luyện viết
  String get _currentChar {
    final chars = widget.word.hanzi.characters.toList();
    if (chars.isEmpty) return widget.word.hanzi;
    return chars[_currentCharIndex.clamp(0, chars.length - 1)];
  }

  /// Chuyển sang ký tự tiếp theo
  void _nextChar() {
    final charCount = widget.word.hanzi.characters.length;
    if (_currentCharIndex < charCount - 1) {
      setState(() {
        _currentCharIndex++;
        _strokeNotifier.clear();
      });
    }
  }

  /// Quay lại ký tự trước
  void _prevChar() {
    if (_currentCharIndex > 0) {
      setState(() {
        _currentCharIndex--;
        _strokeNotifier.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chars = widget.word.hanzi.characters.toList();
    final hasMultipleChars = chars.length > 1;

    return Scaffold(
      backgroundColor: AppColors.background,

      // ── AppBar với thông tin từ ─────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.word.hanzi,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              widget.word.meaning,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          // Nút Undo
          IconButton(
            icon: const Icon(Icons.undo_rounded, color: AppColors.textSecondary),
            onPressed: _strokeNotifier.undoLastStroke,
            tooltip: 'Hoàn tác nét vừa vẽ',
          ),
          // Nút Clear
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            onPressed: _strokeNotifier.clear,
            tooltip: 'Xóa toàn bộ',
          ),
        ],
      ),

      body: Column(
        children: [
          // ── Thông tin Pinyin + chỉ số ký tự ─────────────────────────────
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Pinyin
                Text(
                  widget.word.pinyin,
                  style: const TextStyle(
                    fontSize: 20,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // Badge đang vẽ ký tự thứ mấy (chỉ show khi từ nhiều chữ)
                if (hasMultipleChars)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Chữ ${_currentCharIndex + 1}/${chars.length}: $_currentChar',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Canvas luyện viết ─────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1, // Canvas vuông
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF141420),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    // RepaintBoundary isolates canvas repaints từ widget tree bên ngoài
                    child: RepaintBoundary(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanStart: (details) {
                            _strokeNotifier.startStroke(details.localPosition);
                          },
                          onPanUpdate: (details) {
                            _strokeNotifier.addPoint(details.localPosition);
                          },
                          onPanEnd: (_) {
                            _strokeNotifier.endStroke();
                          },
                          child: CustomPaint(
                            painter: _StrokeCanvasPainter(
                              notifier: _strokeNotifier,
                              guideCharacter: _currentChar,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Điều hướng ký tự (chỉ hiện khi từ nhiều chữ) ────────────────
          if (hasMultipleChars)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
                      label: const Text('Chữ trước', style: TextStyle(color: AppColors.textSecondary)),
                      onPressed: _currentCharIndex > 0 ? _prevChar : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                      label: const Text('Chữ tiếp', style: TextStyle(color: Colors.white)),
                      onPressed: _currentCharIndex < chars.length - 1 ? _nextChar : null,
                    ),
                  ),
                ],
              ),
            ),

          // ── Câu ví dụ ─────────────────────────────────────────────────────
          if (widget.word.example.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ví dụ:',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.word.example,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.word.examplePinyin,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
