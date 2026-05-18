import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/family_member.dart';
import '../repositories/family_repository.dart';

final familyRepositoryProvider =
    Provider<FamilyRepository>((ref) => FamilyRepository());

final familyMembersProvider = StreamProvider<List<FamilyMember>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.familyId == null) return const Stream.empty();
  return ref
      .watch(familyRepositoryProvider)
      .watchMembers(user!.familyId!);
});
