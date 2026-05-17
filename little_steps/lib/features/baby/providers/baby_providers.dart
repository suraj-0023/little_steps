import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/baby.dart';
import '../repositories/baby_repository.dart';

final babyRepositoryProvider = Provider<BabyRepository>((ref) {
  return BabyRepository();
});

final currentBabyProvider = StreamProvider<Baby?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.familyId == null || user.babyId == null) {
    return const Stream.empty();
  }
  return ref
      .watch(babyRepositoryProvider)
      .watchBaby(user.familyId!, user.babyId!);
});

// Generates a stable familyId for the current user session
final newFamilyIdProvider = Provider<String>((ref) => const Uuid().v4());
