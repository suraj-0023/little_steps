import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../constants/app_secrets.dart';
import '../utils/app_logger.dart';
import '../../features/memory/models/memory.dart';
import 'parent_profile_service.dart';

final geminiVisionServiceProvider = Provider<GeminiVisionService>((ref) => GeminiVisionService());

/// The result of analysing a single photo with Gemini Vision.
class PhotoAnalysis {
  const PhotoAnalysis({
    required this.memoryId,
    required this.takenAt,
    this.locationLabel,
    this.persons = const [],
    this.activity = '',
    this.location = '',
    this.visibleText = const [],
    this.emotions = const [],
    this.objects = const [],
  });

  final String memoryId;
  final DateTime takenAt;
  final String? locationLabel;
  final List<String> persons;
  final String activity;
  final String location;
  final List<String> visibleText;
  final List<String> emotions;
  final List<String> objects;
}

class GeminiVisionService {
  GeminiVisionService()
      : _model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: AppSecrets.geminiApiKey,
        );

  final GenerativeModel _model;

  static const _analysisPrompt = '''
Look at this photo carefully and return ONLY a valid JSON object (no markdown, no code fences, no extra text) with exactly these fields:
{
  "persons": ["describe each visible person in detail, e.g. 'newborn baby wrapped in black cloth, eyes closed, sleeping peacefully', 'woman with long dark hair smiling warmly, likely the mother'"],
  "activity": "one clear sentence: what is happening in this photo",
  "location": "describe the setting and background in detail",
  "visibleText": ["any text visible in the image: signs, labels, inscriptions, clothing text"],
  "emotions": ["emotional tones: e.g. 'tender love', 'joy', 'peaceful', 'proud'],
  "objects": ["notable objects: e.g. 'black cloth wrap', 'hospital bracelet', 'blanket'"]
}
''';

  /// Analyse a single photo — downloads bytes and sends to Gemini Vision.
  Future<PhotoAnalysis?> analyzePhoto(Memory memory) async {
    // Try photoUrl first, then thumbnailUrl as fallback
    final urls = [memory.photoUrl, memory.thumbnailUrl]
        .where((u) => u.isNotEmpty)
        .toSet()
        .toList();

    for (final url in urls) {
      try {
        AppLogger.i('Downloading image for analysis: ${memory.id}');
        final response = await http
            .get(Uri.parse(url),
                headers: {'Accept': 'image/*'})
            .timeout(const Duration(seconds: 45));

        if (response.statusCode != 200) {
          AppLogger.w('HTTP ${response.statusCode} for ${memory.id} from $url');
          continue;
        }

        final bytes = response.bodyBytes;
        if (bytes.length < 100) {
          AppLogger.w('Image too small (${bytes.length} bytes) for ${memory.id}');
          continue;
        }

        AppLogger.i(
            'Downloaded ${bytes.length} bytes for ${memory.id}, sending to Gemini Vision');

        final mimeType = _detectMimeType(bytes);
        final content = [
          Content.multi([
            TextPart(_analysisPrompt),
            DataPart(mimeType, bytes),
          ])
        ];

        final result = await _model
            .generateContent(content)
            .timeout(const Duration(seconds: 60));
        final text = result.text ?? '';

        AppLogger.i('Gemini Vision response for ${memory.id}: $text');

        if (text.isEmpty) {
          AppLogger.w('Empty response from Gemini Vision for ${memory.id}');
          continue;
        }

        final parsed = _parseJson(text);

        return PhotoAnalysis(
          memoryId: memory.id,
          takenAt: memory.takenAt,
          locationLabel: memory.location,
          persons: _toStringList(parsed['persons']),
          activity: parsed['activity'] as String? ?? '',
          location: parsed['location'] as String? ?? '',
          visibleText: _toStringList(parsed['visibleText']),
          emotions: _toStringList(parsed['emotions']),
          objects: _toStringList(parsed['objects']),
        );
      } catch (e) {
        AppLogger.e('Vision analysis error for ${memory.id} url=$url: $e');
      }
    }

    AppLogger.w('All URLs failed for ${memory.id}, returning null');
    return null;
  }

  /// Analyse memories sequentially (more reliable than parallel for large images).
  Future<List<PhotoAnalysis>> analyzePhotos(List<Memory> memories) async {
    final results = <PhotoAnalysis>[];
    for (final memory in memories) {
      final analysis = await analyzePhoto(memory);
      if (analysis != null) {
        results.add(analysis);
        AppLogger.i(
            'Analysed ${results.length}/${memories.length}: ${memory.id}');
      }
    }
    AppLogger.i(
        'Vision analysis complete: ${results.length}/${memories.length} succeeded');
    return results;
  }

  /// Generate a rich narrative story from photo analyses + known persons + user notes.
  Future<String> generateStoryFromAnalysis({
    required List<PhotoAnalysis> analyses,
    required List<Memory> memories,
    required String babyName,
    required List<String> knownPersonDisplayNames,
    String? userNotes,
  }) async {
    final sortedMemories = List<Memory>.from(memories)
      ..sort((a, b) => a.takenAt.compareTo(b.takenAt));

    final personsContext = knownPersonDisplayNames.isNotEmpty
        ? 'People known in this family — use their names/roles:\n'
            '${knownPersonDisplayNames.map((n) => '  • $n').join('\n')}\n\n'
        : '';

    final userContext = (userNotes != null && userNotes.trim().isNotEmpty)
        ? 'IMPORTANT CONTEXT PROVIDED BY THE FAMILY:\n"${userNotes.trim()}"\n'
            'Incorporate this context naturally and prominently into the story.\n\n'
        : '';

    final photoDescriptions = StringBuffer();
    for (var i = 0; i < sortedMemories.length; i++) {
      final m = sortedMemories[i];
      final a = analyses.where((x) => x.memoryId == m.id).firstOrNull;

      photoDescriptions.writeln('📷 PHOTO ${i + 1} — ${_formatDate(m.takenAt)}');
      if (m.location != null && m.location!.isNotEmpty) {
        photoDescriptions.writeln('  Location: ${m.location}');
      }
      if (m.caption != null && m.caption!.isNotEmpty) {
        photoDescriptions.writeln('  Photo Description/Caption: ${m.caption}');
      }
      if (m.tags.isNotEmpty) {
        photoDescriptions.writeln('  Tags/Objects in photo: ${m.tags.join(', ')}');
      }
      if (a != null) {
        if (a.persons.isNotEmpty) {
          photoDescriptions.writeln('  People visible: ${a.persons.join(' | ')}');
        }
        if (a.activity.isNotEmpty && a.activity != m.caption) {
          photoDescriptions.writeln("  Scene activity: ${a.activity}");
        }
        if (a.visibleText.isNotEmpty) {
          photoDescriptions.writeln('  Text inside image: ${a.visibleText.join(', ')}');
        }
        if (a.emotions.isNotEmpty) {
          photoDescriptions.writeln('  Emotional tone: ${a.emotions.join(', ')}');
        }
      }
      photoDescriptions.writeln();
    }

    final startDate = sortedMemories.isNotEmpty ? _formatDate(sortedMemories.first.takenAt) : 'recently';
    final endDate =
        sortedMemories.isNotEmpty && sortedMemories.length > 1 ? _formatDate(sortedMemories.last.takenAt) : startDate;
    final dateRange = startDate == endDate ? startDate : '$startDate to $endDate';

    final parentProfilesContext = await ParentProfileService().getProfilesPromptSummary();

    final prompt = '''
You are a warm, literary storyteller writing a deeply personal memory book entry for a baby named $babyName.

$userContext$personsContext$parentProfilesContext
These are your observations from ${sortedMemories.isEmpty ? 'some' : sortedMemories.length.toString()} photos taken $dateRange:

$photoDescriptions

Write a beautiful, vivid, emotionally rich narrative in 3–4 flowing paragraphs. 

STRICT RULES:
- Use $babyName's name naturally (not every sentence — vary it)
- Reference people by name or role where mentioned above
- Warm, intimate, literary memoir tone — like a beautiful letter written directly to $babyName
- DO NOT use these phrases: "precious moments", "special memories", "cherish forever", "time flies"
- Output ONLY the story — no title, no headings, no labels, no bullet points
- Avoid awkward, clinical, or overly detailed visual descriptions of unrecognized people in the photos (e.g. describing them as "someone with teeth out", "a person in a black shirt", or listing their clothing details). 
- If the faces are not recognized, keep it simple and natural: use the FAMILY MEMBER VISUAL PROFILES clues to deduce if they are the parent(s) or loved ones, and describe the scene in warm relationship terms (e.g. "held in your father's arms", "resting against your mother's shoulder", "surrounded by family") instead of focusing on their raw clothes/features.
''';

    try {
      AppLogger.i('Sending story generation prompt to Gemini (${prompt.length} chars)');
      final result = await _model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 90));
      final text = result.text?.trim();
      AppLogger.i(
          'Story generated: ${text?.length ?? 0} chars');
      if (text != null && text.length > 50) return text;
      AppLogger.w('Story response too short, using enhanced fallback');
    } catch (e) {
      AppLogger.e('Story generation failed: $e');
    }

    return _enhancedFallback(babyName, userNotes, sortedMemories);
  }

  Future<String> refineStory(String currentContent, String babyName) async {
    final parentProfilesContext = await ParentProfileService().getProfilesPromptSummary();
    final prompt = '''
You are a warm, literary storyteller. A parent has written or drafted this memory story for their baby, $babyName.
Please rewrite and polish the story to make it sound more beautiful, emotional, warm, and flowing, like a literary memoir or a love letter to the baby.

$parentProfilesContext
STRICT RULES:
- Preserve all specific facts, dates, names, and events.
- Keep the narrative perspective (writing directly to $babyName, or about $babyName).
- Output ONLY the polished story content — no intro, no outro, no title, no code fences.
- Maintain a warm, premium, emotional tone.
- Keep descriptions of people warm and natural. Use the family member visual profiles to verify roles/names.

Current story content:
$currentContent
''';

    try {
      AppLogger.i('Sending story refinement prompt to Gemini');
      final result = await _model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 45));
      final text = result.text?.trim();
      if (text != null && text.length > 50) return text;
    } catch (e) {
      AppLogger.e('Story refinement failed: $e');
    }
    return currentContent;
  }

  String _enhancedFallback(
      String babyName, String? userNotes, List<Memory> memories) {
    final notes = userNotes?.trim() ?? '';
    final photoBriefs = <String>[];
    for (final m in memories) {
      final dateStr = _formatDate(m.takenAt);
      final captionStr = m.caption != null && m.caption!.isNotEmpty ? ' ("${m.caption}")' : '';
      final tagsStr = m.tags.isNotEmpty ? ' (showing ${m.tags.take(3).join(', ')})' : '';
      photoBriefs.add('• On $dateStr, we captured a photo$captionStr$tagsStr.');
    }

    final buffer = StringBuffer();
    buffer.writeln('Dear $babyName,');
    buffer.writeln();
    if (notes.isNotEmpty) {
      buffer.writeln('This month, we set out to write a story about your days, keeping in mind: "$notes".');
      buffer.writeln();
    }
    buffer.writeln(
        'Looking back at these moments, our hearts are filled with a warmth that words can scarcely describe. '
        'We look at the pictures and the timeline of your growth, and we are reminded of how quickly these precious days unfold.');
    buffer.writeln();
    
    if (photoBriefs.isNotEmpty) {
      buffer.writeln('Here are the moments we cherish from this month:\n');
      buffer.writeln(photoBriefs.join('\n'));
      buffer.writeln();
    }
    
    buffer.writeln(
        'Every smile, every quiet sleep, and every small discovery is a treasure. We hope that when you read this '
        'many years from now, you can feel the deep love and joy that filled our home during this time. You are '
        'the center of our world, and we love you more than all the words in the universe.\n\nAlways,\nYour Family');
    
    return buffer.toString();
  }

  String _detectMimeType(Uint8List bytes) {
    if (bytes.length > 4) {
      if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
        return 'image/jpeg';
      }
      if (bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        return 'image/png';
      }
      if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
        return 'image/gif';
      }
      if (bytes[0] == 0x49 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x2A &&
          bytes[3] == 0x00) {
        return 'image/tiff';
      }
      if (bytes[0] == 0x4D &&
          bytes[1] == 0x4D &&
          bytes[2] == 0x00 &&
          bytes[3] == 0x2A) {
        return 'image/tiff';
      }
    }
    return 'image/jpeg';
  }

  Map<String, dynamic> _parseJson(String text) {
    var cleanText = text.trim();
    if (cleanText.startsWith('```')) {
      final lines = cleanText.split('\n');
      if (lines.first.startsWith('```')) {
        lines.removeAt(0);
      }
      if (lines.isNotEmpty && lines.last.startsWith('```')) {
        lines.removeLast();
      }
      cleanText = lines.join('\n').trim();
    }
    try {
      return json.decode(cleanText) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.e('Failed to parse Gemini response as JSON: $e');
      return const {};
    }
  }

  List<String> _toStringList(dynamic val) {
    if (val is List) {
      return val.map((e) => e.toString()).toList();
    }
    return const [];
  }

  String _formatDate(DateTime date) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month.clamp(1, 12)]} ${date.day}, ${date.year}';
  }

  /// Generates a beautiful HTML layout representing a scrapbook page for the selected memories.
  Future<String> generateScrapbookHtml({
    required List<Memory> memories,
    required String babyName,
    required String themeName,
    required List<Uint8List> compressedImageBytes,
  }) async {
    final photoDescriptions = StringBuffer();
    final List<Part> contentParts = [];

    contentParts.add(TextPart('''
You are a master digital scrapbook designer. Design a gorgeous single-page HTML scrapbook layout matching the style of the "$themeName" theme for a baby named $babyName.

STYLING THEMES:
- "Vintage Scrapbook": warm cream background (#FAF0DC), cursive or elegant serif typography, polaroid borders around photos, dotted borders, gold outlines, handwritten notes style, decorative text elements.
- "Dreamy Pastel": soft pink, lavender, and light blue backgrounds (#FFF0F5, #E6E6FA), rounded borders (border-radius: 20px), cute bubble headings, Nunito sans-serif font.
- "Modern Minimalist": crisp white/light gray background (#FFFFFF, #F9F9F9), uppercase tracked titles, clean sharp-cornered grids, minimal spacing, thin black/gray dividers.
- "Earthy Forest": sage green and taupe backgrounds (#F2F4F2, #E3E8E3), warm serif fonts (Lora), double thin leaf/plant motif borders, classic layout.

HTML & CSS GUIDELINES:
- Output ONLY a valid self-contained HTML page starting with `<!DOCTYPE html>` and containing all CSS inside a `<style>` tag in the `<head>`.
- Use a single responsive layout container designed to fit beautifully on a standard A4 portrait sheet (approx. 794px width by 1123px height).
- For the images, use `src="IMAGE_PLACEHOLDER_0"`, `src="IMAGE_PLACEHOLDER_1"`, etc. corresponding to the order of images provided. Make sure to size the images properly so they look balanced and fit the A4 page layout without overflowing.
- DO NOT output any explanations, markdown code fences (like ```html), or conversational text. Return ONLY the HTML code.

AI WRITING GUIDELINES:
- Rewrite and expand the image captions to sound warm, literary, relatable, and poetic, matching the selected theme.
- You have full freedom to reorganize the captions, combine them into a single cohesive narrative story, or lay them out as individual styled scrapbook entries.
- Ensure the details are reliable and consistent with what is visible in the photos.
'''));

    for (var i = 0; i < memories.length; i++) {
      final m = memories[i];
      final bytes = compressedImageBytes[i];
      final mimeType = _detectMimeType(bytes);
      
      photoDescriptions.writeln('📷 PHOTO ${i + 1} (Placeholder: IMAGE_PLACEHOLDER_$i) — Taken on: ${_formatDate(m.takenAt)}');
      if (m.caption != null && m.caption!.isNotEmpty) {
        photoDescriptions.writeln('  Caption: ${m.caption}');
      }
      if (m.location != null && m.location!.isNotEmpty) {
        photoDescriptions.writeln('  Location: ${m.location}');
      }
      photoDescriptions.writeln();

      contentParts.add(DataPart(mimeType, bytes));
    }

    contentParts.add(TextPart('''
Here are the descriptions and the photos for the album:
$photoDescriptions

Please write the HTML code block now.
'''));

    try {
      AppLogger.i('Sending scrapbook HTML generation prompt to Gemini (${contentParts.length} parts)');
      final response = await _model.generateContent([
        Content.multi(contentParts),
      ]).timeout(const Duration(seconds: 90));
      
      var html = response.text ?? '';
      
      // Clean up markdown block markers if Gemini returned them despite instructions
      html = html.trim();
      if (html.startsWith('```')) {
        final lines = html.split('\n');
        if (lines.first.startsWith('```')) {
          lines.removeAt(0);
        }
        if (lines.isNotEmpty && lines.last.startsWith('```')) {
          lines.removeLast();
        }
        html = lines.join('\n').trim();
      }
      
      AppLogger.i('Scrapbook HTML generated successfully: ${html.length} chars');
      return html;
    } catch (e) {
      AppLogger.e('Scrapbook HTML generation failed', e);
      rethrow;
    }
  }
}
