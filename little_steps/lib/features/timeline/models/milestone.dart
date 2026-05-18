import 'package:flutter/material.dart';

enum MilestoneType {
  firstSmile,
  firstLaugh,
  firstWord,
  firstCrawl,
  firstSteps,
  firstTooth,
  firstFood,
  firstHaircut,
  firstBirthday,
  firstClap,
  firstWave,
  firstSleep,
  custom,
}

extension MilestoneTypeX on MilestoneType {
  String get label => switch (this) {
        MilestoneType.firstSmile => 'First Smile',
        MilestoneType.firstLaugh => 'First Laugh',
        MilestoneType.firstWord => 'First Word',
        MilestoneType.firstCrawl => 'First Crawl',
        MilestoneType.firstSteps => 'First Steps',
        MilestoneType.firstTooth => 'First Tooth',
        MilestoneType.firstFood => 'First Food',
        MilestoneType.firstHaircut => 'First Haircut',
        MilestoneType.firstBirthday => 'First Birthday',
        MilestoneType.firstClap => 'First Clap',
        MilestoneType.firstWave => 'First Wave',
        MilestoneType.firstSleep => 'Slept Through Night',
        MilestoneType.custom => 'Custom',
      };

  String get emoji => switch (this) {
        MilestoneType.firstSmile => '😊',
        MilestoneType.firstLaugh => '😂',
        MilestoneType.firstWord => '💬',
        MilestoneType.firstCrawl => '🐛',
        MilestoneType.firstSteps => '👣',
        MilestoneType.firstTooth => '🦷',
        MilestoneType.firstFood => '🥄',
        MilestoneType.firstHaircut => '✂️',
        MilestoneType.firstBirthday => '🎂',
        MilestoneType.firstClap => '👏',
        MilestoneType.firstWave => '👋',
        MilestoneType.firstSleep => '🌙',
        MilestoneType.custom => '⭐',
      };

  Color get color => switch (this) {
        MilestoneType.firstSmile => const Color(0xFFF5A623),
        MilestoneType.firstLaugh => const Color(0xFFFF6B6B),
        MilestoneType.firstWord => const Color(0xFF6C3FC5),
        MilestoneType.firstCrawl => const Color(0xFF4ECDC4),
        MilestoneType.firstSteps => const Color(0xFF45B7D1),
        MilestoneType.firstTooth => const Color(0xFF96CEB4),
        MilestoneType.firstFood => const Color(0xFFFF9F43),
        MilestoneType.firstHaircut => const Color(0xFFA29BFE),
        MilestoneType.firstBirthday => const Color(0xFFE84393),
        MilestoneType.firstClap => const Color(0xFF00B894),
        MilestoneType.firstWave => const Color(0xFF74B9FF),
        MilestoneType.firstSleep => const Color(0xFF2D3436),
        MilestoneType.custom => const Color(0xFF6C3FC5),
      };
}

class Milestone {
  const Milestone({
    required this.id,
    required this.familyId,
    required this.babyId,
    required this.type,
    required this.title,
    required this.achievedAt,
    this.note,
    this.photoUrl,
  });

  final String id;
  final String familyId;
  final String babyId;
  final MilestoneType type;
  final String title;
  final DateTime achievedAt;
  final String? note;
  final String? photoUrl;

  factory Milestone.fromFirestore(Map<String, dynamic> data, String id) {
    final typeStr = data['type'] as String? ?? 'custom';
    return Milestone(
      id: id,
      familyId: data['familyId'] as String,
      babyId: data['babyId'] as String,
      type: MilestoneType.values.firstWhere(
        (t) => t.name == typeStr,
        orElse: () => MilestoneType.custom,
      ),
      title: data['title'] as String,
      achievedAt: DateTime.parse(data['achievedAt'] as String),
      note: data['note'] as String?,
      photoUrl: data['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'familyId': familyId,
        'babyId': babyId,
        'type': type.name,
        'title': title,
        'achievedAt': achievedAt.toIso8601String(),
        if (note != null) 'note': note,
        if (photoUrl != null) 'photoUrl': photoUrl,
      };
}
