import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/story_providers.dart';

class StoryDetailScreen extends ConsumerWidget {
  const StoryDetailScreen({super.key, required this.storyId});
  final String storyId;

  static const _months = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stories = ref.watch(storiesProvider).valueOrNull ?? [];
    final story = stories.where((s) => s.id == storyId).firstOrNull;

    if (story == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final parts = story.monthKey.split('-');
    final monthLabel =
        '${_months[int.parse(parts[1])]} ${parts[0]}';

    return Scaffold(
      appBar: AppBar(
        title: Text(monthLabel),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 6),
                Text('AI-Generated Story',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 16),
            Text(story.title, style: AppTextStyles.headline),
            const SizedBox(height: 20),
            Text(
              story.content,
              style: AppTextStyles.body.copyWith(
                height: 1.8,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            Text('${story.memoryCount} memories · ${story.generatedAt.day}/${story.generatedAt.month}/${story.generatedAt.year}',
                style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}
