import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../memory/providers/memory_providers.dart';
import '../models/milestone.dart';
import '../repositories/milestone_repository.dart';

final milestoneRepositoryProvider =
    Provider<MilestoneRepository>((ref) => MilestoneRepository());

final milestonesProvider = StreamProvider<List<Milestone>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.familyId == null) return const Stream.empty();
  return ref
      .watch(milestoneRepositoryProvider)
      .watchMilestones(user!.familyId!);
});

// Combined timeline items sorted by date descending
final timelineProvider = Provider<List<_TimelineEntry>>((ref) {
  final memories = ref.watch(memoriesProvider).valueOrNull ?? [];
  final milestones = ref.watch(milestonesProvider).valueOrNull ?? [];

  final items = <_TimelineEntry>[
    ...memories.map((m) => _TimelineEntry.memory(m.takenAt, m.id)),
    ...milestones.map((m) => _TimelineEntry.milestone(m.achievedAt, m.id)),
  ]..sort((a, b) => b.date.compareTo(a.date));

  return items;
});

class _TimelineEntry {
  const _TimelineEntry.memory(this.date, this.id) : isMilestone = false;
  const _TimelineEntry.milestone(this.date, this.id) : isMilestone = true;
  final DateTime date;
  final String id;
  final bool isMilestone;
}
