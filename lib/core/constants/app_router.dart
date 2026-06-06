import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/word.dart';
import '../../core/models/chat_models.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/chat/presentation/screens/scenario_screen.dart';
import '../../features/flashcard/presentation/screens/flashcard_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/stroke/presentation/stroke_screen.dart';
import '../../shared/widgets/main_scaffold.dart';

// ─── Đường dẫn Route (constants) ─────────────────────────────────────────────

/// Route auth: đăng nhập
const String kRouteLogin = '/login';

/// Route auth: đăng ký
const String kRouteRegister = '/register';

/// Route chính app — root của StatefulShellRoute
const String kRouteHome = '/home';

/// Route Flashcard tab
const String kRouteFlashcard = '/flashcard';

/// Route AI Chat tab (Scenario Picker)
const String kRouteChat = '/chat';

/// Route Chat conversation
const String kRouteConversation = '/chat/conversation';

/// Route Hồ sơ tab
const String kRouteProfile = '/profile';

// kRouteStroke được định nghĩa trong stroke_screen.dart: '/stroke'

// ─── Router Provider ──────────────────────────────────────────────────────────

/// Provider cung cấp GoRouter toàn ứng dụng.
///
/// Kiến trúc route:
/// ```
/// /login            → LoginScreen
/// /register         → RegisterScreen
/// StatefulShellRoute (MainScaffold)
///   /home           → HomeScreen       [tab 0]
///   /flashcard      → FlashcardScreen  [tab 1]
///   /chat           → ChatScreen       [tab 2]
///   /profile        → ProfileScreen    [tab 3]
/// ```
///
/// Auth redirect: Chưa đăng nhập → /login, Đã đăng nhập → /home.
/// Giữ nguyên luồng Firebase Auth đã có.
final appRouterProvider = Provider<GoRouter>((ref) {
  // Lắng nghe auth state để trigger redirect khi đăng nhập/đăng xuất
  final authNotifier = ValueNotifier<AsyncValue<AuthState>>(
    ref.read(authProvider),
  );

  // Cập nhật notifier mỗi khi auth state thay đổi
  ref.listen<AsyncValue<AuthState>>(authProvider, (_, next) {
    authNotifier.value = next;
  });

  return GoRouter(
    initialLocation: kRouteLogin,
    debugLogDiagnostics: false,

    // Router tự refresh khi auth state thay đổi
    refreshListenable: authNotifier,

    // ── Redirect Logic ────────────────────────────────────────────────────
    redirect: (BuildContext context, GoRouterState state) {
      final authAsync = authNotifier.value;

      // Đang tải — chưa redirect
      if (authAsync.isLoading) return null;

      final authData = authAsync.valueOrNull;
      final isAuthenticated = authData?.status == AuthStatus.authenticated;

      // Các route auth không cần bảo vệ
      final isOnAuthRoute =
          state.matchedLocation == kRouteLogin ||
          state.matchedLocation == kRouteRegister;

      // Chưa đăng nhập → về login
      if (!isAuthenticated && !isOnAuthRoute) return kRouteLogin;

      // Đã đăng nhập mà vào login → về home
      if (isAuthenticated && state.matchedLocation == kRouteLogin) {
        return kRouteHome;
      }

      return null;
    },

    // ── Routes ────────────────────────────────────────────────────────────
    routes: [
      // ── Đăng nhập ───────────────────────────────────────────────────────
      GoRoute(
        path: kRouteLogin,
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Đăng ký ─────────────────────────────────────────────────────────
      GoRoute(
        path: kRouteRegister,
        name: 'register',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RegisterScreen(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),

      // ── Màn hình luyện viết chữ Hán ─────────────────────────────────────
      // Đặt NGOÀI StatefulShellRoute → push lên trên toàn màn hình, không có BottomNav.
      GoRoute(
        path: kRouteStroke,
        name: 'stroke',
        pageBuilder: (context, state) {
          // Nhận Word object được truyền qua context.push(extra: word)
          final word = state.extra as Word;
          return CustomTransitionPage(
            key: state.pageKey,
            child: StrokeScreen(word: word),
            transitionsBuilder: _slideUpTransition,
          );
        },
      ),

      // ── Màn hình AI Chat Conversation ─────────────────────────────────────
      GoRoute(
        path: kRouteConversation,
        name: 'conversation',
        pageBuilder: (context, state) {
          final scenario = state.extra as ChatScenario;
          return CustomTransitionPage(
            key: state.pageKey,
            child: ChatScreen(scenario: scenario),
            transitionsBuilder: _slideUpTransition,
          );
        },
      ),

      // ── Shell Route — Main App với Bottom Navigation ────────────────────
      // StatefulShellRoute giữ nguyên state (không rebuild) khi chuyển tab.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // MainScaffold nhận navigationShell để quản lý bottom nav + tab switching
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          // ── Branch 0: Trang chủ ─────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: kRouteHome,
                name: 'home',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeScreen(),
                ),
              ),
            ],
          ),

          // ── Branch 1: Flashcard ──────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: kRouteFlashcard,
                name: 'flashcard',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: FlashcardScreen(),
                ),
              ),
            ],
          ),

          // ── Branch 2: AI Chat ────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: kRouteChat,
                name: 'chat_scenario',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ScenarioScreen(),
                ),
              ),
            ],
          ),

          // ── Branch 3: Hồ sơ ─────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: kRouteProfile,
                name: 'profile',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],

    // Route không tồn tại → hiển thị error screen
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          'Không tìm thấy trang: ${state.uri}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    ),
  );
});


// ─── Transition Builders ──────────────────────────────────────────────────────

/// Hiệu ứng Fade — dùng cho Login/Home
Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}

/// Hiệu ứng Slide Up — dùng cho Register
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
