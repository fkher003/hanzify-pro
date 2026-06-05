import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

/// Scaffold chính của ứng dụng — chứa BottomNavigationBar 4 tab.
/// Theo Stitch spec: nền #1E1E2E, selected #1A56A4, unselected #6B7280.
/// Sử dụng StatefulShellRoute của go_router để giữ state mỗi tab.
class MainScaffold extends StatelessWidget {
  /// NavigationShell từ StatefulShellRoute — quản lý switching giữa tabs
  final StatefulNavigationShell navigationShell;

  const MainScaffold({
    super.key,
    required this.navigationShell,
  });

  // ─── Định nghĩa các tab ─────────────────────────────────────────────────

  /// Danh sách tab: label, icon inactive, icon active
  static const List<_TabItem> _tabs = [
    _TabItem(
      label: 'Trang chủ',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
    ),
    _TabItem(
      label: 'Flashcard',
      icon: Icons.style_outlined,
      activeIcon: Icons.style,
    ),
    _TabItem(
      label: 'AI Chat',
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
    ),
    _TabItem(
      label: 'Hồ sơ',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
    ),
  ];

  // ─── Xử lý tap tab ──────────────────────────────────────────────────────

  /// Khi người dùng nhấn tab, goBranch điều hướng đến branch tương ứng.
  /// initialLocation=true để reset về root của branch khi tap lại tab hiện tại.
  void _onTabTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // Body là nội dung của tab hiện tại (quản lý bởi StatefulShellRoute)
      body: navigationShell,

      // ── Bottom Navigation Bar ───────────────────────────────────────────
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  /// Xây dựng BottomNavigationBar theo Stitch spec.
  Widget _buildBottomNav() {
    final selectedIndex = navigationShell.currentIndex;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 65,
          child: Row(
            children: List.generate(_tabs.length, (index) {
              final tab = _tabs[index];
              final isSelected = index == selectedIndex;
              return _TabButton(
                tab: tab,
                isSelected: isSelected,
                onTap: () => _onTabTapped(index),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── Model Tab Item ──────────────────────────────────────────────────────────

/// Data class chứa thông tin một tab trong bottom nav
class _TabItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _TabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

// ─── Tab Button Widget ───────────────────────────────────────────────────────

/// Nút tab trong BottomNavigationBar với hiệu ứng indicator pill.
/// Màu selected: #1A56A4 với nền pill rgba(26,86,164,0.15).
class _TabButton extends StatelessWidget {
  final _TabItem tab;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon với indicator pill khi selected
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  // Pill indicator khi selected
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  isSelected ? tab.activeIcon : tab.icon,
                  size: 24,
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 4),
              // Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFF6B7280),
                ),
                child: Text(tab.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
