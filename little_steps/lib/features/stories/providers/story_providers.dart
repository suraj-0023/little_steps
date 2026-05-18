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

final storyGeneratingProvider =
    StateProvider.autoDispose<bool>((ref) => false);
