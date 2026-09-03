# HanzifyPro 🇨🇳📚

HanzifyPro là một ứng dụng học tiếng Trung hiện đại, tối giản và thông minh, được thiết kế đặc biệt dành cho người học từ con số 0 đến cấp độ HSK4. Ứng dụng tích hợp các công nghệ tiên tiến nhất của Flutter, quản lý trạng thái mượt mà, và sự hỗ trợ đắc lực từ Trí tuệ Nhân tạo (Gemini AI) để đem đến trải nghiệm học tập trọn vẹn và cá nhân hóa.

---

## 🌟 Tính năng nổi bật

### 1. 📊 Bảng điều khiển (Dashboard)
- Hiển thị tiến độ hoàn thành mục tiêu HSK4 với biểu đồ trực quan (Donut Chart).
- Theo dõi tần suất học tập trong 7 ngày gần nhất qua Bar Chart (tích hợp thư viện `fl_chart`), với hiệu ứng làm nổi bật ngày hiện tại.
- Thống kê tỷ lệ nhớ từ vựng và số lượng từ đã học.

### 2. 🗂️ Quản lý & Học Từ Vựng Offline
- Hỗ trợ học tập mượt mà không cần mạng với cơ sở dữ liệu nội bộ.
- Dữ liệu 100+ từ vựng mẫu (từ cơ bản đến HSK4) được nạp tự động qua file JSON (`assets/hsk4_vocab.json`).
- Quản lý trạng thái học tập, streak (chuỗi ngày học) và lịch sử lưu trữ bền vững trên bộ nhớ thiết bị bằng `Hive`.

### 3. 🧠 Luyện tập với Flashcard & Stroke Canvas
- Giao diện thẻ ghi nhớ (Flashcard) tối ưu việc lặp lại ngắt quãng.
- **Stroke Canvas:** Tích hợp bảng vẽ cho phép người dùng luyện viết Hán tự trực tiếp trên màn hình, hỗ trợ tốt cho việc ghi nhớ mặt chữ.

### 4. 🤖 AI Chat (Gia Sư Ảo)
- Tích hợp sức mạnh của **Google Gemini 1.5 Flash**.
- Cung cấp tính năng "Phỏng vấn xin việc" hoặc các kịch bản hội thoại để người dùng luyện phản xạ giao tiếp.
- AI phản hồi với tốc độ cao, hỗ trợ phân tích ngữ pháp, dịch nghĩa tiếng Việt, và phiên âm (Pinyin) trong từng tin nhắn thông qua cấu trúc JSON định dạng nghiêm ngặt (`responseMimeType: 'application/json'`).
- Bong bóng chat được thiết kế tinh tế với phần chia đôi để tách biệt ngôn ngữ gốc và giải thích ngữ pháp.

### 5. 👤 Quản lý Hồ Sơ (Profile)
- Quản lý nhắc nhở học tập hàng ngày.
- Quản lý dữ liệu người dùng (có thể dễ dàng xóa và reset toàn bộ tiến độ/từ vựng về trạng thái ban đầu).
- Giao diện Material 3 (Dark Mode) xuyên suốt.

---

## 🏗️ Kiến trúc & Công nghệ (Tech Stack)

HanzifyPro được xây dựng dựa trên các tiêu chuẩn hiện đại nhất của hệ sinh thái Flutter (Dart 3.x, Null Safety):

- **Framework:** Flutter (Material 3).
- **State Management:** Riverpod 2.x (`flutter_riverpod`). Hoàn toàn không sử dụng `setState` để đảm bảo luồng dữ liệu một chiều rõ ràng và tối ưu hiệu năng.
- **Navigation:** GoRouter.
- **Local Storage:** Hive & Hive Flutter.
- **AI Integration:** Google Generative AI (`google_generative_ai`).
- **Charting:** FL Chart (`fl_chart`).
- **Design Pattern:** Feature-first / Layered Architecture. Giao diện ưu tiên giao diện Dark Mode (Màu chủ đạo: `#1A56A4`, Nền: `#0F0F0F` / `#1E1E2E`).

---

## ⚙️ Cài đặt & Khởi chạy

### Yêu cầu hệ thống
- Flutter SDK 3.19+ (hoặc mới nhất).
- Dart 3.x (Bắt buộc dùng Null Safety).
- Khuyến nghị dùng Android Studio hoặc VS Code với extension Flutter.

### Khởi chạy dự án

1. Clone dự án về máy:
   ```bash
   git clone <repo_url>
   cd hanzify_pro
   ```

2. Cài đặt các thư viện phụ thuộc:
   ```bash
   flutter pub get
   ```

3. (Tùy chọn) Khởi tạo lại dữ liệu Hive (nếu có thay đổi Model):
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. Cấu hình biến môi trường và chạy ứng dụng:
   Ứng dụng yêu cầu cung cấp khóa Gemini API qua biến môi trường để tính năng AI Chat có thể hoạt động.
   ```bash
   flutter run --dart-define=GEMINI_KEY="YOUR_GEMINI_API_KEY_HERE"
   ```

### 🚀 Xuất bản (Release Build)

Để biên dịch tệp APK tối ưu hóa hiệu năng, tích hợp nhúng khóa API an toàn (AOT Compilation + Tree-shaking):

```bash
flutter build apk --release --dart-define=GEMINI_KEY="YOUR_GEMINI_API_KEY_HERE"
```
*Lưu ý: Ứng dụng yêu cầu Android `minSdk = 24` để tương thích tốt với các thư viện native.*

---

## 🎨 Giao diện ứng dụng

- **Màu sắc:** Tối giản, tập trung vào chế độ tối (Dark Navy Blue).
- **Trải nghiệm:** Cảm giác vuốt chạm tự nhiên, chuyển cảnh mềm mại qua GoRouter, và phản hồi tức thì từ Riverpod.

## 📄 Bản quyền
(C) 2026 HanzifyPro. Tác giả & Agentic IDE.
