enum UserRole { admin, editor, contributor, viewer, child }

class AppUser {
  const AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.role,
    this.familyId,
    this.babyId,
    this.fcmToken,
  });

  final String uid;
  final String displayName;
  final String email;
  final String photoUrl;
  final UserRole role;
  final String? familyId;
  final String? babyId;
  final String? fcmToken;

  bool get hasFamily => familyId != null && familyId!.isNotEmpty;

  factory AppUser.fromFirestore(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == (data['role'] as String?),
        orElse: () => UserRole.viewer,
      ),
      familyId: data['familyId'] as String?,
      babyId: data['babyId'] as String?,
      fcmToken: data['fcmToken'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
        'role': role.name,
        if (familyId != null) 'familyId': familyId,
        if (babyId != null) 'babyId': babyId,
        if (fcmToken != null) 'fcmToken': fcmToken,
      };

  AppUser copyWith({
    String? displayName,
    String? email,
    String? photoUrl,
    UserRole? role,
    String? familyId,
    String? babyId,
    String? fcmToken,
  }) {
    return AppUser(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      familyId: familyId ?? this.familyId,
      babyId: babyId ?? this.babyId,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
