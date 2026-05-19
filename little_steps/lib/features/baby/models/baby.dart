class Baby {
  const Baby({
    required this.id,
    required this.familyId,
    required this.name,
    required this.createdAt,
    this.dob,
    this.nickname,
    this.isUnborn = false,
    this.expectedDeliveryDate,
    this.coverPhotoUrl,
    this.useNicknameDisplay = false,
  });

  final String id;
  final String familyId;
  final String name;
  final DateTime? dob;
  final String? nickname;
  final bool isUnborn;
  final DateTime? expectedDeliveryDate;
  final DateTime createdAt;
  final String? coverPhotoUrl;
  final bool useNicknameDisplay;

  String get firstName => name.split(' ').first;

  /// The name shown throughout the app — respects the family's display preference.
  String get displayName {
    if (useNicknameDisplay && nickname != null && nickname!.isNotEmpty) {
      return nickname!;
    }
    return firstName;
  }

  factory Baby.fromFirestore(Map<String, dynamic> data, String id) {
    return Baby(
      id: id,
      familyId: data['familyId'] as String,
      name: data['name'] as String,
      dob: data['dob'] != null ? DateTime.parse(data['dob'] as String) : null,
      nickname: data['nickname'] as String?,
      isUnborn: data['isUnborn'] as bool? ?? false,
      expectedDeliveryDate: data['expectedDeliveryDate'] != null
          ? DateTime.parse(data['expectedDeliveryDate'] as String)
          : null,
      createdAt: DateTime.parse(data['createdAt'] as String),
      coverPhotoUrl: data['coverPhotoUrl'] as String?,
      useNicknameDisplay: data['useNicknameDisplay'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'familyId': familyId,
        'name': name,
        if (dob != null) 'dob': dob!.toIso8601String(),
        if (nickname != null) 'nickname': nickname,
        'isUnborn': isUnborn,
        if (expectedDeliveryDate != null)
          'expectedDeliveryDate': expectedDeliveryDate!.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        if (coverPhotoUrl != null) 'coverPhotoUrl': coverPhotoUrl,
        'useNicknameDisplay': useNicknameDisplay,
      };

  Baby copyWith({
    String? name,
    DateTime? dob,
    String? nickname,
    bool? isUnborn,
    DateTime? expectedDeliveryDate,
    String? coverPhotoUrl,
    bool? useNicknameDisplay,
  }) {
    return Baby(
      id: id,
      familyId: familyId,
      name: name ?? this.name,
      dob: dob ?? this.dob,
      nickname: nickname ?? this.nickname,
      isUnborn: isUnborn ?? this.isUnborn,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      createdAt: createdAt,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      useNicknameDisplay: useNicknameDisplay ?? this.useNicknameDisplay,
    );
  }
}
