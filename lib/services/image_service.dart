import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../models/document_model.dart';

class ImageService {
  const ImageService._();

  static Future<Uint8List> renderFilter(
    String sourcePath,
    ScanFilter filter,
  ) async {
    final source = await File(sourcePath).readAsBytes();
    final decoded = img.decodeImage(source);
    if (decoded == null) {
      throw const FormatException('No se pudo leer la imagen');
    }

    var image = img.bakeOrientation(decoded);
    switch (filter) {
      case ScanFilter.original:
        break;
      case ScanFilter.automatic:
        image = img.adjustColor(
          image,
          brightness: 1.03,
          contrast: 1.14,
          saturation: 1.08,
        );
      case ScanFilter.grayscale:
        image = img.grayscale(image);
        image = img.adjustColor(image, contrast: 1.12);
      case ScanFilter.blackAndWhite:
        image = img.grayscale(image);
        image = img.adjustColor(image, contrast: 1.65, brightness: 1.02);
    }

    return Uint8List.fromList(img.encodeJpg(image, quality: 92));
  }

  static Future<String> saveFiltered({
    required String sourcePath,
    required ScanFilter filter,
    required Directory destination,
    String? baseName,
  }) async {
    await destination.create(recursive: true);
    final bytes = await renderFilter(sourcePath, filter);
    final name = baseName ?? 'scan_${DateTime.now().microsecondsSinceEpoch}';
    final outputPath = p.join(destination.path, '$name.jpg');
    await File(outputPath).writeAsBytes(bytes, flush: true);
    return outputPath;
  }

  /// Normalizes gallery and camera images to JPEG so every later step
  /// (filters, thumbnails and PDF generation) behaves consistently.
  static Future<String> normalizeToJpeg({
    required String sourcePath,
    required Directory destination,
  }) async {
    await destination.create(recursive: true);
    final source = await File(sourcePath).readAsBytes();
    final decoded = img.decodeImage(source);
    final name = 'scan_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final outputPath = p.join(destination.path, name);

    if (decoded == null) {
      // Camera plugins normally produce JPEGs. Keep an unsupported file as a
      // fallback instead of blocking the user's scan flow.
      final extension = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
      final fallbackPath = p.join(
        destination.path,
        'scan_${DateTime.now().microsecondsSinceEpoch}$extension',
      );
      await File(sourcePath).copy(fallbackPath);
      return fallbackPath;
    }

    final normalized = img.bakeOrientation(decoded);
    await File(outputPath).writeAsBytes(
      img.encodeJpg(normalized, quality: 94),
      flush: true,
    );
    return outputPath;
  }
}
