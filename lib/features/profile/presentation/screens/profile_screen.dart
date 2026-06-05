import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Màn hình Hồ sơ — Placeholder với thông tin user và nút đăng xuất.
/// Sẽ được phát triển đầy đủ ở sprint tiếp theo.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lấy thông tin user từ provider
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar placeholder
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.surface,
              child: Text(
                (user?.displayName?.isNotEmpty == true)
                    ? user!.displayName![0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.displayName ?? 'Học viên',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Tính năng đang được xây dựng...',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            // Nút đăng xuất
            TextButton.icon(
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text(
                'Đăng xuất',
                style: TextStyle(color: AppColors.error, fontSize: 16),
              ),
              onPressed: () async {
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
