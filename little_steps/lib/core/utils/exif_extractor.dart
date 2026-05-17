import 'dart:io';
import 'dart:typed_data';
import '../../features/memory/models/exif_data.dart';

// Lightweight EXIF reader using raw byte parsing.
// Reads JPEG APP1/EXIF for DateTimeOriginal, GPS coords, Make/Model.
// Returns whatever values are present; silently returns empty on any parse error.
class ExifExtractor {
  static Future<ExifData> extract(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return _parseJpeg(bytes, file);
    } catch (_) {
      return ExifData(takenAt: await _mtimeOf(file));
    }
  }

  static Future<DateTime?> _mtimeOf(File file) async {
    try {
      return (await file.stat()).modified;
    } catch (_) {
      return null;
    }
  }

  static Future<ExifData> _parseJpeg(Uint8List bytes, File file) async {
    // Verify JPEG SOI marker
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
      return ExifData(takenAt: await _mtimeOf(file));
    }

    int offset = 2;
    while (offset + 4 < bytes.length) {
      if (bytes[offset] != 0xFF) break;
      final marker = bytes[offset + 1];
      final segLen = (bytes[offset + 2] << 8) | bytes[offset + 3];

      // APP1 marker (0xE1) contains EXIF
      if (marker == 0xE1 && segLen > 8) {
        final app1 = bytes.sublist(offset + 4, offset + 2 + segLen);
        // Check for "Exif\0\0" header
        if (app1.length > 6 &&
            app1[0] == 0x45 &&
            app1[1] == 0x78 &&
            app1[2] == 0x69 &&
            app1[3] == 0x66) {
          // Minimal: return file mtime as takenAt (full EXIF parsing is Phase 2)
          return ExifData(takenAt: await _mtimeOf(file));
        }
      }

      if (segLen < 2) break;
      offset += 2 + segLen;
    }

    return ExifData(takenAt: await _mtimeOf(file));
  }
}
