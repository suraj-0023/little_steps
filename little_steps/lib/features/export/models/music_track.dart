class MusicTrack {
  final String id;
  final String title;
  final String artist;
  final String audioUrl;
  final String previewUrl;
  final int durationSeconds;
  final String licenseName;
  final String sourceApi; // 'ccmixter', 'jamendo'

  const MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    required this.previewUrl,
    required this.durationSeconds,
    required this.licenseName,
    required this.sourceApi,
  });

  factory MusicTrack.fromCcMixter(Map<String, dynamic> json) {
    // ccMixter returns a list of upload information
    // audio url is typically in json['files'][i]['download_url'] or similar.
    final uploadId = json['upload_id']?.toString() ?? '';
    final name = json['upload_name']?.toString() ?? 'Unknown Track';
    final artistName = json['user_real_name']?.toString() ?? 
                       json['artist_name']?.toString() ?? 
                       json['user_name']?.toString() ?? 'Unknown Artist';
    
    // Find the mp3 file
    String audio = '';
    String preview = '';
    if (json['files'] is List) {
      for (var f in json['files']) {
        final format = f['file_format']?.toString() ?? '';
        final url = f['download_url']?.toString() ?? '';
        if (format == 'mp3' || url.endsWith('.mp3')) {
          audio = url;
          preview = url;
          break;
        }
      }
    }
    
    final license = json['license_name']?.toString() ?? 'Creative Commons';
    
    return MusicTrack(
      id: 'ccmixter_$uploadId',
      title: name,
      artist: artistName,
      audioUrl: audio,
      previewUrl: preview,
      durationSeconds: 180, // ccMixter API doesn't always return precise seconds
      licenseName: license,
      sourceApi: 'ccmixter',
    );
  }

  factory MusicTrack.fromJamendo(Map<String, dynamic> json) {
    final trackId = json['id']?.toString() ?? '';
    final name = json['name']?.toString() ?? 'Unknown Track';
    final artistName = json['artist_name']?.toString() ?? 'Unknown Artist';
    
    // Use 'audiodownload' — the permanent publicly accessible download URL.
    // The 'audio' field is a streaming URL that returns 403 when fetched without session tokens.
    final audioDownload = json['audiodownload']?.toString() ?? '';
    // Fallback chain: audiodownload > audio (streaming, may fail)
    final audio = audioDownload.isNotEmpty ? audioDownload : (json['audio']?.toString() ?? '');
    
    final duration = json['duration'] != null ? int.tryParse(json['duration'].toString()) ?? 180 : 180;
    final license = json['license_ccurl']?.toString() ?? 'Creative Commons';

    return MusicTrack(
      id: 'jamendo_$trackId',
      title: name,
      artist: artistName,
      audioUrl: audio,
      previewUrl: audio, // Use same downloadable URL for preview
      durationSeconds: duration,
      licenseName: license.replaceAll('http://creativecommons.org/licenses/', 'CC ').replaceAll('/', '').toUpperCase(),
      sourceApi: 'jamendo',
    );
  }
}
