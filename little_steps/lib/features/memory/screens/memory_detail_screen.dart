import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';

class MemoryDetailScreen extends StatelessWidget {
  const MemoryDetailScreen({super.key, required this.memoryId});

  final String memoryId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Memory')),
      body: Center(
        child: Text('Memory detail — coming in Step 1.3', style: AppTextStyles.body),
      ),
    );
  }
}
