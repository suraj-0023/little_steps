import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../models/app_user.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return _fetchOrCreateUser(firebaseUser);
    });
  }

  Future<AppUser> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final firebaseUser = userCredential.user!;
    return _fetchOrCreateUser(firebaseUser);
  }

  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    AppLogger.i('User signed out');
  }

  Future<void> updateFcmToken(String uid, String token) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'fcmToken': token});
  }

  Future<AppUser> _fetchOrCreateUser(User firebaseUser) async {
    final docRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(firebaseUser.uid);

    final doc = await docRef.get();

    if (doc.exists) {
      return AppUser.fromFirestore(doc.data()!, firebaseUser.uid);
    }

    // First sign-in — create the user document
    final newUser = AppUser(
      uid: firebaseUser.uid,
      displayName: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
      photoUrl: firebaseUser.photoURL ?? '',
      role: UserRole.admin,
    );

    await docRef.set(newUser.toFirestore());
    AppLogger.i('Created new user: ${firebaseUser.uid}');
    return newUser;
  }
}
