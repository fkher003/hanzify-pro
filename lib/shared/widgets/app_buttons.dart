import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Nút bấm chính dùng chung toàn ứng dụng (tái sử dụng).
/// Thiết kế theo spec Stitch: chiều cao 56dp, bo góc 12dp,
/// gradient từ #1A56A4 → #2563EB.
class AppPrimaryButton extends StatelessWidget {
  /// Nội dung văn bản trên nút
  final String label;

  /// Callback khi nhấn nút (null = nút bị vô hiệu hóa)
  final VoidCallback? onPressed;

  /// Hiển thị trạng thái đang tải (spinner thay cho text)
  final bool isLoading;

  /// Icon hiển thị bên trái text (tuỳ chọn)
  final Widget? leadingIcon;

  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          // Gradient từ màu primary sang màu sáng hơn
          gradient: (onPressed != null && !isLoading)
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: (onPressed == null || isLoading)
              ? AppColors.surface
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            // Nền trong suốt để gradient hiển thị qua
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (leadingIcon != null) ...[
                      leadingIcon!,
                      const SizedBox(width: 10),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Nút bấm phụ (outlined / ghost) dùng chung.
/// Ví dụ: nút đăng nhập bằng Google.
class AppOutlineButton extends StatelessWidget {
  /// Nội dung văn bản
  final String label;

  /// Callback khi nhấn
  final VoidCallback? onPressed;

  /// Trạng thái loading
  final bool isLoading;

  /// Icon bên trái
  final Widget? leadingIcon;

  const AppOutlineButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leadingIcon != null) ...[
                    leadingIcon!,
                    const SizedBox(width: 10),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
