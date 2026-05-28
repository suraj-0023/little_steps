class Person {
  const Person({
    required this.id,
    required this.familyId,
    required this.description,
    this.resolvedName,
    required this.firstSeenAt,
    this.appearsInCount = 1,
  });

  final String id;
  final String familyId;

  /// Raw AI description e.g. "woman with dark curly hair, likely mother"
  final String description;

  /// User-assigned name e.g. "Priya (Mom)" — null until user labels them
  final String? resolvedName;

  final DateTime firstSeenAt;
  final int appearsInCount;

  /// Display name: resolved name if set, otherwise description
  String get displayName => resolvedName ?? description;

  factory Person.fromFirestore(Map<String, dynamic> data, String id) {
    return Person(
      id: id,
      familyId: data['familyId'] as String,
      description: data['description'] as String,
      resolvedName: data['resolvedName'] as String?,
      firstSeenAt: DateTime.parse(data['firstSeenAt'] as String),
      appearsInCount: data['appearsInCount'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'familyId': familyId,
        'description': description,
        if (resolvedName != null) 'resolvedName': resolvedName,
        'firstSeenAt': firstSeenAt.toIso8601String(),
        'appearsInCount': appearsInCount,
      };

  Person copyWith({
    String? resolvedName,
    int? appearsInCount,
  }) {
    return Person(
      id: id,
      familyId: familyId,
      description: description,
      resolvedName: resolvedName ?? this.resolvedName,
      firstSeenAt: firstSeenAt,
      appearsInCount: appearsInCount ?? this.appearsInCount,
    );
  }
}
