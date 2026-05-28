// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_providers.dart';
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
    final monthIndex = int.tryParse(parts[1]) ?? 1;
    final monthLabel = '${_months[monthIndex.clamp(1, 12)]} ${parts[0]}';

    // Editorial layout logic: split content into drop-cap and paragraphs
    final paragraphs = story.content.split('\n\n');
    final String firstParagraph = paragraphs.isNotEmpty ? paragraphs.first : '';

    String firstChar = '';
    String restOfFirst = '';
    if (firstParagraph.isNotEmpty) {
      firstChar = firstParagraph.substring(0, 1);
      restOfFirst = firstParagraph.substring(1);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(monthLabel, style: AppTextStyles.title),
        backgroundColor: AppColors.surface,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            tooltip: 'Edit story',
            onPressed: () => context.push('/stories/$storyId/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Delete story',
            onPressed: () => _confirmDelete(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Full-width Hero image at the top of the blog post
            if (story.photoUrls.isNotEmpty)
              _BlogHeroHeader(url: story.photoUrls.first)
            else if (story.illustrationUrl != null)
              _IllustrationHero(url: story.illustrationUrl!),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: AppColors.primary, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'AI-Generated Story'.toUpperCase(),
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primaryDark,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.auto_awesome,
                          color: AppColors.primary, size: 14),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      story.title,
                      style: AppTextStyles.display.copyWith(
                        fontSize: 26,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      '✦   ✦   ✦',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Interleaved paragraphs and photos (blog style)
                  ..._buildInterleavedContent(firstChar, restOfFirst, paragraphs, story.photoUrls),

                  const SizedBox(height: 24),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 24),
                  
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '${story.memoryCount} photos woven together',
                          style: AppTextStyles.caption.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Generated on ${story.generatedAt.day}/${story.generatedAt.month}/${story.generatedAt.year}',
                          style: AppTextStyles.caption.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final stories = ref.read(storiesProvider).valueOrNull ?? [];
    final story = stories.where((s) => s.id == storyId).firstOrNull;
    if (story == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Story?'),
        content: Text(
          'This will permanently delete "${story.title}". This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final user = ref.read(currentUserProvider);
      if (user?.familyId == null) return;
      try {
        await ref
            .read(storyRepositoryProvider)
            .deleteStory(user!.familyId!, storyId);
        if (context.mounted) {
          Navigator.of(context).pop(); // back to stories list
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Story deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not delete: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  List<Widget> _buildInterleavedContent(
    String firstChar,
    String restOfFirst,
    List<String> paragraphs,
    List<String> photoUrls,
  ) {
    final List<Widget> children = [];
    final remainingPhotos = photoUrls.length > 1 ? photoUrls.sublist(1) : const <String>[];
    final int step = remainingPhotos.isNotEmpty
        ? (paragraphs.length / (remainingPhotos.length + 1)).floor().clamp(1, paragraphs.length)
        : paragraphs.length;

    for (int i = 0; i < paragraphs.length; i++) {
      final para = paragraphs[i];
      if (para.trim().isEmpty) continue;

      if (i == 0 && firstChar.isNotEmpty) {
        children.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              firstChar,
              style: const TextStyle(
                fontFamily: 'Lora',
                fontSize: 54,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                height: 0.95,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(restOfFirst, style: AppTextStyles.storyBody)),
          ],
        ));
      } else {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Text(para, style: AppTextStyles.storyBody),
        ));
      }

      final int oneBasedIndex = i + 1;
      if (remainingPhotos.isNotEmpty &&
          oneBasedIndex % step == 0 &&
          (oneBasedIndex ~/ step) - 1 < remainingPhotos.length) {
        final photoIndex = (oneBasedIndex ~/ step) - 1;
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              remainingPhotos[photoIndex],
              fit: BoxFit.cover,
              width: double.infinity,
              height: 250,
            ),
          ),
        ));
      }
    }
    return children;
  }
}



class _IllustrationHero extends StatelessWidget {
  const _IllustrationHero({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : Container(
                  color: AppColors.shimmerBase,
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ),
          errorBuilder: (ctx, err, stack) => Container(
            color: AppColors.surface,
            child: const Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: AppColors.textSecondary,
                size: 40,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BlogHeroHeader extends StatelessWidget {
  const _BlogHeroHeader({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => Container(
          color: AppColors.surface,
          child: const Center(
            child: Icon(Icons.image_not_supported_outlined,
                color: AppColors.textSecondary, size: 40),
          ),
        ),
      ),
    );
  }
}

