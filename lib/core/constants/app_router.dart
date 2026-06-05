import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';

// ─── Tên routes (constants) ──────────────────────────────────────────────

/// Đường dẫn route cho màn hình Login
const String kRouteLogin = '/login';

/// Đường dẫn route cho màn hình Register
const String kRouteRegister = '/register';

/// Đường dẫn route cho màn hình Home
const String kRouteHome = '/home';

// ─── Router Provider ─────────────────────────────────────────────────────

/// Provider cung cấp GoRouter cho toàn bộ ứng dụng.
/// Tích hợp với [authProvider] để redirect tự động:
/// - Chưa đăng nhập → /login
/// - Đã đăng nhập mà vào /login → /home
final appRouterProvider = Provider<GoRouter>((ref) {
  // Lắng nghe auth state để redirect khi state thay đổi
  final authNotifier = ValueNotifier<AsyncValue<AuthState>>(
    ref.read(authProvider),
  );

  // Cập nhật notifier khi auth state thay đổi
  ref.listen<AsyncValue<AuthState>>(authProvider, (_, next) {
    authNotifier.value = next;
  });

  return GoRouter(
    initialLocation: kRouteLogin,
    debugLogDiagnostics: false,

    // Lắng nghe thay đổi để router refresh khi auth state thay đổi
    refreshListenable: authNotifier,

    // Redirect logic: kiểm tra auth state và điều hướng phù hợp
    redirect: (BuildContext context, GoRouterState state) {
      final authAsync = authNotifier.value;

      // Đang tải auth state — chưa redirect
      if (authAsync.isLoading) return null;

      final authData = authAsync.valueOrNull;
      final isAuthenticated = authData?.status == AuthStatus.authenticated;
      final isOnAuthRoute =
          state.matchedLocation == kRouteLogin ||
          state.matchedLocation == kRouteRegister;

      // Chưa đăng nhập và không ở trang auth → về login
      if (!isAuthenticated && !isOnAuthRoute) return kRouteLogin;

      // Đã đăng nhập nhưng đang ở trang login → về home
      if (isAuthenticated && state.matchedLocation == kRouteLogin) {
        return kRouteHome;
      }

      // Không cần redirect
      return null;
    },

    routes: [
      // ── Màn hình Đăng nhập ──────────────────────────────────────────
      GoRoute(
        path: kRouteLogin,
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Màn hình Đăng ký ────────────────────────────────────────────
      GoRoute(
        path: kRouteRegister,
        name: 'register',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RegisterScreen(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),

      // ── Màn hình Home ────────────────────────────────────────────────
      GoRoute(
        path: kRouteHome,
        name: 'home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HomeScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
    ],

    // Xử lý route không tồn tại
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Center(
        child: Text(
          'Không tìm thấy trang: ${state.uri}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    ),
  );
});

// ─── Transition Builders ──────────────────────────────────────────────────

/// Hiệu ứng chuyển trang Fade
Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}

/// Hiệu ứng chuyển trang Slide Up (cho màn hình đăng ký)
Widget _slideUpTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
    child: child,
  );
}
