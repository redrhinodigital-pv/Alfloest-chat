import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final compressionServiceProvider = Provider<CompressionService>((ref) => CompressionService());

class CompressionService {
  /// Compress image
  /// - Resizes max width/height to 1280
  /// - Lowers quality to 70
  /// - Converts to jpeg
  Future<Uint8List> compressImage({
    required String filePath,
    required Uint8List originalBytes,
  }) async {
    if (kIsWeb) {
      // On Web, native compressors are not supported.
      // We rely on ImagePicker's native compression or return original bytes.
      return originalBytes;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        targetPath,
        quality: 70,
        minWidth: 1280,
        minHeight: 1280,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        final compressedBytes = await result.readAsBytes();
        // Clean up temporary compressed file
        try {
          final file = io.File(targetPath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
        return compressedBytes;
      }
    } catch (e) {
      debugPrint('Image compression failed, falling back to original: $e');
    }
    return originalBytes;
  }

  /// Compress video
  /// - Reduces bitrate intelligently
  /// - Target size: 10MB - 20MB
  /// Returns a map with compressed file path (null if web) and bytes.
  Future<CompressedVideoResult> compressVideo({
    required String filePath,
    required Uint8List originalBytes,
  }) async {
    if (kIsWeb) {
      // Video compression not supported on web
      return CompressedVideoResult(
        filePath: null,
        bytes: originalBytes,
      );
    }

    try {
      // Start compression using video_compress
      final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        filePath,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false, // Do not delete user's original video
        includeAudio: true,
      );

      if (mediaInfo != null && mediaInfo.file != null) {
        final compressedFile = mediaInfo.file!;
        final bytes = await compressedFile.readAsBytes();
        return CompressedVideoResult(
          filePath: compressedFile.path,
          bytes: bytes,
        );
      }
    } catch (e) {
      debugPrint('Video compression failed, falling back to original: $e');
    }

    return CompressedVideoResult(
      filePath: filePath,
      bytes: originalBytes,
    );
  }
}

class CompressedVideoResult {
  final String? filePath;
  final Uint8List bytes;

  CompressedVideoResult({
    required this.filePath,
    required this.bytes,
  });
}
