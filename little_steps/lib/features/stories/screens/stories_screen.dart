// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../baby/providers/baby_providers.dart';
import '../../baby/widgets/baby_switcher_sheet.dart';
import '../../memory/models/memory.dart';
import '../../memory/providers/memory_providers.dart';
import '../models/story.dart';
import '../providers/story_providers.dart';

class StoriesScreen extends ConsumerWidget {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(storiesProvider);
    final memories = ref.watch(memoriesProvider).valueOrNull ?? [];
    final generatingStatus = ref.watch(storyGeneratingStatusProvider);
    final isGenerating = generatingStatus != null;

    final months = memories
        .map((m) =>
            '${m.takenAt.year}-${m.takenAt.month.toString().padLeft(2, '0')}')
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final baby = ref.watch(currentBabyProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stories'),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Center(
            child: GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) => const BabySwitcherSheet(),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                backgroundImage: baby?.coverPhotoUrl != null
                    ? NetworkImage(baby!.coverPhotoUrl!)
                    : null,
                child: baby?.coverPhotoUrl == null
                    ? Text(
                        baby?.displayName.substring(0, 1).toUpperCase() ?? '?',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
      body: storiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stories) {
          if (months.isEmpty) {
            return const _NoMemoriesState();
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              _GenerateCard(
                currentMonthKey: months.first,
                isGenerating: isGenerating,
                generatingStatus: generatingStatus,
                onGenerate: () =>
                    _showPhotoSelector(context, ref, months.first),
              ),
              const SizedBox(height: 24),
              if (stories.isNotEmpty) ...[
                Text('Your Stories', style: AppTextStyles.title),
                const SizedBox(height: 12),
                ...stories.map((s) => _StoryCard(
                      story: s,
                      onTap: () => context.push('/stories/${s.id}'),
                      onDelete: () => _confirmDelete(context, ref, s),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }

  // ─── Step 1: Photo selection ─────────────────────────────────────────────

  Future<void> _showPhotoSelector(
      BuildContext context, WidgetRef ref, String monthKey) async {
    final memories = ref.read(memoriesProvider).valueOrNull ?? [];
    final monthMemories = memories.where((m) {
      final mKey =
          '${m.takenAt.year}-${m.takenAt.month.toString().padLeft(2, '0')}';
      return mKey == monthKey;
    }).toList();

    final parts = monthKey.split('-');
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthIndex = int.tryParse(parts[1]) ?? 1;
    final monthLabel = '${months[monthIndex.clamp(1, 12)]} ${parts[0]}';

    final selected = await showModalBottomSheet<List<Memory>>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StoryPhotoSelectorSheet(
        monthLabel: monthLabel,
        memories: monthMemories,
      ),
    );

    if (selected == null || selected.isEmpty) return;

    // ─── Step 2: User notes ─────────────────────────────────────────────────
    if (!context.mounted) return;
    final notes = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StoryNotesSheet(photoCount: selected.length),
    );

    // notes == null means user dismissed (cancelled) — also proceed with empty
    await _generate(context, ref, monthKey, selected, notes ?? '');
  }

  // ─── Generate ────────────────────────────────────────────────────────────

  Future<void> _generate(
    BuildContext context,
    WidgetRef ref,
    String monthKey,
    List<Memory> selectedMemories,
    String userNotes,
  ) async {
    final user = ref.read(currentUserProvider);
    final baby = ref.read(currentBabyProvider).valueOrNull;
    if (user?.familyId == null || baby == null) return;

    ref.read(storyGeneratingStatusProvider.notifier).state =
        'Starting AI analysis…';
    try {
      Story? result;
      await ref.read(storyRepositoryProvider).generateStory(
            familyId: user!.familyId!,
            babyId: baby.id,
            monthKey: monthKey,
            selectedMemories: selectedMemories,
            babyName: baby.displayName,
            userNotes: userNotes.trim().isEmpty ? null : userNotes.trim(),
            onStatusUpdate: (status) {
              ref.read(storyGeneratingStatusProvider.notifier).state = status;
            },
          ).then((s) => result = s);

      if (context.mounted && result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Story created!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.push('/stories/${result!.id}');
      }
    } catch (e) {
      debugPrint('Story generation failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Story generation failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      ref.read(storyGeneratingStatusProvider.notifier).state = null;
    }
  }

  // ─── Delete ──────────────────────────────────────────────────────────────

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Story story) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            .deleteStory(user!.familyId!, story.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Story deleted')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Could not delete: $e'),
                backgroundColor: AppColors.error),
          );
        }
      }
    }
  }
}

// ─── Generate Card ────────────────────────────────────────────────────────────

class _GenerateCard extends StatelessWidget {
  const _GenerateCard({
    required this.currentMonthKey,
    required this.isGenerating,
    required this.onGenerate,
    this.generatingStatus,
  });

  final String currentMonthKey;
  final bool isGenerating;
  final String? generatingStatus;
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
              Text('AI Photo Story',
                  style:
                      AppTextStyles.caption.copyWith(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 8),
          Text(_monthLabel,
              style: AppTextStyles.title
                  .copyWith(color: Colors.white, fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            'Select photos → add your notes → AI writes a vivid personal story',
            style:
                AppTextStyles.bodySecondary.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          if (isGenerating)
            _GeneratingIndicator(status: generatingStatus ?? 'Generating…')
          else
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
              ),
              onPressed: onGenerate,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Create Story with AI'),
            ),
        ],
      ),
    );
  }
}

class _GeneratingIndicator extends StatefulWidget {
  const _GeneratingIndicator({required this.status});
  final String status;

  @override
  State<_GeneratingIndicator> createState() => _GeneratingIndicatorState();
}

class _GeneratingIndicatorState extends State<_GeneratingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _fade = Tween<double>(begin: 0.5, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        FadeTransition(
          opacity: _fade,
          child: Text(widget.status,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// ─── Story Card ───────────────────────────────────────────────────────────────

class _StoryCard extends StatelessWidget {
  const _StoryCard(
      {required this.story, required this.onTap, required this.onDelete});

  final Story story;
  final VoidCallback onTap;
  final VoidCallback onDelete;

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
    return Dismissible(
      key: Key('story_${story.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.error, size: 28),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo strip — show up to 3 photos side by side
              if (story.photoUrls.isNotEmpty)
                SizedBox(
                  height: 120,
                  child: Row(
                    children: [
                      ...story.photoUrls.take(3).map((url) => Expanded(
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              height: 120,
                              errorBuilder: (ctx, err, stack) => Container(
                                color:
                                    AppColors.primary.withValues(alpha: 0.08),
                                child: const Icon(Icons.image_outlined,
                                    color: AppColors.textSecondary),
                              ),
                            ),
                          )),
                      // +N overlay if more than 3
                      if (story.photoUrls.length > 3)
                        Container(
                          width: 50,
                          color: Colors.black54,
                          child: Center(
                            child: Text(
                              '+${story.photoUrls.length - 3}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
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
                          child:
                              Text(story.title, style: AppTextStyles.title),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 20, color: AppColors.textSecondary),
                          tooltip: 'Delete story',
                          onPressed: onDelete,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 4),
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
                    Row(
                      children: [
                        Text('${story.memoryCount} photos',
                            style: AppTextStyles.caption),
                        const SizedBox(width: 8),
                        Text('·', style: AppTextStyles.caption),
                        const SizedBox(width: 8),
                        Text(_monthLabel, style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── No Memories State ────────────────────────────────────────────────────────

class _NoMemoriesState extends StatelessWidget {
  const _NoMemoriesState();

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
            const Text('AI Photo Stories', style: AppTextStyles.title),
            const SizedBox(height: 8),
            Text(
              'Add some photos first, then AI will look at each one and write a vivid personal story.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── STEP 1: Photo Selector Sheet ─────────────────────────────────────────────

class StoryPhotoSelectorSheet extends StatefulWidget {
  const StoryPhotoSelectorSheet({
    super.key,
    required this.monthLabel,
    required this.memories,
  });

  final String monthLabel;
  final List<Memory> memories;

  @override
  State<StoryPhotoSelectorSheet> createState() =>
      _StoryPhotoSelectorSheetState();
}

class _StoryPhotoSelectorSheetState extends State<StoryPhotoSelectorSheet> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.memories.map((m) => m.id).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Step 1 of 2 — Select Photos',
                            style: AppTextStyles.title),
                        const SizedBox(height: 4),
                        Text(
                          'Choose photos for your story from ${widget.monthLabel}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedIds.length} of ${widget.memories.length} selected',
                    style: AppTextStyles.bodySecondary
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _selectedIds =
                            widget.memories.map((m) => m.id).toSet()),
                        child: const Text('All',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold)),
                      ),
                      TextButton(
                        onPressed: () =>
                            setState(() => _selectedIds.clear()),
                        child: Text('None',
                            style:
                                TextStyle(color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: widget.memories.isEmpty
                    ? Center(
                        child: Text('No photos found for this month',
                            style: AppTextStyles.bodySecondary))
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: widget.memories.length,
                        itemBuilder: (context, index) {
                          final memory = widget.memories[index];
                          final isSelected =
                              _selectedIds.contains(memory.id);
                          return GestureDetector(
                            onTap: () => setState(() {
                              if (isSelected) {
                                _selectedIds.remove(memory.id);
                              } else {
                                _selectedIds.add(memory.id);
                              }
                            }),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.divider,
                                        width: isSelected ? 2.5 : 1,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      child: Image.network(
                                        memory.thumbnailUrl,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.black
                                              .withValues(alpha: 0.35),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 1.5),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check,
                                            size: 13, color: Colors.white)
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _selectedIds.isEmpty
                    ? null
                    : () {
                        final selectedMemories = widget.memories
                            .where((m) => _selectedIds.contains(m.id))
                            .toList();
                        Navigator.of(context).pop(selectedMemories);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.divider,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: Text(
                  _selectedIds.isEmpty
                      ? 'Select at least 1 photo'
                      : 'Next — Add Your Notes (${_selectedIds.length} photos)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── STEP 2: User Notes Sheet ─────────────────────────────────────────────────

class StoryNotesSheet extends StatefulWidget {
  const StoryNotesSheet({super.key, required this.photoCount});
  final int photoCount;

  @override
  State<StoryNotesSheet> createState() => _StoryNotesSheetState();
}

class _StoryNotesSheetState extends State<StoryNotesSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus the text field after sheet opens
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 24, 20, 20 + bottomPadding),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Step 2 of 2 — Add Context',
                          style: AppTextStyles.title),
                      const SizedBox(height: 4),
                      Text(
                        'Tell AI more about these ${widget.photoCount} photos (optional but makes a richer story)',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(''),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Examples row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                "Bubu's first bath",
                "First time at grandma's",
                "Birthday celebration",
                "Playing in the park",
              ].map((example) => GestureDetector(
                    onTap: () {
                      _controller.text = example;
                      _controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: example.length),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(20),
                        color: AppColors.primary.withValues(alpha: 0.06),
                      ),
                      child: Text(
                        example,
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  )).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLines: 5,
              minLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText:
                    "e.g. This was Bubu's first day home from the hospital. Grandma was visiting. It was a rainy Sunday morning.",
                hintStyle: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                    fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).pop(''), // skip notes
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Skip'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pop(_controller.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Generate Story',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
