class Baby {
  const Baby({
    required this.id,
    required this.familyId,
    required this.name,
    required this.dob,
    required this.createdAt,
    this.coverPhotoUrl,
  });

  final String id;
  final String familyId;
  final String name;
  final DateTime dob;
  final DateTime createdAt;
  final String? coverPhotoUrl;

  String get firstName => name.split(' ').first;

  factory Baby.fromFirestore(Map<String, dynamic> data, String id) {
    return Baby(
      id: id,
      familyId: data['familyId'] as String,
      name: data['name'] as String,
      dob: DateTime.parse(data['dob'] as String),
      createdAt: DateTime.parse(data['createdAt'] as String),
      coverPhotoUrl: data['coverPhotoUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'familyId': familyId,
        'name': name,
        'dob': dob.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        if (coverPhotoUrl != null) 'coverPhotoUrl': coverPhotoUrl,
      };

  Baby copyWith({
    String? name,
    DateTime? dob,
    String? coverPhotoUrl,
  }) {
    return Baby(
      id: id,
      familyId: familyId,
      name: name ?? this.name,
      dob: dob ?? this.dob,
      createdAt: createdAt,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
    );
  }
}
