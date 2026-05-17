import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/memory.dart';
import '../repositories/memory_repository.dart';

final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  return MemoryRepository();
});

final memoriesProvider = StreamProvider<List<Memory>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.familyId == null) return const Stream.empty();
  return ref.watch(memoryRepositoryProvider).watchMemories(user!.familyId!);
});

// Groups memories by "MMMM yyyy" key, newest month first
final memoriesByMonthProvider = Provider<Map<String, List<Memory>>>((ref) {
  final memories = ref.watch(memoriesProvider).valueOrNull ?? [];
  final grouped = <String, List<Memory>>{};
  for (final memory in memories) {
    final key = _monthYearKey(memory.takenAt);
    grouped.putIfAbsent(key, () => []).add(memory);
  }
  return grouped;
});

String _monthYearKey(DateTime dt) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return '${months[dt.month - 1]} ${dt.year}';
}
