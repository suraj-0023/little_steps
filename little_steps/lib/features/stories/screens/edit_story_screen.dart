import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_providers.dart';
import '../../baby/providers/baby_providers.dart';
import '../providers/story_providers.dart';
import '../models/story.dart';
import '../../../core/services/gemini_vision_service.dart';
import '../../../core/utils/app_logger.dart';

class EditStoryScreen extends ConsumerStatefulWidget {
  const EditStoryScreen({super.key, required this.storyId});
  final String storyId;

  @override
  ConsumerState<EditStoryScreen> createState() => _EditStoryScreenState();
}

class _EditStoryScreenState extends ConsumerState<EditStoryScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stories = ref.watch(storiesProvider).valueOrNull ?? [];
    final story = stories.where((s) => s.id == widget.storyId).firstOrNull;
    final baby = ref.watch(currentBabyProvider).valueOrNull;
    final babyName = baby?.displayName ?? 'our baby';

    if (story == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_initialized) {
      _titleController.text = story.title;
      _contentController.text = story.content;
      _initialized = true;
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Edit Story', style: AppTextStyles.title),
        backgroundColor: AppColors.surface,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            )
          else
            TextButton(
              onPressed: () => _saveStory(story),
              child: Text(
                'Save',
                style: AppTextStyles.button.copyWith(color: AppColors.primaryDark),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title input
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Story Title',
                labelStyle: AppTextStyles.label.copyWith(color: AppColors.primaryDark),
                hintText: 'Enter a title for this story',
                hintStyle: AppTextStyles.bodySecondary,
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              style: AppTextStyles.storyTitle,
            ),
            const SizedBox(height: 20),
            // Content input
            TextField(
              controller: _contentController,
              maxLines: 15,
              minLines: 8,
              decoration: InputDecoration(
                labelText: 'Story Content',
                labelStyle: AppTextStyles.label.copyWith(color: AppColors.primaryDark),
                hintText: 'Write the story of your baby\'s month...',
                hintStyle: AppTextStyles.bodySecondary,
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              style: AppTextStyles.storyBody,
            ),
            const SizedBox(height: 24),
            // AI Action Button
            ElevatedButton.icon(
              onPressed: () => _improveWithAI(context, babyName),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.auto_awesome, size: 20),
              label: Text(
                'Improve with AI'.toUpperCase(),
                style: AppTextStyles.button.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _saveStory(story),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Save Changes'.toUpperCase(),
                style: AppTextStyles.button.copyWith(color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _saveStory(Story originalStory) async {
    final user = ref.read(currentUserProvider);
    if (user?.familyId == null) return;

    setState(() {
      _isSaving = true;
    });

    final updated = Story(
      id: originalStory.id,
      familyId: originalStory.familyId,
      babyId: originalStory.babyId,
      monthKey: originalStory.monthKey,
      title: _titleController.text.trim().isEmpty ? originalStory.title : _titleController.text.trim(),
      content: _contentController.text.trim(),
      generatedAt: originalStory.generatedAt,
      photoUrls: originalStory.photoUrls,
      memoryCount: originalStory.memoryCount,
      illustrationUrl: originalStory.illustrationUrl,
    );

    try {
      await ref.read(storyRepositoryProvider).updateStory(user!.familyId!, updated);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Story saved successfully')),
        );
      }
    } catch (e) {
      AppLogger.e('Failed to save story: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _improveWithAI(BuildContext context, String babyName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _AIImprovementModal(
          initialDraft: _contentController.text,
          babyName: babyName,
          onApply: (polishedText) {
            setState(() {
              _contentController.text = polishedText;
            });
          },
        );
      },
    );
  }
}

class _AIImprovementModal extends ConsumerStatefulWidget {
  const _AIImprovementModal({
    required this.initialDraft,
    required this.babyName,
    required this.onApply,
  });

  final String initialDraft;
  final String babyName;
  final ValueChanged<String> onApply;

  @override
  ConsumerState<_AIImprovementModal> createState() => _AIImprovementModalState();
}

class _AIImprovementModalState extends ConsumerState<_AIImprovementModal> with SingleTickerProviderStateMixin {
  late Future<String> _refineFuture;
  late AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _startRefinement();
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

  void _startRefinement() {
    _refineFuture = ref.read(geminiVisionServiceProvider).refineStory(
          widget.initialDraft,
          widget.babyName,
        );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: 24 + bottomPadding,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: FutureBuilder<String>(
        future: _refineFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),
                RotationTransition(
                  turns: _sparkleController,
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.primary,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Weaving your story…',
                  style: AppTextStyles.headline.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'AI is polishing your narrative to make it warm, emotional, and memorable.',
                    style: AppTextStyles.bodySecondary,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            );
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to Refine Story',
                  style: AppTextStyles.title,
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error?.toString() ?? 'Something went wrong',
                  style: AppTextStyles.bodySecondary,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _startRefinement();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('Retry'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          final polishedText = snapshot.data!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'AI Refined Version',
                    style: AppTextStyles.headline.copyWith(fontSize: 20),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Text(
                      polishedText,
                      style: AppTextStyles.storyBody,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _startRefinement();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Retry'.toUpperCase(),
                        style: AppTextStyles.button.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApply(polishedText);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Use This Text'.toUpperCase(),
                        style: AppTextStyles.button.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Keep Original Draft',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
