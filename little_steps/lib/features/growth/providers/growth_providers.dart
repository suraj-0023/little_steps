import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../baby/providers/baby_providers.dart';
import '../models/growth_entry.dart';
import '../repositories/growth_repository.dart';

final growthRepositoryProvider = Provider<GrowthRepository>((ref) {
  return GrowthRepository();
});

final growthEntriesProvider = StreamProvider<List<GrowthEntry>>((ref) {
  final user = ref.watch(currentUserProvider);
  final baby = ref.watch(currentBabyProvider).valueOrNull;
  if (user?.familyId == null || baby == null) return const Stream.empty();
  return ref
      .watch(growthRepositoryProvider)
      .watchEntries(user!.familyId!, baby.id);
});
