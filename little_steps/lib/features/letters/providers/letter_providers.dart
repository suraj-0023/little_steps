import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/letter.dart';
import '../repositories/letter_repository.dart';

final letterRepositoryProvider = Provider<LetterRepository>((ref) {
  return LetterRepository();
});

final lettersProvider = StreamProvider<List<Letter>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.familyId == null) return const Stream.empty();
  return ref.watch(letterRepositoryProvider).watchLetters(user!.familyId!);
});
