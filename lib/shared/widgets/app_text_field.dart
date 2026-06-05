import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Ô nhập liệu dùng chung toàn ứng dụng (tái sử dụng).
/// Thiết kế theo spec Stitch: chiều cao 56dp, bo góc 12dp, viền #2D2D3D.
class AppTextField extends StatefulWidget {
  /// Label hiển thị phía trên ô nhập liệu
  final String label;

  /// Gợi ý (hint) bên trong ô nhập liệu
  final String hint;

  /// Controller để đọc/ghi nội dung
  final TextEditingController controller;

  /// Ẩn/hiện nội dung (cho ô mật khẩu)
  final bool obscureText;

  /// Loại bàn phím hiển thị
  final TextInputType keyboardType;

  /// Icon phía trước ô nhập liệu
  final IconData? prefixIcon;

  /// Thông báo lỗi (hiển thị màu đỏ bên dưới)
  final String? errorText;

  /// Callback khi người dùng gõ
  final ValueChanged<String>? onChanged;

  /// Có hiện nút toggle ẩn/hiện mật khẩu không
  final bool showPasswordToggle;

  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.errorText,
    this.onChanged,
    this.showPasswordToggle = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  /// Trạng thái ẩn/hiện mật khẩu nội bộ widget
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nhãn label
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),

        // Ô nhập liệu
        TextFormField(
          controller: widget.controller,
          obscureText: _isObscured,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, color: AppColors.textSecondary, size: 20)
                : null,
            // Nút toggle ẩn/hiện mật khẩu
            suffixIcon: widget.showPasswordToggle
                ? IconButton(
                    onPressed: () => setState(() => _isObscured = !_isObscured),
                    icon: Icon(
                      _isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  )
                : null,
            filled: true,
            fillColor: AppColors.surface,
            // Viền mặc định
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border, width: 1),
            ),
            // Viền khi focus — dùng màu primary
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderFocus, width: 1.5),
            ),
            // Viền khi có lỗi
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            errorText: widget.errorText,
            errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          ),
        ),
      ],
    );
  }
}
