import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class CollageScreen extends StatelessWidget {
  const CollageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appName)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_library_outlined, size: 72, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text(AppStrings.addFirstMemory, style: AppTextStyles.title),
            const SizedBox(height: 8),
            const Text(AppStrings.addFirstMemorySubtitle, style: AppTextStyles.bodySecondary),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Add memory'),
      ),
    );
  }
}
