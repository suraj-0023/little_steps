import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/baby.dart';
import '../providers/baby_providers.dart';

const _selectedBabyBox = 'prefs';
const _selectedBabyKey = 'selectedBabyId';

// All babies in the family — used for multi-baby switcher
final allBabiesProvider = StreamProvider<List<Baby>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.familyId == null) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection(AppConstants.familiesCollection)
      .doc(user!.familyId)
      .collection(AppConstants.babiesCollection)
      .orderBy('createdAt')
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => Baby.fromFirestore(d.data(), d.id))
          .toList());
});

// Safe Hive box accessor — box must be opened in main() before any provider runs
Box _prefsBox() => Hive.box(_selectedBabyBox);

// The currently selected baby id (persisted in Hive)
class SelectedBabyNotifier extends Notifier<String?> {
  @override
  String? build() {
    final user = ref.watch(currentUserProvider);
    // Box is guaranteed open because main() calls Hive.openBox('prefs') before runApp()
    final saved = _prefsBox().get(_selectedBabyKey) as String?;
    return saved ?? user?.babyId;
  }

  Future<void> select(String babyId) async {
    state = babyId;
    await _prefsBox().put(_selectedBabyKey, babyId);
  }
}

final selectedBabyIdProvider =
    NotifierProvider<SelectedBabyNotifier, String?>(SelectedBabyNotifier.new);

// Override currentBabyProvider to use selectedBabyId
final activeBabyProvider = StreamProvider<Baby?>((ref) {
  final user = ref.watch(currentUserProvider);
  final babyId = ref.watch(selectedBabyIdProvider);
  if (user?.familyId == null || babyId == null) return const Stream.empty();
  return ref.watch(babyRepositoryProvider).watchBaby(user!.familyId!, babyId);
});
