import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Trạng thái xác thực ──────────────────────────────────────────────────

/// Các trạng thái có thể của quá trình xác thực
enum AuthStatus {
  /// Chưa xác thực
  unauthenticated,

  /// Đã xác thực thành công
  authenticated,

  /// Đang tiến hành xác thực
  loading,
}

/// Dữ liệu trạng thái của Auth feature
class AuthState {
  /// Trạng thái hiện tại
  final AuthStatus status;

  /// Người dùng hiện tại (null nếu chưa đăng nhập)
  final User? user;

  /// Thông báo lỗi (null nếu không có lỗi)
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  /// Trạng thái ban đầu — chưa xác thực
  factory AuthState.initial() => const AuthState(status: AuthStatus.unauthenticated);

  /// Tạo bản sao với một số trường được cập nhật
  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

// ─── AsyncNotifier ────────────────────────────────────────────────────────

/// Provider quản lý trạng thái xác thực.
/// Sử dụng AsyncNotifier để xử lý các thao tác bất đồng bộ.
///
/// TUYỆT ĐỐI KHÔNG dùng setState — mọi state thay đổi đều qua notifier này.
class AuthNotifier extends AsyncNotifier<AuthState> {
  /// Firebase Auth instance
  FirebaseAuth get _auth => FirebaseAuth.instance;

  @override
  Future<AuthState> build() async {
    // Lắng nghe thay đổi trạng thái đăng nhập từ Firebase
    final user = _auth.currentUser;
    if (user != null) {
      return AuthState(status: AuthStatus.authenticated, user: user);
    }
    return AuthState.initial();
  }

  /// Đăng nhập bằng Email và Mật khẩu.
  ///
  /// Tham số:
  /// - [email]: Địa chỉ email người dùng
  /// - [password]: Mật khẩu
  ///
  /// Cập nhật state sang [AuthStatus.loading] trong khi xử lý,
  /// [AuthStatus.authenticated] nếu thành công,
  /// hoặc giữ [AuthStatus.unauthenticated] kèm thông báo lỗi nếu thất bại.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    // Cập nhật trạng thái đang tải
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthState(
        status: AuthStatus.authenticated,
        user: credential.user,
      );
    });

    // Nếu có lỗi, chuyển thành thông báo tiếng Việt thân thiện
    if (state.hasError) {
      final errorMsg = _mapFirebaseError(state.error);
      state = AsyncData(AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: errorMsg,
      ));
    }
  }

  /// Đăng ký tài khoản mới bằng Email và Mật khẩu.
  ///
  /// Tham số:
  /// - [displayName]: Tên hiển thị của người dùng
  /// - [email]: Địa chỉ email
  /// - [password]: Mật khẩu (ít nhất 6 ký tự)
  Future<void> registerWithEmail({
    required String displayName,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      // Tạo tài khoản mới
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Cập nhật tên hiển thị sau khi đăng ký thành công
      await credential.user?.updateDisplayName(displayName.trim());
      await credential.user?.reload();

      return AuthState(
        status: AuthStatus.authenticated,
        user: _auth.currentUser,
      );
    });

    // Chuyển lỗi Firebase sang thông báo tiếng Việt
    if (state.hasError) {
      final errorMsg = _mapFirebaseError(state.error);
      state = AsyncData(AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: errorMsg,
      ));
    }
  }

  /// Đăng xuất khỏi ứng dụng.
  Future<void> signOut() async {
    await _auth.signOut();
    state = AsyncData(AuthState.initial());
  }

  /// Xoá thông báo lỗi hiện tại.
  void clearError() {
    final currentData = state.valueOrNull;
    if (currentData != null) {
      state = AsyncData(currentData.copyWith(errorMessage: null));
    }
  }

  /// Chuyển đổi FirebaseAuthException sang thông báo tiếng Việt thân thiện.
  String _mapFirebaseError(Object? error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'Không tìm thấy tài khoản với email này.';
        case 'wrong-password':
          return 'Mật khẩu không đúng. Vui lòng thử lại.';
        case 'invalid-credential':
          return 'Email hoặc mật khẩu không đúng.';
        case 'email-already-in-use':
          return 'Email này đã được sử dụng bởi tài khoản khác.';
        case 'weak-password':
          return 'Mật khẩu quá yếu. Vui lòng dùng ít nhất 6 ký tự.';
        case 'invalid-email':
          return 'Định dạng email không hợp lệ.';
        case 'too-many-requests':
          return 'Quá nhiều lần thử. Vui lòng đợi một lúc rồi thử lại.';
        case 'network-request-failed':
          return 'Lỗi kết nối mạng. Vui lòng kiểm tra internet.';
        case 'user-disabled':
          return 'Tài khoản này đã bị vô hiệu hóa.';
        default:
          return error.message ?? 'Đã có lỗi xảy ra. Vui lòng thử lại.';
      }
    }
    return 'Đã có lỗi xảy ra. Vui lòng thử lại.';
  }
}

// ─── Providers ────────────────────────────────────────────────────────────

/// Provider chính quản lý trạng thái Auth toàn ứng dụng.
/// Dùng trong toàn bộ ứng dụng để theo dõi trạng thái đăng nhập.
final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// Provider tiện ích — trả về user hiện tại (hoặc null nếu chưa đăng nhập).
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authProvider).valueOrNull;
  return authState?.user;
});

/// Provider kiểm tra nhanh — người dùng đã xác thực hay chưa.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider).valueOrNull;
  return authState?.status == AuthStatus.authenticated;
});
