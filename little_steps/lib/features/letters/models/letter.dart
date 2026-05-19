class Letter {
  const Letter({
    required this.id,
    required this.familyId,
    required this.babyId,
    required this.authorId,
    required this.title,
    required this.encryptedBody,
    required this.iv,
    required this.createdAt,
    required this.unlockAt,
    this.isPublic = false,
  });

  final String id;
  final String familyId;
  final String babyId;
  final String authorId;
  final String title;
  final String encryptedBody;
  final String iv;
  final DateTime createdAt;
  final DateTime unlockAt;
  final bool isPublic;

  bool get isUnlocked => DateTime.now().isAfter(unlockAt);

  factory Letter.fromFirestore(Map<String, dynamic> data, String id) {
    return Letter(
      id: id,
      familyId: data['familyId'] as String,
      babyId: data['babyId'] as String,
      authorId: data['authorId'] as String,
      title: data['title'] as String,
      encryptedBody: data['encryptedBody'] as String,
      iv: data['iv'] as String,
      createdAt: DateTime.parse(data['createdAt'] as String),
      unlockAt: DateTime.parse(data['unlockAt'] as String),
      isPublic: data['isPublic'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'familyId': familyId,
        'babyId': babyId,
        'authorId': authorId,
        'title': title,
        'encryptedBody': encryptedBody,
        'iv': iv,
        'createdAt': createdAt.toIso8601String(),
        'unlockAt': unlockAt.toIso8601String(),
        'isPublic': isPublic,
      };
}
