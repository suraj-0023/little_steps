import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

// Output size for vertical reel (portrait 9:16)
const int _outputWidth = 720;
const int _outputHeight = 1280;

class ReelCompilerService {
  final http.Client _client = http.Client();

  /// HTTP GET with redirect following and a browser User-Agent header.
  Future<http.Response> _getWithRedirects(String url) async {
    final headers = {
      'User-Agent':
          'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1',
    };

    var currentUrl = url;
    for (var i = 0; i < 6; i++) {
      final response = await _client
          .get(Uri.parse(currentUrl), headers: headers)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) return response;
      if ([301, 302, 307, 308].contains(response.statusCode)) {
        final location = response.headers['location'];
        if (location == null) return response;
        if (location.startsWith('/')) {
          final uri = Uri.parse(currentUrl);
          currentUrl = '${uri.scheme}://${uri.host}$location';
        } else {
          currentUrl = location;
        }
      } else {
        return response;
      }
    }
    throw Exception('Too many redirects for URL: $url');
  }

  /// Generates an MP4 reel from [imageUrls] with background [audioUrl].
  ///
  /// Uses the FFmpeg `-loop 1` + `filter_complex concat` approach which:
  /// - Handles images of different dimensions by scaling/padding each one
  /// - Produces a correctly timed video without needing a concat demuxer file
  Future<String> generateReel({
    required List<String> imageUrls,
    required String audioUrl,
    required double slideDuration,
    required Function(double progress, String stage) onProgress,
  }) async {
    try {
      await WakelockPlus.enable();
      onProgress(0.02, 'Preparing workspace...');

      final tempDir = await getTemporaryDirectory();
      final reelId = DateTime.now().millisecondsSinceEpoch.toString();
      final workDir = Directory('${tempDir.path}/reel_$reelId');
      await workDir.create(recursive: true);

      // ── Step 1: Download audio ───────────────────────────────────────────
      onProgress(0.05, 'Downloading soundtrack...');
      final audioFile = File('${workDir.path}/audio.aac');
      bool audioOk = false;

      try {
        final res = await _getWithRedirects(audioUrl);
        if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
          await audioFile.writeAsBytes(res.bodyBytes);
          audioOk = true;
          debugPrint('[ReelCompiler] Audio downloaded OK (${res.bodyBytes.length} bytes)');
        } else {
          debugPrint('[ReelCompiler] Audio HTTP ${res.statusCode} for $audioUrl');
        }
      } catch (e) {
        debugPrint('[ReelCompiler] Audio download error: $e');
      }

      if (!audioOk) {
        // Fallback: generate a silent AAC track (libmp3lame unavailable in ffmpeg_kit)
        onProgress(0.07, 'Generating silent soundtrack...');
        final totalSeconds = (imageUrls.length * slideDuration).ceil();
        final silentSession = await FFmpegKit.execute(
          '-y -f lavfi -i anullsrc=r=44100:cl=stereo '
          '-t $totalSeconds -c:a aac -b:a 128k '
          '"${audioFile.path}"',
        );
        final silentCode = await silentSession.getReturnCode();
        if (!ReturnCode.isSuccess(silentCode)) {
          debugPrint('[ReelCompiler] Silent audio generation failed: '
              '${await silentSession.getLogsAsString()}');
        } else {
          audioOk = true;
        }
      }

      // ── Step 2: Download & normalise images ──────────────────────────────
      final List<String> localImagePaths = [];
      final int total = imageUrls.length;

      for (int i = 0; i < total; i++) {
        final pct = 0.08 + (i / total) * 0.40;
        onProgress(pct, 'Processing photo ${i + 1}/$total...');

        try {
          final rawRes = await _getWithRedirects(imageUrls[i]);
          if (rawRes.statusCode != 200 || rawRes.bodyBytes.isEmpty) {
            debugPrint('[ReelCompiler] Photo $i HTTP ${rawRes.statusCode}, skipping');
            continue;
          }

          // Write raw download
          final rawFile = File('${workDir.path}/raw_$i.jpg');
          await rawFile.writeAsBytes(rawRes.bodyBytes);

          // Compress to keep memory manageable (target 720p width)
          final compFile = File('${workDir.path}/img_$i.jpg');
          final compressed = await FlutterImageCompress.compressAndGetFile(
            rawFile.path,
            compFile.path,
            minWidth: _outputWidth,
            minHeight: _outputHeight,
            quality: 82,
            keepExif: false,
          );

          final finalPath = compressed?.path ?? rawFile.path;
          localImagePaths.add(finalPath);
          debugPrint('[ReelCompiler] Photo $i ready: $finalPath');

          // Delete raw if we have a compressed version
          if (compressed != null && await rawFile.exists()) {
            await rawFile.delete();
          }
        } catch (e) {
          debugPrint('[ReelCompiler] Photo $i error: $e — skipping');
        }
      }

      if (localImagePaths.isEmpty) {
        throw Exception(
          'None of the selected photos could be downloaded. '
          'Please check your internet connection and try again.',
        );
      }

      // ── Step 3: Build FFmpeg command ─────────────────────────────────────
      //
      // Strategy: use one `-loop 1 -t <duration> -i <image>` input per photo,
      // then a filter_complex that:
      //   (a) scales + pads each image to exactly $_outputWidth x $_outputHeight
      //   (b) concatenates all the video streams
      //
      // This is the most reliable method for still-image video generation
      // because it doesn't require a concat demuxer file and handles
      // mixed image dimensions automatically.
      //
      onProgress(0.50, 'Building video timeline...');

      final outputPath = '${workDir.path}/reel_output.mp4';
      final n = localImagePaths.length;

      // Build input arguments
      final inputArgs = StringBuffer();
      for (final path in localImagePaths) {
        inputArgs.write('-loop 1 -t $slideDuration -i "$path" ');
      }

      // Add audio input (last)
      inputArgs.write('-i "${audioFile.path}" ');

      // Build filter_complex:
      // Each video stream [i:v] → scale=720:1280 (pad to fit) → setsar → fps → [vi]
      // Then concat all [v0][v1]...[vN-1]concat=n=N:v=1:a=0[outv]
      final filterBuf = StringBuffer();
      for (int i = 0; i < n; i++) {
        filterBuf.write(
          '[$i:v]scale=$_outputWidth:$_outputHeight:'
          'force_original_aspect_ratio=decrease,'
          'pad=$_outputWidth:$_outputHeight:(ow-iw)/2:(oh-ih)/2:color=black,'
          'setsar=1,fps=25[v$i];',
        );
      }
      final concatInputs = List.generate(n, (i) => '[v$i]').join('');
      filterBuf.write('${concatInputs}concat=n=$n:v=1:a=0[outv]');

      // Map indices: video streams are 0..(n-1), audio is n
      final audioMapIndex = n;

      final ffmpegCmd = '${inputArgs.toString()}'
          '-filter_complex "${filterBuf.toString()}" '
          '-map "[outv]" -map ${audioMapIndex}:a '
          '-c:v libx264 -profile:v baseline -level 3.1 '
          '-pix_fmt yuv420p -c:a aac -b:a 128k -shortest '
          '-movflags +faststart '
          '-y "$outputPath"';

      debugPrint('[ReelCompiler] Running FFmpeg:\n$ffmpegCmd');

      // ── Step 4: Execute FFmpeg ───────────────────────────────────────────
      onProgress(0.55, 'Rendering video reel...');

      final totalDurationMs = n * slideDuration * 1000.0;
      FFmpegKitConfig.enableStatisticsCallback((stats) {
        final timeMs = stats.getTime().toDouble();
        if (totalDurationMs > 0) {
          final enc = (timeMs / totalDurationMs).clamp(0.0, 1.0);
          onProgress(0.55 + enc * 0.40,
              'Encoding (${(enc * 100).toInt()}%)...');
        }
      });

      final session = await FFmpegKit.execute(ffmpegCmd);
      FFmpegKitConfig.enableStatisticsCallback(null);

      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        final outFile = File(outputPath);
        final size = await outFile.length();
        debugPrint('[ReelCompiler] ✅ Success — output $size bytes at $outputPath');
        onProgress(1.0, 'Your reel is ready!');
        return outputPath;
      } else {
        final logs = await session.getLogsAsString();
        debugPrint('[ReelCompiler] ❌ FFmpeg failed:\n$logs');
        throw Exception(
          'Video rendering failed.\n\nFFmpeg error details:\n'
          '${logs.length > 600 ? logs.substring(logs.length - 600) : logs}',
        );
      }
    } finally {
      await WakelockPlus.disable();
    }
  }

  void dispose() {
    _client.close();
  }
}

final reelCompilerServiceProvider = Provider<ReelCompilerService>((ref) {
  final service = ReelCompilerService();
  ref.onDispose(() => service.dispose());
  return service;
});
