import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/constants/app_router.dart';
import 'core/services/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Khởi tạo Hive: đăng ký TypeAdapter và mở tất cả box
  await HiveService.initialize();

  // Nạp dữ liệu mẫu nếu box từ vựng còn rỗng (lần đầu cài app)
  await HiveService().seedSampleWordsIfEmpty();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}


/// Widget gốc của ứng dụng HanzifyPro.
/// Kết nối với GoRouter thông qua [appRouterProvider].
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lấy router từ provider — tự động xử lý redirect theo auth state
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'HanzifyPro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A56A4),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        useMaterial3: true,
      ),
      // Kết nối GoRouter
      routerConfig: router,
    );
  }
}
