import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:archive/archive.dart';
import 'package:video_compress/video_compress.dart';

final compressionServiceProvider = Provider<CompressionService>((ref) => CompressionService());

/// Response container for compressed images
class ImageCompressResult {
  final Uint8List mediaBytes;
  final Uint8List thumbnailBytes;
  final String format;

  ImageCompressResult({
    required this.mediaBytes,
    required this.thumbnailBytes,
    required this.format,
  });
}

/// Response container for compressed videos
class VideoCompressResult {
  final String filePath;
  final Uint8List thumbnailBytes;

  VideoCompressResult({
    required this.filePath,
    required this.thumbnailBytes,
  });
}

/// Core Compression Engine handling Multi-media adaptive compression
class CompressionService {

  /// Top-level helper function for isolated image compression (runs on separate Thread)
  static ImageCompressResult _performIsolatedImageCompression(Map<String, dynamic> params) {
    final Uint8List originalBytes = params['bytes'] as Uint8List;
    final bool dataSaver = params['dataSaver'] as bool;
    final bool isHD = params['isHD'] as bool;

    final img.Image? decoded = img.decodeImage(originalBytes);
    if (decoded == null) {
      throw Exception('Failed to decode image data.');
    }

    // 1. Intelligent Resizing (maintain aspect ratio)
    final maxDimension = isHD ? 1920 : 1280;
    img.Image resized = decoded;
    if (decoded.width > maxDimension || decoded.height > maxDimension) {
      if (decoded.width > decoded.height) {
        resized = img.copyResize(decoded, width: maxDimension);
      } else {
        resized = img.copyResize(decoded, height: maxDimension);
      }
    }

    // 2. Adaptive progressive compression quality loop (target < 300KB)
    int quality = dataSaver ? 50 : 75;
    Uint8List compressedBytes;
    while (true) {
      compressedBytes = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
      if (compressedBytes.length < 300 * 1024 || quality <= 40) {
        break; // Stop if size is acceptable or quality reaches floor
      }
      quality -= 10; // Progressive step reduction
    }

    // 3. Generate 300x300 blurred loaded thumbnail
    final img.Image thumbImg = img.copyResize(resized, width: 300, height: 300);
    // Extreme high JPEG compression (quality 15) for hyper-fast loading blurred preview
    final Uint8List thumbBytes = Uint8List.fromList(img.encodeJpg(thumbImg, quality: 15));

    return ImageCompressResult(
      mediaBytes: compressedBytes,
      thumbnailBytes: thumbBytes,
      format: 'jpg',
    );
  }

  /// Entry point to compress image (WebP, EXIF stripping, resizing, retry logic)
  Future<ImageCompressResult> compressImage({
    required String? filePath,
    required Uint8List originalBytes,
    bool dataSaver = false,
    bool isHD = false,
  }) async {
    try {
      // Execute compression in background isolate to keep UI thread fully fluid
      return await compute(_performIsolatedImageCompression, {
        'bytes': originalBytes,
        'dataSaver': dataSaver,
        'isHD': isHD,
      });
    } catch (e) {
      debugPrint('Isolate image compression failed, falling back: $e');
      
      // Secondary fallback using basic mobile-only compressor if isolate encounters issues
      if (!kIsWeb && filePath != null) {
        try {
          final tempDir = await getTemporaryDirectory();
          final targetPath = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final resultFile = await FlutterImageCompress.compressAndGetFile(
            filePath,
            targetPath,
            quality: dataSaver ? 50 : 70,
            minWidth: isHD ? 1920 : 1280,
            minHeight: isHD ? 1920 : 1280,
            format: CompressFormat.jpeg,
          );
          if (resultFile != null) {
            final bytes = await resultFile.readAsBytes();
            return ImageCompressResult(
              mediaBytes: bytes,
              thumbnailBytes: bytes, // Use same file as fallback preview
              format: 'jpeg',
            );
          }
        } catch (_) {}
      }
      
      // Absolute fallback: original bytes
      return ImageCompressResult(
        mediaBytes: originalBytes,
        thumbnailBytes: originalBytes,
        format: 'jpeg',
      );
    }
  }

  /// Compress and transcode video to 720p maximum resolution
  Future<VideoCompressResult?> compressVideo({
    required String filePath,
    bool dataSaver = false,
    void Function(double)? onProgress,
  }) async {
    if (kIsWeb) {
      // Video transcoding not supported natively on web
      return null;
    }

    try {
      // Set up progress callbacks
      Subscription? subscription;
      if (onProgress != null) {
        subscription = VideoCompress.compressProgress$.subscribe((progress) {
          onProgress(progress / 100.0);
        });
      }

      final info = await VideoCompress.compressVideo(
        filePath,
        quality: dataSaver ? VideoQuality.LowQuality : VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      subscription?.unsubscribe();

      if (info != null && info.path != null) {
        final thumbnailFile = await VideoCompress.getFileThumbnail(filePath);
        final thumbnailBytes = await thumbnailFile.readAsBytes();
        return VideoCompressResult(
          filePath: info.path!,
          thumbnailBytes: thumbnailBytes,
        );
      }
    } catch (e) {
      debugPrint('Video compression failed: $e');
    }
    return null;
  }

  /// Zips document streams dynamically to reduce bandwidth and storage usage aggressively.
  Future<Uint8List> zipDocument({
    required String fileName,
    required Uint8List originalBytes,
  }) async {
    try {
      return await compute((params) {
        final String name = params['name'] as String;
        final Uint8List bytes = params['bytes'] as Uint8List;

        final archive = Archive();
        archive.addFile(ArchiveFile(name, bytes.length, bytes));

        final zipped = ZipEncoder().encode(archive);
        return Uint8List.fromList(zipped);
      }, {
        'name': fileName,
        'bytes': originalBytes,
      });
    } catch (e) {
      debugPrint('Document zipping failed, falling back: $e');
      return originalBytes;
    }
  }

  /// Helper to release transcode memory cache
  Future<void> cleanVideoCache() async {
    if (!kIsWeb) {
      await VideoCompress.deleteAllCache();
    }
  }
}
