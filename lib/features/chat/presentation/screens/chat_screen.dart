import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Màn hình AI Chat — Placeholder.
/// Sẽ tích hợp Gemini API (google_generative_ai) ở sprint tiếp theo.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'AI Chat — Gemini',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tính năng đang được xây dựng...',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
