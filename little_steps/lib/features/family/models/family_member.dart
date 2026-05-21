import '../../auth/models/app_user.dart';

class FamilyMember {
  const FamilyMember({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
    required this.role,
    required this.joinedAt,
  });

  final String uid;
  final String displayName;
  final String photoUrl;
  final UserRole role;
  final DateTime joinedAt;

  bool get hasPhoto => photoUrl.isNotEmpty;

  String get initials {
    final parts = displayName.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  factory FamilyMember.fromFirestore(Map<String, dynamic> data) {
    return FamilyMember(
      uid: data['uid'] as String,
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == (data['role'] as String? ?? 'viewer'),
        orElse: () => UserRole.viewer,
      ),
      joinedAt: DateTime.parse(data['joinedAt'] as String),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'role': role.name,
        'joinedAt': joinedAt.toIso8601String(),
      };
}
