import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_buttons.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

/// Màn hình Đăng nhập chính của HanzifyPro.
/// Thiết kế theo Stitch spec: nền tối, logo Hán ngữ, form email/mật khẩu,
/// và liên kết sang màn hình đăng ký.
///
/// Sử dụng ConsumerStatefulWidget để kết hợp với Riverpod.
/// TUYỆT ĐỐI KHÔNG dùng setState — state được quản lý bởi [authProvider].
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  // Controller cho các ô nhập liệu
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Form key để validate
  final _formKey = GlobalKey<FormState>();

  // Trạng thái "nhớ mật khẩu" — dùng ValueNotifier thay vì setState
  final _rememberMe = ValueNotifier<bool>(false);

  // Animation controller cho hiệu ứng fade-in
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Khởi tạo animation fade-in khi màn hình mở
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _rememberMe.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ─── Xử lý đăng nhập ────────────────────────────────────────────────────

  /// Kiểm tra form và gọi auth provider để thực hiện đăng nhập
  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Xoá bàn phím trước khi xử lý
    FocusScope.of(context).unfocus();

    await ref.read(authProvider.notifier).signInWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Lắng nghe auth state và điều hướng khi đăng nhập thành công
    ref.listen<AsyncValue<AuthState>>(authProvider, (previous, next) {
      final data = next.valueOrNull;
      if (data?.status == AuthStatus.authenticated) {
        // Điều hướng sang Home khi đăng nhập thành công
        context.go('/home');
      }
    });

    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;
    final errorMsg = authState.valueOrNull?.errorMessage;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // ── Logo Hán tự ────────────────────────────────────────
                  _buildLogoSection(),

                  const SizedBox(height: 48),

                  // ── Thông báo lỗi (nếu có) ────────────────────────────
                  if (errorMsg != null) ...[
                    _buildErrorBanner(errorMsg),
                    const SizedBox(height: 16),
                  ],

                  // ── Ô Email ────────────────────────────────────────────
                  AppTextField(
                    label: 'Email',
                    hint: 'example@email.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    onChanged: (_) {
                      // Xoá lỗi khi người dùng bắt đầu gõ lại
                      if (errorMsg != null) {
                        ref.read(authProvider.notifier).clearError();
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  // ── Ô Mật khẩu ────────────────────────────────────────
                  AppTextField(
                    label: 'Mật khẩu',
                    hint: '••••••••',
                    controller: _passwordController,
                    obscureText: true,
                    showPasswordToggle: true,
                    prefixIcon: Icons.lock_outline,
                  ),

                  const SizedBox(height: 16),

                  // ── Nhớ mật khẩu + Quên mật khẩu ─────────────────────
                  _buildRememberAndForgot(),

                  const SizedBox(height: 28),

                  // ── Nút Đăng nhập ─────────────────────────────────────
                  AppPrimaryButton(
                    label: 'Đăng nhập',
                    onPressed: isLoading ? null : _handleLogin,
                    isLoading: isLoading,
                  ),

                  const SizedBox(height: 24),

                  // ── Divider ────────────────────────────────────────────
                  _buildDivider(),

                  const SizedBox(height: 24),

                  // ── Nút Google ─────────────────────────────────────────
                  AppOutlineButton(
                    label: 'Tiếp tục với Google',
                    onPressed: isLoading ? null : () {
                      // TODO: Thêm Google Sign-In ở sprint sau
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Google Sign-In sẽ sớm ra mắt!'),
                          backgroundColor: AppColors.surface,
                        ),
                      );
                    },
                    leadingIcon: const _GoogleIcon(),
                  ),

                  const SizedBox(height: 40),

                  // ── Liên kết đăng ký ───────────────────────────────────
                  _buildRegisterLink(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Widgets con ────────────────────────────────────────────────────────

  /// Logo Hán tự với tiêu đề ứng dụng
  Widget _buildLogoSection() {
    return Column(
      children: [
        // Chữ Hán lớn màu đỏ truyền thống
        const Text(
          '汉字',
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: AppColors.chineseRed,
            height: 1,
          ),
        ),
        const SizedBox(height: 12),
        // Tên ứng dụng
        const Text(
          'HanzifyPro',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        // Slogan
        const Text(
          'Học Hán ngữ cùng AI',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Banner thông báo lỗi (màu đỏ nhạt, có icon)
  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// Hàng "Nhớ mật khẩu" (checkbox) + "Quên mật khẩu?" (link)
  Widget _buildRememberAndForgot() {
    return ValueListenableBuilder<bool>(
      valueListenable: _rememberMe,
      builder: (_, value, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Checkbox nhớ mật khẩu
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: value,
                    onChanged: (v) => _rememberMe.value = v ?? false,
                    activeColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Nhớ mật khẩu',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            // Quên mật khẩu
            GestureDetector(
              onTap: () {
                // TODO: Thêm chức năng reset mật khẩu
              },
              child: const Text(
                'Quên mật khẩu?',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Đường kẻ phân cách "— Hoặc tiếp tục với —"
  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: AppColors.border, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Hoặc tiếp tục với',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: AppColors.border, thickness: 1),
        ),
      ],
    );
  }

  /// Liên kết "Chưa có tài khoản? Đăng ký ngay"
  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Chưa có tài khoản? ',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () => context.push('/register'),
          child: const Text(
            'Đăng ký ngay',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Google Icon (SVG-style Painter) ─────────────────────────────────────

/// Icon Google được vẽ thủ công bằng Canvas để tránh thêm dependency ảnh
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _GoogleIconPainter(),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Vẽ hình tròn nền trắng
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius, bgPaint);

    // Vẽ chữ "G" màu Google blue (đơn giản hoá)
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
