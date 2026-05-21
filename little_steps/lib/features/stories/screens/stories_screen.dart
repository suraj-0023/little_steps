// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/app_shell.dart';
import '../../auth/providers/auth_providers.dart';
import '../../baby/providers/baby_providers.dart';
import '../../memory/providers/memory_providers.dart';
import '../models/story.dart';
import '../providers/story_providers.dart';

class StoriesScreen extends ConsumerWidget {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(storiesProvider);
    final memories = ref.watch(memoriesProvider).valueOrNull ?? [];
    final generating = ref.watch(storyGeneratingProvider);

    // Derive available months from memories
    final months = memories
        .map((m) =>
            '${m.takenAt.year}-${m.takenAt.month.toString().padLeft(2, '0')}')
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stories'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: AppShell.openDrawer,
        ),
      ),
      body: storiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stories) {
          if (months.isEmpty) {
            return _NoMemoriesState();
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _GenerateCard(
                currentMonthKey: months.first,
                hasStory: stories.any((s) => s.monthKey == months.first),
                generating: generating,
                onGenerate: () =>
                    _generate(context, ref, months.first),
              ),
              const SizedBox(height: 24),
              if (stories.isNotEmpty) ...[
                Text('Previous stories', style: AppTextStyles.title),
                const SizedBox(height: 12),
                ...stories.map((s) => _StoryCard(
                      story: s,
                      onTap: () => context.push('/stories/${s.id}'),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _generate(
      BuildContext context, WidgetRef ref, String monthKey) async {
    final user = ref.read(currentUserProvider);
    final baby = ref.read(currentBabyProvider).valueOrNull;
    if (user?.familyId == null || baby == null) return;

    ref.read(storyGeneratingProvider.notifier).state = true;
    try {
      await ref.read(storyRepositoryProvider).generateStory(
            familyId: user!.familyId!,
            babyId: baby.id,
            monthKey: monthKey,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Story generated!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Story generation requires Cloud Functions to be deployed.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      ref.read(storyGeneratingProvider.notifier).state = false;
    }
  }
}

class _GenerateCard extends StatelessWidget {
  const _GenerateCard({
    required this.currentMonthKey,
    required this.hasStory,
    required this.generating,
    required this.onGenerate,
  });
  final String currentMonthKey;
  final bool hasStory;
  final bool generating;
  final VoidCallback onGenerate;

  String get _monthLabel {
    final parts = currentMonthKey.split('-');
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthIndex = int.tryParse(parts[1]) ?? 1;
    return '${months[monthIndex.clamp(1, 12)]} ${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Monthly Story',
                  style: AppTextStyles.caption
                      .copyWith(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 8),
          Text(_monthLabel,
              style: AppTextStyles.title
                  .copyWith(color: Colors.white, fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            hasStory
                ? 'Story already generated for this month'
                : 'Let AI write a beautiful story from this month\'s memories',
            style:
                AppTextStyles.bodySecondary.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          generating
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                  ),
                  onPressed: onGenerate,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: Text(hasStory ? 'Regenerate' : 'Generate Story'),
                ),
        ],
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.story, required this.onTap});
  final Story story;
  final VoidCallback onTap;

  String get _monthLabel {
    final parts = story.monthKey.split('-');
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthIndex = int.tryParse(parts[1]) ?? 1;
    return '${months[monthIndex.clamp(1, 12)]} ${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen 3 illustration banner — shown when available
            if (story.illustrationUrl != null)
              SizedBox(
                width: double.infinity,
                height: 140,
                child: Image.network(
                  story.illustrationUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    child: const Icon(Icons.image_outlined,
                        color: AppColors.textSecondary),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text(_monthLabel, style: AppTextStyles.title)),
                      const Icon(Icons.chevron_right,
                          color: AppColors.textSecondary),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    story.content.length > 120
                        ? '${story.content.substring(0, 120)}…'
                        : story.content,
                    style: AppTextStyles.bodySecondary,
                  ),
                  const SizedBox(height: 8),
                  Text('${story.memoryCount} memories',
                      style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoMemoriesState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_stories_outlined,
                size: 72,
                color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 24),
            const Text('Monthly Stories', style: AppTextStyles.title),
            const SizedBox(height: 8),
            Text(
              'Add some memories first, then generate a beautiful AI-written story of the month.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
