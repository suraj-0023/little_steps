import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/app_logger.dart';

class ParentProfileService {
  Future<File> _getProfileFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/parent_profiles.json');
  }

  Future<Map<String, dynamic>> loadProfiles() async {
    try {
      final file = await _getProfileFile();
      if (!await file.exists()) {
        // Return default structure if it doesn't exist
        return {
          'profiles': [
            {
              'role': 'Mother',
              'name': '',
              'details': '',
            },
            {
              'role': 'Father',
              'name': '',
              'details': '',
            }
          ]
        };
      }
      final content = await file.readAsString();
      return json.decode(content) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.e('Failed to load parent profiles: $e');
      return {'profiles': []};
    }
  }

  Future<void> saveProfiles(Map<String, dynamic> data) async {
    try {
      final file = await _getProfileFile();
      await file.writeAsString(json.encode(data));
      AppLogger.i('Parent profiles saved successfully.');
    } catch (e) {
      AppLogger.e('Failed to save parent profiles: $e');
    }
  }

  Future<String> getProfilesPromptSummary() async {
    try {
      final data = await loadProfiles();
      final List<dynamic> profiles = data['profiles'] ?? [];
      final valid = profiles.where((p) {
        final details = (p['details'] as String? ?? '').trim();
        return details.isNotEmpty;
      }).toList();

      if (valid.isEmpty) return '';

      final buffer = StringBuffer();
      buffer.writeln('FAMILY MEMBER VISUAL PROFILES (Use these clues to identify the parents/loved ones in the photos):');
      for (final p in valid) {
        final role = p['role'] ?? 'Parent';
        final name = p['name'] ?? '';
        final nameStr = name.toString().trim().isNotEmpty ? ' ($name)' : '';
        final details = p['details'];
        buffer.writeln('- $role$nameStr: $details');
      }
      buffer.writeln();
      return buffer.toString();
    } catch (e) {
      AppLogger.e('Failed to format parent profiles summary: $e');
      return '';
    }
  }
}

final parentProfileServiceProvider = Provider<ParentProfileService>((ref) => ParentProfileService());
