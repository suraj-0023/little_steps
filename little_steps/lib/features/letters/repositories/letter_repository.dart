import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart' as enc;
import '../../../core/constants/app_constants.dart';
import '../models/letter.dart';

class LetterRepository {
  final _db = FirebaseFirestore.instance;

  // Derives a 32-byte AES key from the familyId (padded/truncated)
  enc.Key _keyFor(String familyId) {
    final padded = familyId.replaceAll('-', '').padRight(32, '0');
    return enc.Key.fromUtf8(padded.substring(0, 32));
  }

  String encryptBody(String plainText, String familyId, String ivBase64) {
    final key = _keyFor(familyId);
    final iv = enc.IV.fromBase64(ivBase64);
    final encrypter = enc.Encrypter(enc.AES(key));
    return encrypter.encrypt(plainText, iv: iv).base64;
  }

  String decryptBody(String cipherBase64, String familyId, String ivBase64) {
    final key = _keyFor(familyId);
    final iv = enc.IV.fromBase64(ivBase64);
    final encrypter = enc.Encrypter(enc.AES(key));
    return encrypter.decrypt64(cipherBase64, iv: iv);
  }

  String generateIv() => enc.IV.fromSecureRandom(16).base64;

  Stream<List<Letter>> watchLetters(String familyId) {
    return _db
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.lettersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Letter.fromFirestore(d.data(), d.id)).toList());
  }

  Future<void> saveLetter(String familyId, Letter letter) async {
    await _db
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.lettersCollection)
        .doc(letter.id)
        .set(letter.toFirestore());
  }

  Future<void> deleteLetter(String familyId, String letterId) async {
    await _db
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.lettersCollection)
        .doc(letterId)
        .delete();
  }
}
