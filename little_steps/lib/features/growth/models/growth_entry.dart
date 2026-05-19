class GrowthEntry {
  const GrowthEntry({
    required this.id,
    required this.familyId,
    required this.babyId,
    required this.date,
    required this.createdAt,
    this.heightCm,
    this.weightKg,
    this.note,
  });

  final String id;
  final String familyId;
  final String babyId;
  final DateTime date;
  final DateTime createdAt;
  final double? heightCm;
  final double? weightKg;
  final String? note;

  factory GrowthEntry.fromFirestore(Map<String, dynamic> data, String id) {
    return GrowthEntry(
      id: id,
      familyId: data['familyId'] as String,
      babyId: data['babyId'] as String,
      date: DateTime.parse(data['date'] as String),
      createdAt: DateTime.parse(data['createdAt'] as String),
      heightCm: (data['heightCm'] as num?)?.toDouble(),
      weightKg: (data['weightKg'] as num?)?.toDouble(),
      note: data['note'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'familyId': familyId,
        'babyId': babyId,
        'date': date.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        if (heightCm != null) 'heightCm': heightCm,
        if (weightKg != null) 'weightKg': weightKg,
        if (note != null) 'note': note,
      };
}
