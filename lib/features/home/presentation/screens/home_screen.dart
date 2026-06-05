import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Màn hình Home tạm thời — placeholder sau khi đăng nhập thành công.
/// Sẽ được phát triển đầy đủ ở các sprint tiếp theo.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lấy thông tin user hiện tại từ provider
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'HanzifyPro',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Nút đăng xuất
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Chữ Hán lớn
            const Text(
              '汉字',
              style: TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.bold,
                color: AppColors.chineseRed,
              ),
            ),
            const SizedBox(height: 16),
            // Chào mừng người dùng
            Text(
              'Chào mừng, ${user?.displayName ?? user?.email ?? 'Học viên'}!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tính năng đang được xây dựng...',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 40),
            // Badge cho các tính năng sắp ra mắt
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: const [
                _FeatureBadge(icon: Icons.style, label: 'Flashcard SRS'),
                _FeatureBadge(icon: Icons.brush, label: 'Nét viết'),
                _FeatureBadge(icon: Icons.chat, label: 'AI Chat'),
                _FeatureBadge(icon: Icons.search, label: 'Từ điển'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge hiển thị tính năng sắp ra mắt
class _FeatureBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
