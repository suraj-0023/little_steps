class Story {
  const Story({
    required this.id,
    required this.familyId,
    required this.babyId,
    required this.monthKey,
    required this.title,
    required this.content,
    required this.generatedAt,
    this.photoUrls = const [],
    this.memoryCount = 0,
  });

  final String id;
  final String familyId;
  final String babyId;
  final String monthKey; // "2026-05"
  final String title;
  final String content;
  final DateTime generatedAt;
  final List<String> photoUrls;
  final int memoryCount;

  factory Story.fromFirestore(Map<String, dynamic> data, String id) {
    return Story(
      id: id,
      familyId: data['familyId'] as String,
      babyId: data['babyId'] as String,
      monthKey: data['monthKey'] as String,
      title: data['title'] as String,
      content: data['content'] as String,
      generatedAt: DateTime.parse(data['generatedAt'] as String),
      photoUrls: List<String>.from(data['photoUrls'] as List? ?? []),
      memoryCount: data['memoryCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'familyId': familyId,
        'babyId': babyId,
        'monthKey': monthKey,
        'title': title,
        'content': content,
        'generatedAt': generatedAt.toIso8601String(),
        'photoUrls': photoUrls,
        'memoryCount': memoryCount,
      };
}
