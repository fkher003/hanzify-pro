import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/hive_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../home/providers/home_provider.dart';

/// Màn hình Hồ sơ người dùng (Profile Screen).
/// Thiết kế theo Material 3 Dark mode với Primary Color #1A56A4.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  /// Trạng thái switch "Nhắc nhở học tập" — UI-only, chưa kết nối notification service
  bool _reminderEnabled = true;

  // ─── Xử lý Đăng xuất ────────────────────────────────────────────────────

  Future<void> _handleSignOut() async {
    await ref.read(authProvider.notifier).signOut();
    if (mounted) {
      context.go('/login');
    }
  }

  // ─── Xử lý Xóa dữ liệu ─────────────────────────────────────────────────

  Future<void> _handleClearData() async {
    // Hiện Dialog xác nhận trước khi xóa
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 10),
            Text(
              'Xóa dữ liệu?',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Toàn bộ tiến trình học tập và chuỗi ngày (streak) sẽ bị xóa. '
          'Ứng dụng sẽ nạp lại 100 từ vựng mặc định.\n\nBạn có chắc không?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Thực hiện xóa và re-seed
    final hive = ref.read(hiveServiceProvider);
    await hive.clearAllProgressAndReseed();

    // Invalidate provider để HomeScreen cập nhật số liệu mới
    ref.invalidate(homeStatsProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa và nạp lại dữ liệu mặc định!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final displayName =
        user?.displayName ?? user?.email?.split('@').first ?? 'Hanzify Learner';
    final email = user?.email ?? 'Chưa đăng nhập';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar với avatar ────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            backgroundColor: AppColors.background,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildProfileHeader(displayName, email),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 8),

                // ── Section: Cài đặt ──────────────────────────────────────
                _buildSectionLabel('Cài đặt'),
                _buildCard(children: [
                  _buildSwitchTile(
                    icon: Icons.notifications_active_rounded,
                    title: 'Nhắc nhở học tập',
                    subtitle: 'Thông báo hàng ngày lúc 8:00 sáng',
                    value: _reminderEnabled,
                    onChanged: (v) => setState(() => _reminderEnabled = v),
                  ),
                ]),

                const SizedBox(height: 12),

                // ── Section: Tài khoản ────────────────────────────────────
                _buildSectionLabel('Tài khoản'),
                _buildCard(children: [
                  _buildActionTile(
                    icon: Icons.delete_sweep_rounded,
                    iconColor: AppColors.error,
                    title: 'Xóa dữ liệu học tập',
                    titleColor: AppColors.error,
                    subtitle: 'Xóa toàn bộ tiến trình, bắt đầu lại từ đầu',
                    onTap: _handleClearData,
                  ),
                  Divider(
                    height: 1,
                    color: AppColors.border,
                    indent: 56,
                  ),
                  _buildActionTile(
                    icon: Icons.logout_rounded,
                    iconColor: AppColors.textSecondary,
                    title: 'Đăng xuất',
                    subtitle: 'Thoát khỏi tài khoản của bạn',
                    onTap: _handleSignOut,
                  ),
                ]),

                const SizedBox(height: 40),

                // ── Version ───────────────────────────────────────────────
                const Text(
                  'HanzifyPro  •  Phiên bản 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '学而时习之，不亦说乎',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF3D3D5C),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Profile Header ──────────────────────────────────────────────────────

  Widget _buildProfileHeader(String displayName, String email) {
    // Ký tự đầu của tên để làm avatar chữ
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'H';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D1B3E), Color(0xFF0F0F0F)],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),

            // Avatar chữ cái đầu
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A56A4), Color(0xFF2E7DE9)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Tên người dùng
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 4),

            // Email
            Text(
              email,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 12),

            // HSK badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: const Text(
                '🎯 Mục tiêu: HSK 4',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  /// Label tiêu đề cho từng section
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  /// Card bọc nhóm ListTile
  Widget _buildCard({required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: children),
      ),
    );
  }

  /// ListTile với Switch
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
        activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
      ),
    );
  }

  /// ListTile dạng tap (action)
  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    Color titleColor = AppColors.textPrimary,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: titleColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textSecondary,
        size: 20,
      ),
    );
  }
}
