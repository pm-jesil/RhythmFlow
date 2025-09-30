part of 'metadata_extractor.dart';

/// Album art extraction, optimization, and management
class AlbumArtHandler {
  /// Extract album art from metadata with optimization
  static Future<String?> extractAlbumArt(String filePath, Tag? tag) async {
    try {
      final pictures = tag?.pictures;
      if (pictures == null || pictures.isEmpty) {
        MetadataExtractor._logger.d('No album art found in metadata for: $filePath');
        return null;
      }
      final picture = pictures.first;
      final albumArtData = picture.bytes;
      MetadataExtractor._logger.d('Found album art (${albumArtData.length} bytes) for: $filePath');
      final optimizedData = await optimizeAlbumArt(albumArtData);
      if (optimizedData == null) {
        MetadataExtractor._logger.w('Failed to optimize album art for: $filePath');
        return null;
      }
      return await saveAlbumArt(filePath, optimizedData, picture.mimeType?.toString());
    } catch (e, stackTrace) {
      MetadataExtractor._logger.e('Error extracting album art from $filePath', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Safe extraction of album art with error handling
  static Future<String?> extractAlbumArtSafely(String filePath, Tag? tag) async {
    return await SharedValidation.extractSafely(
      () async => await extractAlbumArt(filePath, tag),
      null,
      'album art',
    );
  }

  /// Find external album art files in the same directory
  static Future<String?> findExternalAlbumArt(String filePath) async {
    try {
      final dir = Directory(filePath.substring(0, filePath.lastIndexOf('/')));
      if (!await dir.exists()) return null;
      final candidates = <String>[
        'cover.jpg', 'cover.png', 'folder.jpg', 'folder.png', 'front.jpg', 'front.png',
      ];
      for (final name in candidates) {
        final f = File('${dir.path}/$name');
        if (await f.exists()) {
          final data = await f.readAsBytes();
          final optimized = await optimizeAlbumArt(data);
          return await saveAlbumArt(filePath, optimized ?? data, guessMimeTypeFromPath(name));
        }
      }
    } catch (e) {
      MetadataExtractor._logger.w('External album art search failed for $filePath - $e');
    }
    return null;
  }

  /// Optimize album art using isolate for heavy processing
  static Future<Uint8List?> optimizeAlbumArt(Uint8List imageData) async {
    try {
      final optimized = await compute(_optimizeAlbumArtIsolate, imageData)
          .timeout(const Duration(seconds: 5));
      return optimized ?? imageData;
    } catch (e, stackTrace) {
      MetadataExtractor._logger.e('Error optimizing album art', error: e, stackTrace: stackTrace);
      return imageData;
    }
  }

  /// Save optimized album art to app directory
  static Future<String?> saveAlbumArt(String filePath, Uint8List data, String? mimeType) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final albumArtDir = Directory('${appDir.path}/album_art');
      if (!await albumArtDir.exists()) {
        await albumArtDir.create(recursive: true);
      }
      final songId = await _generateSongId(filePath);
      final extension = getImageExtensionFromMimeType(mimeType);
      final albumArtPath = '${albumArtDir.path}/$songId$extension';
      final albumArtFile = File(albumArtPath);
      if (!await albumArtFile.exists()) {
        await albumArtFile.writeAsBytes(data);
        MetadataExtractor._logger.d('Saved optimized album art: $albumArtPath');
      } else {
        MetadataExtractor._logger.d('Album art already exists: $albumArtPath');
      }
      return albumArtPath;
    } catch (e) {
      MetadataExtractor._logger.w('Failed to save album art: $e');
      try {
        final tempDir = await getTemporaryDirectory();
        final albumArtDir = Directory('${tempDir.path}/album_art');
        if (!await albumArtDir.exists()) {
          await albumArtDir.create(recursive: true);
        }
        final songId = await _generateSongId(filePath);
        final extension = getImageExtensionFromMimeType(mimeType);
        final albumArtPath = '${albumArtDir.path}/$songId$extension';
        final albumArtFile = File(albumArtPath);
        await albumArtFile.writeAsBytes(data);
        MetadataExtractor._logger.d('Saved album art to temp directory: $albumArtPath');
        return albumArtPath;
      } catch (tempError) {
        MetadataExtractor._logger.e('Failed to save album art to temp directory: $tempError');
        return null;
      }
    }
  }

  /// Guess MIME type from file path
  static String guessMimeTypeFromPath(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  /// Get image extension from MIME type
  static String getImageExtensionFromMimeType(String? mimeType) {
    switch (mimeType?.toLowerCase()) {
      case 'image/jpeg':
      case 'image/jpg':
        return '.jpg';
      case 'image/png':
        return '.png';
      case 'image/gif':
        return '.gif';
      case 'image/webp':
        return '.webp';
      case 'image/bmp':
        return '.bmp';
      default:
        return '.jpg';
    }
  }
}

/// Heavy image optimization moved to an isolate-safe top-level function
Uint8List? _optimizeAlbumArtIsolate(Uint8List imageData) {
  try {
    if (imageData.length < 50 * 1024) return imageData;

    final originalImage = img.decodeImage(imageData);
    if (originalImage == null) return null;

    const maxDimension = 500;
    int targetWidth = originalImage.width;
    int targetHeight = originalImage.height;

    if (originalImage.width > maxDimension || originalImage.height > maxDimension) {
      if (originalImage.width > originalImage.height) {
        targetWidth = maxDimension;
        targetHeight = (originalImage.height * maxDimension / originalImage.width).round();
      } else {
        targetHeight = maxDimension;
        targetWidth = (originalImage.width * maxDimension / originalImage.height).round();
      }
    }

    img.Image processedImage = originalImage;
    if (targetWidth != originalImage.width || targetHeight != originalImage.height) {
      processedImage = img.copyResize(
        originalImage,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.cubic,
      );
    }

    int quality = 90;
    if (imageData.length > 500 * 1024) {
      quality = 80;
    } else if (imageData.length > 200 * 1024) {
      quality = 85;
    }

    final compressed = img.encodeJpg(processedImage, quality: quality);
    return Uint8List.fromList(compressed);
  } catch (_) {
    return imageData;
  }
}
