import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/app_logger.dart';
import '../models/person.dart';

class PersonRepository {
  PersonRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _personsCollection = 'persons';

  CollectionReference<Map<String, dynamic>> _col(String familyId) =>
      _firestore
          .collection('families')
          .doc(familyId)
          .collection(_personsCollection);

  Stream<List<Person>> watchPersons(String familyId) {
    return _col(familyId)
        .orderBy('firstSeenAt')
        .snapshots()
        .map((s) => s.docs.map((d) => Person.fromFirestore(d.data(), d.id)).toList());
  }

  /// Match raw AI-detected descriptions against known persons.
  /// Creates new Person documents for unrecognised ones.
  /// Returns the full list of matched/created persons.
  Future<List<Person>> mergePersons(
      String familyId, List<String> rawDescriptions) async {
    if (rawDescriptions.isEmpty) return [];

    final snap = await _col(familyId).get();
    final existing = snap.docs
        .map((d) => Person.fromFirestore(d.data(), d.id))
        .toList();

    final result = <Person>[];

    for (final desc in rawDescriptions) {
      final descLower = desc.toLowerCase();

      // Fuzzy match: if any keyword in the new description overlaps with an
      // existing person's description, treat them as the same person.
      Person? matched;
      for (final known in existing) {
        final knownWords = known.description.toLowerCase().split(RegExp(r'\W+'));
        final descWords = descLower.split(RegExp(r'\W+'));
        final overlap = knownWords.toSet().intersection(descWords.toSet());
        // Require at least 2 meaningful overlapping words (skip stop words)
        final meaningful = overlap
            .where((w) =>
                w.length > 3 &&
                !{'with', 'that', 'this', 'from', 'they', 'have'}.contains(w))
            .length;
        if (meaningful >= 2) {
          matched = known;
          break;
        }
      }

      if (matched != null) {
        // Increment appears-in count
        await _col(familyId)
            .doc(matched.id)
            .update({'appearsInCount': matched.appearsInCount + 1});
        result.add(matched.copyWith(appearsInCount: matched.appearsInCount + 1));
      } else {
        // New person — create document
        final ref = _col(familyId).doc();
        final person = Person(
          id: ref.id,
          familyId: familyId,
          description: desc,
          firstSeenAt: DateTime.now(),
        );
        await ref.set(person.toFirestore());
        existing.add(person);
        result.add(person);
        AppLogger.i('New person stored: $desc');
      }
    }

    return result;
  }

  Future<void> updatePersonName(
      String familyId, String personId, String name) async {
    await _col(familyId).doc(personId).update({'resolvedName': name});
  }
}
