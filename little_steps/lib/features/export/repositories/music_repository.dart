import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/music_track.dart';

class MusicRepository {
  final http.Client _client;
  MusicRepository({http.Client? client}) : _client = client ?? http.Client();

  // Jamendo Client ID - using standard public sandbox client ID
  static const _jamendoClientId = '56d30c95';

  Future<List<MusicTrack>> fetchCcMixterTracks({String query = '', String tag = ''}) async {
    final tags = ['instrumental'];
    if (tag.isNotEmpty) {
      tags.add(tag.toLowerCase());
    }
    
    final tagString = tags.join(',');
    // Use HTTPS for ccMixter
    var urlString = 'https://ccmixter.org/api/query?f=json&limit=20&tags=$tagString';
    if (query.isNotEmpty) {
      urlString += '&q=${Uri.encodeComponent(query)}';
    }
    
    try {
      final response = await _client.get(Uri.parse(urlString)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          try {
            return MusicTrack.fromCcMixter(item as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        }).whereType<MusicTrack>().where((t) => t.audioUrl.isNotEmpty).toList();
      }
    } catch (e) {
      // Fallback or log error
    }
    return [];
  }

  Future<List<MusicTrack>> fetchJamendoTracks({String query = '', String tag = ''}) async {
    // Request 'audiodownload' field — this is the permanent, publicly accessible download URL.
    // The standard 'audio' streaming URL requires session tokens and always returns 403 when downloaded.
    // We also filter by audiodownload_allowed=1 to only show tracks that can be downloaded.
    var urlString = 'https://api.jamendo.com/v3.0/tracks/?client_id=$_jamendoClientId'
        '&format=json&limit=20&audioformat=mp31'
        '&include=musicinfo&audiodownload_allowed=1';
    
    if (tag.isNotEmpty) {
      urlString += '&tags=${Uri.encodeComponent(tag.toLowerCase())}';
    }
    if (query.isNotEmpty) {
      urlString += '&search=${Uri.encodeComponent(query)}';
    } else {
      urlString += '&boost=popularity_month';
    }

    try {
      final response = await _client.get(Uri.parse(urlString)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic>? results = data['results'];
        if (results != null) {
          return results.map((item) {
            try {
              return MusicTrack.fromJamendo(item as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          }).whereType<MusicTrack>().where((t) => t.audioUrl.isNotEmpty).toList();
        }
      }
    } catch (e) {
      // Fallback or log error
    }
    return [];
  }

  Future<List<MusicTrack>> searchTracks({
    required String provider,
    String query = '',
    String tag = '',
  }) async {
    if (provider == 'jamendo') {
      return fetchJamendoTracks(query: query, tag: tag);
    } else {
      return fetchCcMixterTracks(query: query, tag: tag);
    }
  }
}

final musicRepositoryProvider = Provider<MusicRepository>((ref) {
  final repo = MusicRepository();
  ref.onDispose(() => repo._client.close());
  return repo;
});
