import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/story.dart';
import '../repositories/story_repository.dart';

final storyRepositoryProvider =
    Provider<StoryRepository>((ref) => StoryRepository());

final storiesProvider = StreamProvider<List<Story>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.familyId == null) return const Stream.empty();
  return ref.watch(storyRepositoryProvider).watchStories(user!.familyId!);
});

/// Nullable status string — null means not generating.
/// Non-null value is the current step description shown in the UI.
final storyGeneratingStatusProvider =
    StateProvider.autoDispose<String?>((ref) => null);

/// Kept for backwards compatibility (derived from status provider)
final storyGeneratingProvider =
    Provider.autoDispose<bool>((ref) =>
        ref.watch(storyGeneratingStatusProvider) != null);
