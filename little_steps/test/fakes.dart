import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/mockito.dart';
import 'package:little_steps/core/services/gemini_vision_service.dart';
import 'package:flutter_image_compress_platform_interface/flutter_image_compress_platform_interface.dart';
import 'package:cross_file/cross_file.dart';

class FakeUser extends Fake implements User {
  FakeUser({
    required this.uid,
    this.email = 'test@example.com',
    this.displayName = 'Test User',
    this.photoURL = 'https://example.com/test.jpg',
  });

  @override
  final String uid;
  @override
  final String? email;
  @override
  final String? displayName;
  @override
  final String? photoURL;
}

class FakeUserCredential extends Fake implements UserCredential {
  FakeUserCredential({required this.user});

  @override
  final User? user;
}

class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  FakeFirebaseAuth({User? currentUser}) : _currentUser = currentUser {
    _controller = StreamController<User?>.broadcast();
    _controller.add(_currentUser);
  }

  User? _currentUser;
  late final StreamController<User?> _controller;

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<User?> authStateChanges() {
    final controller = StreamController<User?>();
    controller.add(_currentUser);
    final subscription = _controller.stream.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = () => subscription.cancel();
    return controller.stream;
  }

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    final user = FakeUser(uid: 'google_user_123');
    _currentUser = user;
    _controller.add(user);
    return FakeUserCredential(user: user);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  void triggerAuthStateChange(User? user) {
    _currentUser = user;
    _controller.add(user);
  }

  void dispose() {
    _controller.close();
  }
}

class FakeDocumentSnapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  FakeDocumentSnapshot(this._id, this._data, {this.existsValue = true});

  final String _id;
  final Map<String, dynamic>? _data;
  final bool existsValue;

  @override
  String get id => _id;

  @override
  bool get exists => existsValue;

  @override
  Map<String, dynamic>? data() => _data;
}

class FakeDocumentReference extends Fake implements DocumentReference<Map<String, dynamic>> {
  FakeDocumentReference(this.path, this._firestore) {
    _snapshotsController = StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();
  }

  @override
  final String path;
  final FakeFirebaseFirestore _firestore;
  late final StreamController<DocumentSnapshot<Map<String, dynamic>>> _snapshotsController;

  @override
  String get id => path.split('/').last;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    final data = _firestore.getData(path);
    return FakeDocumentSnapshot(id, data, existsValue: data != null);
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    _firestore.setData(path, data);
    _snapshotsController.add(FakeDocumentSnapshot(id, data));
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    final currentData = _firestore.getData(path) ?? {};
    final castedData = Map<String, dynamic>.from(data);
    final updatedData = {...currentData, ...castedData};
    _firestore.setData(path, updatedData);
    _snapshotsController.add(FakeDocumentSnapshot(id, updatedData));
  }

  @override
  Future<void> delete() async {
    _firestore.setData(path, null);
    _snapshotsController.add(FakeDocumentSnapshot(id, null, existsValue: false));
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    // Initial emit
    Timer.run(() {
      if (!_snapshotsController.isClosed) {
        final data = _firestore.getData(path);
        _snapshotsController.add(FakeDocumentSnapshot(id, data, existsValue: data != null));
      }
    });
    return _snapshotsController.stream;
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return FakeCollectionReference('$path/$collectionPath', _firestore);
  }
}

class FakeCollectionReference extends Fake implements CollectionReference<Map<String, dynamic>> {
  FakeCollectionReference(this._path, this._firestore);

  final String _path;
  final FakeFirebaseFirestore _firestore;

  @override
  String get path => _path;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    final docId = path ?? 'doc_${DateTime.now().millisecondsSinceEpoch}';
    final fullPath = '$_path/$docId';
    return _firestore.getDocRef(fullPath);
  }

  @override
  Future<DocumentReference<Map<String, dynamic>>> add(Map<String, dynamic> data) async {
    final docRef = doc();
    await docRef.set(data);
    return docRef;
  }
}

class FakeQueryDocumentSnapshot extends Fake implements QueryDocumentSnapshot<Map<String, dynamic>> {
  FakeQueryDocumentSnapshot(this._id, this._data);

  final String _id;
  final Map<String, dynamic> _data;

  @override
  String get id => _id;

  @override
  Map<String, dynamic> data() => _data;

  @override
  bool get exists => true;
}

class FakeQuerySnapshot extends Fake implements QuerySnapshot<Map<String, dynamic>> {
  FakeQuerySnapshot(this._docs);

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs;

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => _docs;
}

class FakeWriteBatch extends Fake implements WriteBatch {
  FakeWriteBatch(this._firestore);

  final FakeFirebaseFirestore _firestore;
  final List<Future<void> Function()> _operations = [];

  @override
  void set<T>(DocumentReference<T> document, T data, [SetOptions? options]) {
    _operations.add(() async {
      await (document as DocumentReference<Map<String, dynamic>>).set(data as Map<String, dynamic>, options);
    });
  }

  @override
  void update(DocumentReference<Object?> document, Map<String, dynamic> data) {
    _operations.add(() async {
      await (document as DocumentReference<Map<String, dynamic>>).update(data);
    });
  }

  @override
  void delete(DocumentReference<Object?> document) {
    _operations.add(() async {
      await (document as DocumentReference<Map<String, dynamic>>).delete();
    });
  }

  @override
  Future<void> commit() async {
    for (final op in _operations) {
      await op();
    }
  }
}

class FakeFirebaseFirestore extends Fake implements FirebaseFirestore {
  final Map<String, Map<String, dynamic>> _db = {};
  final Map<String, FakeDocumentReference> _refs = {};

  void setData(String path, Map<String, dynamic>? data) {
    if (data == null) {
      _db.remove(path);
    } else {
      _db[path] = data;
    }
  }

  Map<String, dynamic>? getData(String path) => _db[path];

  FakeDocumentReference getDocRef(String path) {
    return _refs.putIfAbsent(path, () => FakeDocumentReference(path, this));
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return FakeCollectionReference(collectionPath, this);
  }

  @override
  WriteBatch batch() => FakeWriteBatch(this);
}

class FakeGoogleSignInAuthentication extends Fake implements GoogleSignInAuthentication {
  @override
  String get accessToken => 'access_token_123';
  @override
  String get idToken => 'id_token_123';
}

class FakeGoogleSignInAccount extends Fake implements GoogleSignInAccount {
  @override
  String get email => 'test@example.com';
  @override
  String get displayName => 'Test User';
  @override
  String get id => 'google_id_123';
  @override
  String? get photoUrl => 'https://example.com/test.jpg';

  @override
  Future<GoogleSignInAuthentication> get authentication async => FakeGoogleSignInAuthentication();
}

class FakeGoogleSignIn extends Fake implements GoogleSignIn {
  GoogleSignInAccount? _currentUser;
  bool _shouldCancel = false;

  void setShouldCancel(bool cancel) {
    _shouldCancel = cancel;
  }

  @override
  Future<GoogleSignInAccount?> signIn() async {
    if (_shouldCancel) return null;
    _currentUser = FakeGoogleSignInAccount();
    return _currentUser;
  }

  @override
  Future<GoogleSignInAccount?> signOut() async {
    _currentUser = null;
    return null;
  }
}

class FakeTaskSnapshot extends Fake implements TaskSnapshot {
  @override
  TaskState get state => TaskState.success;
}

class FakeUploadTask extends Fake implements UploadTask {
  final Future<TaskSnapshot> _future = Future.value(FakeTaskSnapshot());

  @override
  Future<S> then<S>(FutureOr<S> Function(TaskSnapshot) onValue, {Function? onError}) {
    return _future.then(onValue, onError: onError);
  }

  @override
  Future<TaskSnapshot> catchError(Function onError, {bool Function(Object)? test}) {
    return _future.catchError(onError, test: test);
  }

  @override
  Future<TaskSnapshot> whenComplete(FutureOr<void> Function() action) {
    return _future.whenComplete(action);
  }
}

class FakeReference extends Fake implements Reference {
  FakeReference(this._path, this._storage);

  final String _path;
  final FakeFirebaseStorage _storage;

  @override
  String get path => _path;

  @override
  Reference ref(String path) {
    return FakeReference('$_path/$path', _storage);
  }

  @override
  Reference child(String path) {
    return FakeReference('$_path/$path', _storage);
  }

  @override
  UploadTask putFile(dynamic file, [SettableMetadata? metadata]) {
    _storage.uploadedPaths.add(_path);
    return FakeUploadTask();
  }

  @override
  Future<String> getDownloadURL() async {
    return 'https://firebasestorage.googleapis.com/v0/b/mock/o/${Uri.encodeComponent(_path)}?alt=media';
  }

  @override
  Future<void> delete() async {
    _storage.uploadedPaths.remove(_path);
  }
}

class FakeFirebaseStorage extends Fake implements FirebaseStorage {
  final Set<String> uploadedPaths = {};

  @override
  Reference ref([String? path]) {
    return FakeReference(path ?? '', this);
  }
}

class FakeGeminiVisionService extends Fake implements GeminiVisionService {
  String? mockTranscription = 'Mocked audio transcription';

  @override
  Future<String?> transcribeAudio(dynamic audioFile) async {
    return mockTranscription;
  }
}

class FakeFlutterImageCompressPlatform extends Fake implements FlutterImageCompressPlatform {
  @override
  Future<XFile?> compressAndGetFile(
    String path,
    String targetPath, {
    int minWidth = 1920,
    int minHeight = 1080,
    int inSampleSize = 1,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
    int numberOfRetries = 5,
  }) async {
    return XFile(targetPath);
  }
}
