// ignore_for_file: use_build_context_synchronously
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_providers.dart';
import '../../baby/providers/baby_providers.dart';
import '../../baby/widgets/baby_switcher_sheet.dart';
import '../../memory/models/memory.dart';
import '../../memory/providers/memory_providers.dart';
import '../models/milestone.dart';
import '../providers/timeline_providers.dart';

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memories = ref.watch(memoriesProvider).valueOrNull ?? [];
    final milestones = ref.watch(milestonesProvider).valueOrNull ?? [];
    final user = ref.watch(currentUserProvider);

    final visibleMemories = memories.where((m) => m.showInTimeline).toList();
    final hiddenMemories = memories.where((m) => !m.showInTimeline).toList();

    final items = <_Item>[
      ...visibleMemories.map((m) => _Item(date: m.takenAt, memory: m)),
      ...milestones.map((m) => _Item(date: m.achievedAt, milestone: m)),
    ]..sort((a, b) => b.date.compareTo(a.date));

    final baby = ref.watch(currentBabyProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline'),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Center(
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (_) => const BabySwitcherSheet(),
                );
              },
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
        actions: [
          if (user?.familyId != null && hiddenMemories.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.visibility_off_outlined),
              tooltip: 'Hidden memories',
              onPressed: () => _showHiddenMemoriesSheet(
                context,
                ref,
                user!.familyId!,
              ),
            ),
        ],
      ),
      body: items.isEmpty
          ? _EmptyState(onAdd: () => context.push('/timeline/add-milestone'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 100), // Bottom padding for dock
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                final showHeader =
                    i == 0 || !_sameMonth(items[i - 1].date, item.date);
                
                // Alternate sides: even items show image/icon on the left, odd items show it on the right
                final isLeftImage = i % 2 == 0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showHeader) _MonthHeader(date: item.date),
                    const SizedBox(height: 12),
                    if (item.milestone != null)
                      TimelineItemRow(
                        isLeftImage: isLeftImage,
                        dotColor: item.milestone!.type.color,
                        imageWidget: Container(
                          width: 96,
                          height: 96,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: item.milestone!.type.color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            item.milestone!.type.emoji,
                            style: const TextStyle(fontSize: 34),
                          ),
                        ),
                        textWidget: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: !isLeftImage
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatDate(item.milestone!.achievedAt),
                                style: AppTextStyles.caption.copyWith(
                                  color: item.milestone!.type.color,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: !isLeftImage ? TextAlign.right : TextAlign.left,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.milestone!.title,
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                textAlign: !isLeftImage ? TextAlign.right : TextAlign.left,
                              ),
                              if (item.milestone!.note?.isNotEmpty == true) ...[
                                const SizedBox(height: 4),
                                Text(
                                  item.milestone!.note!,
                                  style: AppTextStyles.bodySecondary.copyWith(fontSize: 13),
                                  textAlign: !isLeftImage ? TextAlign.right : TextAlign.left,
                                ),
                              ],
                              const SizedBox(height: 8),
                              if (user?.familyId != null)
                                GestureDetector(
                                  onTap: () async {
                                    try {
                                      await ref
                                          .read(milestoneRepositoryProvider)
                                          .deleteMilestone(
                                              user!.familyId!, item.milestone!.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                              content: Text('Milestone deleted')),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                                'Failed to delete milestone'),
                                            backgroundColor: AppColors.error,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                    else if (item.memory != null)
                      TimelineItemRow(
                        isLeftImage: isLeftImage,
                        dotColor: AppColors.primary,
                        imageWidget: GestureDetector(
                          onTap: () => context.push('/memory/${item.memory!.id}'),
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.textPrimary.withValues(alpha: 0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: item.memory!.thumbnailUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Container(color: AppColors.shimmerBase),
                              ),
                            ),
                          ),
                        ),
                        textWidget: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: !isLeftImage
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatDate(item.memory!.takenAt),
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: !isLeftImage ? TextAlign.right : TextAlign.left,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.memory!.caption?.isNotEmpty == true
                                    ? item.memory!.caption!
                                    : (_generateDescriptionFromTags(item.memory!.tags) ?? 'Photo memory'),
                                style: AppTextStyles.body.copyWith(height: 1.3, fontSize: 13),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                textAlign: !isLeftImage ? TextAlign.right : TextAlign.left,
                              ),
                              if (item.memory!.tags.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  item.memory!.tags.take(3).join(' · '),
                                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                                  textAlign: !isLeftImage ? TextAlign.right : TextAlign.left,
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: !isLeftImage
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  if (!isLeftImage) ...[
                                    GestureDetector(
                                      onTap: () => _confirmHideMemory(
                                          context, ref, item.memory!, user!.familyId!),
                                      child: Text(
                                        'Hide',
                                        style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    GestureDetector(
                                      onTap: () => _showEditCaptionDialog(
                                          context, ref, item.memory!, user!.familyId!),
                                      child: Text(
                                        'Edit',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    GestureDetector(
                                      onTap: () => _showEditCaptionDialog(
                                          context, ref, item.memory!, user!.familyId!),
                                      child: Text(
                                        'Edit',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    GestureDetector(
                                      onTap: () => _confirmHideMemory(
                                          context, ref, item.memory!, user!.familyId!),
                                      child: Text(
                                        'Hide',
                                        style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11),
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80), // Offset from dock
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/timeline/add-milestone'),
          icon: const Icon(Icons.add),
          label: const Text('Add Milestone'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
        ),
      ),
    );
  }

  bool _sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  Future<void> _showEditCaptionDialog(
      BuildContext context, WidgetRef ref, Memory memory, String familyId) async {
    final initialText = memory.caption?.isNotEmpty == true
        ? memory.caption!
        : (_generateDescriptionFromTags(memory.tags) ?? '');
    final controller = TextEditingController(text: initialText);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.divider),
          ),
          title: Text(
            'Edit Description',
            style: AppTextStyles.title.copyWith(fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe this memory...',
                  hintStyle: AppTextStyles.bodySecondary,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    final aiCaption = _generateDescriptionFromTags(memory.tags);
                    if (aiCaption != null) {
                      controller.text = aiCaption;
                    }
                  },
                  icon: const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                  label: const Text(
                    'Generate description with AI',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final newCaption = controller.text.trim();
                await ref
                    .read(memoryRepositoryProvider)
                    .updateCaption(familyId, memory.id, newCaption);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Description updated')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmHideMemory(
      BuildContext context, WidgetRef ref, Memory memory, String familyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.divider),
          ),
          title: Text(
            'Hide from Timeline?',
            style: AppTextStyles.title.copyWith(fontSize: 18),
          ),
          content: const Text(
            'This image will be hidden from the timeline, but will remain visible in your main collage book.',
            style: AppTextStyles.bodySecondary,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Hide'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await ref
          .read(memoryRepositoryProvider)
          .updateMemoryTimelineVisibility(familyId, memory.id, false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hidden from timeline')),
        );
      }
    }
  }

  Future<void> _showHiddenMemoriesSheet(
      BuildContext context, WidgetRef ref, String familyId) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final memories = ref.watch(memoriesProvider).valueOrNull ?? [];
            final currentHidden = memories.where((m) => !m.showInTimeline).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hidden Memories',
                        style: AppTextStyles.title.copyWith(fontSize: 20),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'These photos are hidden from the timeline. Tap Unhide to restore them.',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: currentHidden.isEmpty
                        ? Center(
                            child: Text(
                              'No hidden memories',
                              style: AppTextStyles.bodySecondary,
                            ),
                          )
                        : ListView.builder(
                            itemCount: currentHidden.length,
                            itemBuilder: (context, index) {
                              final memory = currentHidden[index];
                              final captionText = memory.caption?.isNotEmpty == true
                                  ? memory.caption!
                                  : (_generateDescriptionFromTags(memory.tags) ?? 'Photo memory');
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                color: AppColors.card,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: AppColors.divider),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(8),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: memory.thumbnailUrl,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  title: Text(
                                    captionText,
                                    style: AppTextStyles.body.copyWith(fontSize: 13),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    _formatDate(memory.takenAt),
                                    style: AppTextStyles.caption,
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () async {
                                      await ref
                                          .read(memoryRepositoryProvider)
                                          .updateMemoryTimelineVisibility(familyId, memory.id, true);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Memory restored to timeline')),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.textPrimary,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text(
                                      'Unhide',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class TimelineItemRow extends StatelessWidget {
  const TimelineItemRow({
    super.key,
    required this.isLeftImage,
    required this.imageWidget,
    required this.textWidget,
    required this.dotColor,
  });

  final bool isLeftImage;
  final Widget imageWidget;
  final Widget textWidget;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left side (image or text)
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: isLeftImage ? imageWidget : textWidget,
              ),
            ),
          ),
          // Center line and dot
          SizedBox(
            width: 24,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 2,
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                Positioned(
                  top: 24, // Aligned with the center of the elements
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Right side (text or image)
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: isLeftImage ? textWidget : imageWidget,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Item {
  _Item({required this.date, this.memory, this.milestone});
  final DateTime date;
  final Memory? memory;
  final Milestone? milestone;
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.date});
  final DateTime date;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        '${_months[date.month - 1]} ${date.year}',
        style:
            AppTextStyles.title.copyWith(color: AppColors.primary, fontSize: 15),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline_outlined,
                size: 72,
                color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 24),
            const Text('Your timeline', style: AppTextStyles.title),
            const SizedBox(height: 8),
            Text(
              'Photos and milestones appear here in chronological order.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add first milestone'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
}

String? _generateDescriptionFromTags(List<String> tags) {
  if (tags.isEmpty) return null;
  
  final cleanTags = tags.map((t) => t.trim().toLowerCase()).toList();
  
  final hasBaby = cleanTags.contains('baby') || cleanTags.contains('child') || cleanTags.contains('infant') || cleanTags.contains('toddler');
  final hasSmile = cleanTags.contains('smiling') || cleanTags.contains('smile') || cleanTags.contains('happy');
  final hasPlay = cleanTags.contains('playing') || cleanTags.contains('play') || cleanTags.contains('toy');
  final hasSleep = cleanTags.contains('sleeping') || cleanTags.contains('sleep') || cleanTags.contains('nap');
  final hasEating = cleanTags.contains('eating') || cleanTags.contains('eat') || cleanTags.contains('food');
  
  final otherTags = cleanTags.where((t) => !['baby', 'child', 'infant', 'toddler', 'smiling', 'smile', 'happy', 'playing', 'play', 'toy', 'sleeping', 'sleep', 'nap', 'eating', 'eat', 'food', 'person'].contains(t)).toList();
  
  if (hasSleep) {
    return hasBaby 
        ? "A peaceful moment of baby sleeping soundly, lost in sweet dreams."
        : "A quiet, peaceful naptime moment.";
  }
  
  if (hasEating) {
    return hasBaby
        ? "Baby enjoying a delicious mealtime adventure, full of curiosity."
        : "A delightful mealtime moment.";
  }
  
  if (hasPlay && hasSmile) {
    return hasBaby
        ? "A joyful moment of baby smiling and playing happily."
        : "A happy play session filled with smiles.";
  }
  
  if (hasSmile) {
    if (otherTags.isNotEmpty) {
      return "A bright, smiling moment featuring ${otherTags.first}.";
    }
    return "A heartwarming smile that brightens up the day.";
  }
  
  if (hasPlay) {
    if (otherTags.isNotEmpty) {
      return "Baby having fun playing, exploring ${otherTags.first}.";
    }
    return "An active moment of play and exploration.";
  }
  
  if (otherTags.isNotEmpty) {
    final item = otherTags.first;
    return "A beautiful capture featuring a lovely view of $item.";
  }
  
  return "A precious memory captured to remember forever.";
}
