# AGENTS.md — Định hướng Kiến trúc HanzifyPro

> Tài liệu này định nghĩa các quy ước, kiến trúc và quy tắc code bắt buộc cho toàn bộ dự án HanzifyPro.
> Mọi AI agent và lập trình viên đều phải tuân thủ nghiêm ngặt các hướng dẫn trong file này.

---

## 1. Kiến trúc: Feature-First Structure

Dự án sử dụng kiến trúc **Feature-First** — mỗi tính năng là một module độc lập.

```
lib/
├── main.dart                   # Điểm khởi động ứng dụng
├── firebase_options.dart       # Cấu hình Firebase tự động sinh
├── core/
│   ├── constants/              # Hằng số toàn cục (màu sắc, kích thước, chuỗi)
│   ├── services/               # Các service dùng chung (AI, TTS, HTTP...)
│   ├── models/                 # Data models cốt lõi (Word, FlashCard, ChatMessage)
│   └── utils/
│       └── srs_algorithm.dart  # Thuật toán SM-2 cho Spaced Repetition
├── features/
│   ├── auth/                   # Xác thực người dùng (đăng nhập, đăng ký)
│   ├── home/                   # Màn hình chính / dashboard
│   ├── flashcard/              # Hệ thống flashcard và ôn tập SRS
│   ├── stroke/                 # Hướng dẫn nét viết chữ Hán
│   ├── chat/                   # Chat AI với Gemini
│   └── search/                 # Tìm kiếm từ vựng
└── shared/
    ├── widgets/                # Widget dùng chung giữa các features
    └── theme/                  # Theme, màu sắc, typography toàn cục
```

### Quy tắc tổ chức trong mỗi feature:
```
features/<ten_feature>/
├── data/
│   ├── datasources/            # Nguồn dữ liệu (Firestore, Hive, API)
│   └── repositories/          # Triển khai repository
├── domain/
│   ├── entities/               # Business entities (nếu khác model)
│   └── repositories/          # Abstract repository interfaces
├── presentation/
│   ├── screens/                # Các màn hình (Screen widgets)
│   ├── widgets/                # Widget riêng của feature này
│   └── providers/              # Riverpod providers của feature
```

---

## 2. State Management: Riverpod 2.x

- Sử dụng **flutter_riverpod** phiên bản 2.x.
- Ưu tiên dùng `AsyncNotifier` cho các state bất đồng bộ.
- Dùng `StateNotifier` cho các state đồng bộ phức tạp.
- Dùng `Provider`, `FutureProvider`, `StreamProvider` cho các trường hợp đơn giản.
- **TUYỆT ĐỐI KHÔNG** dùng `setState()` — mọi state đều phải đi qua Riverpod.
- Đặt tên provider theo quy ước: `<tênFeature><Chức năng>Provider` (ví dụ: `flashcardListProvider`).
- Tất cả provider phải được khai báo ở file `providers/` trong feature tương ứng.

```dart
// ✅ ĐÚNG — Dùng AsyncNotifier
@riverpod
class FlashcardList extends _$FlashcardList {
  @override
  Future<List<FlashCard>> build() async {
    return ref.watch(flashcardRepositoryProvider).getCards();
  }
}

// ❌ SAI — Không dùng setState
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}
class _MyWidgetState extends State<MyWidget> {
  void _doSomething() {
    setState(() { /* CẤM! */ });
  }
}
```

---

## 3. Routing: go_router

- Sử dụng **go_router** cho toàn bộ điều hướng.
- Định nghĩa tất cả routes tại `lib/core/constants/app_router.dart`.
- Sử dụng named routes với constant string để tránh lỗi typo.
- Hỗ trợ deep linking và redirect (ví dụ: redirect về login nếu chưa xác thực).

```dart
// Ví dụ cấu trúc router
final appRouter = GoRouter(
  redirect: (context, state) {
    // Kiểm tra auth và redirect phù hợp
  },
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/flashcard', builder: (_, __) => const FlashcardScreen()),
    // ...
  ],
);
```

---

## 4. AI Service: Gemini API

- Sử dụng thư viện **google_generative_ai** (package chính thức của Google).
- Model mặc định: `gemini-2.0-flash` (hoặc phiên bản mới nhất hỗ trợ).
- Tất cả logic liên quan đến Gemini đặt trong `lib/core/services/gemini_service.dart`.
- Hỗ trợ multi-turn chat (lịch sử hội thoại) cho tính năng chat.
- Prompt engineering cho các tác vụ: giải nghĩa từ, kiểm tra ngữ pháp, tạo ví dụ.

```dart
// Cách khởi tạo service
class GeminiService {
  final GenerativeModel _model;

  GeminiService()
      : _model = GenerativeModel(
          model: 'gemini-2.0-flash',
          apiKey: const String.fromEnvironment('GEMINI_KEY'),
        );
}
```

---

## 5. Quản lý API Key

- **KHÔNG BAO GIỜ** hardcode API key vào source code.
- **KHÔNG BAO GIỜ** commit API key lên Git.
- Gemini API key được truyền qua `--dart-define` khi build/run:

```bash
# Chạy development
flutter run --dart-define=GEMINI_KEY=your_api_key_here

# Build production
flutter build apk --dart-define=GEMINI_KEY=your_api_key_here
flutter build appbundle --dart-define=GEMINI_KEY=your_api_key_here
```

- Đọc key trong code bằng:
```dart
const geminiApiKey = String.fromEnvironment('GEMINI_KEY');
```

- Đảm bảo `.gitignore` chứa các file `.env` và không commit key.

---

## 6. Quy tắc Code

### Ngôn ngữ comment
- Tất cả comment phải viết **bằng tiếng Việt**.
- Docstring (`///`) cho public API cũng viết bằng tiếng Việt.

```dart
/// Lớp đại diện cho một từ vựng trong từ điển Hán-Việt.
class Word {
  // ID duy nhất của từ (dùng UUID hoặc ID từ Firestore)
  final String id;

  // Chữ Hán (ví dụ: 你好)
  final String hanzi;
}
```

### Null Safety
- Bắt buộc dùng **Dart 3.x null safety**.
- Không dùng `dynamic` trừ khi thực sự cần thiết.
- Ưu tiên `required` parameter thay vì nullable parameter khi có thể.
- Dùng `?` và `??` một cách có chủ ý, không dùng tràn lan.

### Naming Conventions
| Loại | Quy ước | Ví dụ |
|------|---------|-------|
| Class | PascalCase | `FlashCard`, `GeminiService` |
| Variable / Function | camelCase | `cardList`, `fetchWord()` |
| Constant | camelCase với `k` prefix | `kPrimaryColor`, `kApiUrl` |
| File | snake_case | `flash_card.dart`, `gemini_service.dart` |
| Provider | camelCase + Provider | `flashcardListProvider` |

### Cấu trúc file dart
```dart
// 1. Imports (theo thứ tự: dart:, package:, relative)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/word.dart';

// 2. Part directives (nếu dùng code generation)
part 'word.g.dart';

// 3. Constants của file (nếu có)

// 4. Class definition với docstring tiếng Việt
/// Mô tả class bằng tiếng Việt
class MyClass {
  // ...
}
```

---

## 7. Database: Hive (Local) + Firestore (Cloud)

- **Hive** (`hive_flutter`): Lưu trữ cục bộ — flashcard progress, settings, cache.
- **Firestore** (`cloud_firestore`): Đồng bộ cloud — user data, từ điển, tiến trình.
- **Firebase Auth** (`firebase_auth`): Xác thực người dùng.
- Tất cả logic DB đặt trong `data/datasources/` của từng feature.
- Không gọi DB trực tiếp từ presentation layer — phải qua repository.

---

## 8. Các thư viện chính (Dependencies)

| Package | Mục đích |
|---------|---------|
| `google_generative_ai` | Tích hợp Gemini AI |
| `flutter_riverpod` | State management |
| `hive_flutter` | Local database (offline) |
| `go_router` | Điều hướng màn hình |
| `flutter_tts` | Text-to-Speech phát âm |
| `dio` | HTTP client (gọi API ngoài) |
| `fl_chart` | Biểu đồ tiến trình học tập |
| `firebase_core` | Firebase core |
| `firebase_auth` | Xác thực Firebase |
| `cloud_firestore` | Cloud database |

---

## 9. Quy trình làm việc với AI Agent

Khi AI agent nhận được task trong project này:

1. **Đọc file này trước** — Luôn bắt đầu bằng việc đọc `AGENTS.md`.
2. **Đặt code đúng chỗ** — Không tạo file ngoài cấu trúc đã định.
3. **Tuân thủ Riverpod** — Không dùng `setState` dưới mọi hình thức.
4. **Comment tiếng Việt** — Mọi comment đều phải bằng tiếng Việt.
5. **Null safety** — Dart 3.x, không có late hoặc ! trừ khi chắc chắn.
6. **Không hardcode key** — Dùng `String.fromEnvironment('GEMINI_KEY')`.
7. **Test trước khi báo cáo** — Đảm bảo code biên dịch được.

---

*Tài liệu này được tạo ngày 2026-06-03. Cập nhật khi có thay đổi kiến trúc lớn.*
