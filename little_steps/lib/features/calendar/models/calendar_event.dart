class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.familyId,
    required this.title,
    required this.date,
    required this.category,
    this.description = '',
    this.amount,
    required this.createdAt,
  });

  final String id;
  final String familyId;
  final String title;
  final String description;
  final DateTime date;
  final String category; // 'activity', 'health', 'vaccination', 'expenditure', 'target', 'birthday', 'other'
  final double? amount; // For expenditures
  final DateTime createdAt;

  factory CalendarEvent.fromFirestore(Map<String, dynamic> data, String id) {
    return CalendarEvent(
      id: id,
      familyId: data['familyId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      date: DateTime.parse(data['date'] as String),
      category: data['category'] as String? ?? 'other',
      amount: data['amount'] != null ? (data['amount'] as num).toDouble() : null,
      createdAt: DateTime.parse(data['createdAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'familyId': familyId,
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'category': category,
        if (amount != null) 'amount': amount,
        'createdAt': createdAt.toIso8601String(),
      };

  CalendarEvent copyWith({
    String? title,
    String? description,
    DateTime? date,
    String? category,
    double? amount,
  }) {
    return CalendarEvent(
      id: id,
      familyId: familyId,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      createdAt: createdAt,
    );
  }
}
