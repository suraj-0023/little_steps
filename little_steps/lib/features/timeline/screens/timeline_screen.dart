import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/app_shell.dart';
import '../../auth/providers/auth_providers.dart';
import '../../memory/models/memory.dart';
import '../../memory/providers/memory_providers.dart';
import '../models/milestone.dart';
import '../providers/timeline_providers.dart';
import '../widgets/milestone_card.dart';

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memories = ref.watch(memoriesProvider).valueOrNull ?? [];
    final milestones = ref.watch(milestonesProvider).valueOrNull ?? [];
    final user = ref.watch(currentUserProvider);

    final items = <_Item>[
      ...memories.map((m) => _Item(date: m.takenAt, memory: m)),
      ...milestones.map((m) => _Item(date: m.achievedAt, milestone: m)),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: AppShell.openDrawer,
        ),
      ),
      body: items.isEmpty
          ? _EmptyState(onAdd: () => context.push('/timeline/add-milestone'))
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                final showHeader =
                    i == 0 || !_sameMonth(items[i - 1].date, item.date);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showHeader) _MonthHeader(date: item.date),
                    if (item.milestone != null)
                      MilestoneCard(
                        milestone: item.milestone!,
                        onDelete: user?.familyId != null
                            ? () => ref
                                .read(milestoneRepositoryProvider)
                                .deleteMilestone(
                                    user!.familyId!, item.milestone!.id)
                            : null,
                      )
                    else if (item.memory != null)
                      _MemoryRow(
                        memory: item.memory!,
                        onTap: () =>
                            context.push('/memory/${item.memory!.id}'),
                      ),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/timeline/add-milestone'),
        icon: const Icon(Icons.add),
        label: const Text('Add Milestone'),
      ),
    );
  }

  bool _sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;
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

class _MemoryRow extends StatelessWidget {
  const _MemoryRow({required this.memory, required this.onTap});
  final Memory memory;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: memory.thumbnailUrl,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              Container(color: AppColors.shimmerBase),
        ),
      ),
      title: Text(
        memory.caption?.isNotEmpty == true
            ? memory.caption!
            : 'Photo · ${memory.takenAt.day}/${memory.takenAt.month}',
        style: AppTextStyles.body,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: memory.tags.isNotEmpty
          ? Text(memory.tags.take(3).join(' · '),
              style: AppTextStyles.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis)
          : null,
      onTap: onTap,
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
