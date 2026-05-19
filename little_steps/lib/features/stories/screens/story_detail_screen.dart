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
    final monthLabel = '${_months[int.parse(parts[1])]} ${parts[0]}';

    return Scaffold(
      appBar: AppBar(
        title: Text(monthLabel),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen 3 illustration — shown only when available
            if (story.illustrationUrl != null)
              _IllustrationHero(url: story.illustrationUrl!),

            Padding(
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
                  Text(
                    '${story.memoryCount} memories · '
                    '${story.generatedAt.day}/${story.generatedAt.month}/${story.generatedAt.year}',
                    style: AppTextStyles.caption,
                  ),
                  if (story.illustrationUrl != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.image_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('Illustration by Imagen 3',
                            style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IllustrationHero extends StatelessWidget {
  const _IllustrationHero({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 220,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                color: AppColors.primary.withValues(alpha: 0.08),
                child: const Center(child: CircularProgressIndicator()),
              ),
        errorBuilder: (ctx, err, stack) => Container(
          color: AppColors.primary.withValues(alpha: 0.08),
          child: const Center(
            child: Icon(Icons.image_not_supported_outlined,
                color: AppColors.textSecondary, size: 40),
          ),
        ),
      ),
    );
  }
}
