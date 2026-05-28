import 'exif_data.dart';

class Memory {
  const Memory({
    required this.id,
    required this.familyId,
    required this.photoUrl,
    required this.thumbnailUrl,
    required this.takenAt,
    required this.uploadedBy,
    required this.createdAt,
    this.tags = const [],
    this.caption,
    this.location,
    this.exif,
    this.voiceNoteUrl,
    this.showInTimeline = true,
  });

  final String id;
  final String familyId;
  final String photoUrl;
  final String thumbnailUrl;
  final DateTime takenAt;
  final String uploadedBy;
  final DateTime createdAt;
  final List<String> tags;
  final String? caption;
  final String? location;
  final ExifData? exif;
  final String? voiceNoteUrl;
  final bool showInTimeline;

  factory Memory.fromFirestore(Map<String, dynamic> data, String id) {
    return Memory(
      id: id,
      familyId: data['familyId'] as String,
      photoUrl: data['photoUrl'] as String,
      thumbnailUrl: data['thumbnailUrl'] as String? ?? data['photoUrl'] as String,
      takenAt: DateTime.parse(data['takenAt'] as String),
      uploadedBy: data['uploadedBy'] as String,
      createdAt: DateTime.parse(data['createdAt'] as String),
      tags: List<String>.from(data['tags'] as List? ?? []),
      caption: data['caption'] as String?,
      location: data['location'] as String?,
      exif: data['exif'] != null
          ? ExifData.fromMap(Map<String, dynamic>.from(data['exif'] as Map))
          : null,
      voiceNoteUrl: data['voiceNoteUrl'] as String?,
      showInTimeline: data['showInTimeline'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'familyId': familyId,
        'photoUrl': photoUrl,
        'thumbnailUrl': thumbnailUrl,
        'takenAt': takenAt.toIso8601String(),
        'uploadedBy': uploadedBy,
        'createdAt': createdAt.toIso8601String(),
        'tags': tags,
        'showInTimeline': showInTimeline,
        if (caption != null) 'caption': caption,
        if (location != null) 'location': location,
        if (exif != null) 'exif': exif!.toMap(),
        if (voiceNoteUrl != null) 'voiceNoteUrl': voiceNoteUrl,
      };

  Memory copyWith({
    String? caption,
    List<String>? tags,
    String? location,
    String? voiceNoteUrl,
    bool? showInTimeline,
  }) {
    return Memory(
      id: id,
      familyId: familyId,
      photoUrl: photoUrl,
      thumbnailUrl: thumbnailUrl,
      takenAt: takenAt,
      uploadedBy: uploadedBy,
      createdAt: createdAt,
      tags: tags ?? this.tags,
      caption: caption ?? this.caption,
      location: location ?? this.location,
      exif: exif,
      voiceNoteUrl: voiceNoteUrl ?? this.voiceNoteUrl,
      showInTimeline: showInTimeline ?? this.showInTimeline,
    );
  }
}
