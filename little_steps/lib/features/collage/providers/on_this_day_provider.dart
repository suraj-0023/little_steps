import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../memory/models/memory.dart';
import '../../memory/providers/memory_providers.dart';

final onThisDayProvider = Provider<List<Memory>>((ref) {
  final memories = ref.watch(memoriesProvider).valueOrNull ?? [];
  final today = DateTime.now();
  return memories
      .where((m) =>
          m.takenAt.day == today.day &&
          m.takenAt.month == today.month &&
          m.takenAt.year != today.year)
      .toList();
});
