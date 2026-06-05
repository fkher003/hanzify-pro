import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_buttons.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

/// Màn hình Đăng ký tài khoản mới của HanzifyPro.
/// Theo Stitch spec: cùng theme tối, form gồm tên/email/mật khẩu/xác nhận mật khẩu.
///
/// TUYỆT ĐỐI KHÔNG dùng setState — state qua [authProvider].
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  // Các controller cho form đăng ký
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Form key để validate
  final _formKey = GlobalKey<FormState>();

  // Animation fade-in
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ─── Xử lý đăng ký ──────────────────────────────────────────────────────

  /// Validate form và gọi auth provider để thực hiện đăng ký
  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Kiểm tra mật khẩu khớp nhau
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu xác nhận không khớp!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    await ref.read(authProvider.notifier).registerWithEmail(
          displayName: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Điều hướng về Home khi đăng ký thành công
    ref.listen<AsyncValue<AuthState>>(authProvider, (previous, next) {
      final data = next.valueOrNull;
      if (data?.status == AuthStatus.authenticated) {
        context.go('/home');
      }
    });

    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;
    final errorMsg = authState.valueOrNull?.errorMessage;

    return Scaffold(
      backgroundColor: AppColors.background,
      // Nút back về Login
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Tiêu đề ───────────────────────────────────────────
                  _buildHeader(),

                  const SizedBox(height: 36),

                  // ── Thông báo lỗi ─────────────────────────────────────
                  if (errorMsg != null) ...[
                    _buildErrorBanner(errorMsg),
                    const SizedBox(height: 16),
                  ],

                  // ── Ô tên hiển thị ────────────────────────────────────
                  AppTextField(
                    label: 'Tên hiển thị',
                    hint: 'Nguyễn Văn A',
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    prefixIcon: Icons.person_outline,
                    onChanged: (_) {
                      if (errorMsg != null) {
                        ref.read(authProvider.notifier).clearError();
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  // ── Ô Email ────────────────────────────────────────────
                  AppTextField(
                    label: 'Email',
                    hint: 'example@email.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    onChanged: (_) {
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

                  const SizedBox(height: 20),

                  // ── Ô Xác nhận mật khẩu ───────────────────────────────
                  AppTextField(
                    label: 'Xác nhận mật khẩu',
                    hint: '••••••••',
                    controller: _confirmPasswordController,
                    obscureText: true,
                    showPasswordToggle: true,
                    prefixIcon: Icons.lock_outline,
                  ),

                  const SizedBox(height: 32),

                  // ── Nút Đăng ký ───────────────────────────────────────
                  AppPrimaryButton(
                    label: 'Đăng ký',
                    onPressed: isLoading ? null : _handleRegister,
                    isLoading: isLoading,
                  ),

                  const SizedBox(height: 32),

                  // ── Liên kết Đăng nhập ────────────────────────────────
                  _buildLoginLink(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Widgets con ────────────────────────────────────────────────────────

  /// Tiêu đề màn hình đăng ký (nhỏ hơn màn hình đăng nhập)
  Widget _buildHeader() {
    return Column(
      children: [
        // Chữ Hán nhỏ hơn
        const Text(
          '汉字',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: AppColors.chineseRed,
            height: 1,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Tạo tài khoản mới',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Bắt đầu hành trình học Hán ngữ',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Banner lỗi
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

  /// Liên kết quay lại màn hình đăng nhập
  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Đã có tài khoản? ',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () => context.pop(),
          child: const Text(
            'Đăng nhập',
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
