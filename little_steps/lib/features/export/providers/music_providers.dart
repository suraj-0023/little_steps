import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/music_track.dart';
import '../repositories/music_repository.dart';

/// The active API source ('ccmixter' or 'jamendo')
final musicApiProvider = StateProvider<String>((ref) => 'ccmixter');

/// The active search query text
final musicQueryProvider = StateProvider<String>((ref) => '');

/// The active genre/tag filter (e.g. 'lullaby', 'happy', 'calm')
final musicTagProvider = StateProvider<String>((ref) => 'Lullaby');

/// Async provider to query tracks based on selected API, query, and tag filters
final musicTracksProvider = FutureProvider.autoDispose<List<MusicTrack>>((ref) async {
  final api = ref.watch(musicApiProvider);
  final query = ref.watch(musicQueryProvider);
  final tag = ref.watch(musicTagProvider);
  final repository = ref.watch(musicRepositoryProvider);

  // Map user-friendly tags to appropriate API tags
  String apiTag = tag;
  if (tag == 'Lullaby') {
    apiTag = api == 'jamendo' ? 'lullaby' : 'lullaby';
  } else if (tag == 'Happy') {
    apiTag = api == 'jamendo' ? 'happy' : 'happy';
  } else if (tag == 'Calm') {
    apiTag = api == 'jamendo' ? 'ambient' : 'ambient';
  } else if (tag == 'Playful') {
    apiTag = api == 'jamendo' ? 'playful' : 'playful';
  } else if (tag == 'Acoustic') {
    apiTag = api == 'jamendo' ? 'acoustic' : 'acoustic';
  }

  return repository.searchTracks(
    provider: api,
    query: query,
    tag: apiTag,
  );
});

/// The selected background track for the compiled video reel
final selectedMusicTrackProvider = StateProvider<MusicTrack?>((ref) => null);
