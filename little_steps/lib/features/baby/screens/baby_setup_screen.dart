import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_strings.dart';

class BabySetupScreen extends StatelessWidget {
  const BabySetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.babySetup)),
      body: const Center(
        child: Text('Baby setup — coming in Step 1.2', style: AppTextStyles.body),
      ),
    );
  }
}
