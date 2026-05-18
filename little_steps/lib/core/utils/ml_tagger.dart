import 'dart:io';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'app_logger.dart';

class MlTagger {
  MlTagger._();

  static const double _minConfidence = 0.65;
  static const int _maxLabels = 6;

  static Future<List<String>> labelImage(File image) async {
    final inputImage = InputImage.fromFile(image);
    final labeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: _minConfidence),
    );

    try {
      final labels = await labeler.processImage(inputImage);
      final result = labels
          .map((l) => l.label.toLowerCase())
          .take(_maxLabels)
          .toList();
      AppLogger.i('ML tags: $result');
      return result;
    } catch (e) {
      AppLogger.e('ML tagging failed — continuing without tags', e);
      return [];
    } finally {
      await labeler.close();
    }
  }
}
