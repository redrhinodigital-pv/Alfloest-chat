import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Service handling security validation, upload deduplication, and pre-compression estimations.
class ValidationService {
  static const String _historyBoxName = 'upload_history_cache';

  /// List of dangerous file extensions blocked for security
  static const Set<String> _blockedExtensions = {
    'exe', 'bat', 'cmd', 'sh', 'apk', 'dmg', 'bin', 'com', 'vbs', 'msi', 'scr', 'pif', 'cpl'
  };

  /// Validate if file extension is safe to upload
  static bool isSafeFile(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return !_blockedExtensions.contains(ext);
  }

  /// Estimates compressed file size (in bytes) based on media type and original size.
  static int estimateCompressedSize(String fileName, int originalSize, {bool dataSaver = false}) {
    final ext = fileName.split('.').last.toLowerCase();
    
    // Image estimation: WebP compression typically achieves 80-92% reduction
    if (['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(ext)) {
      final ratio = dataSaver ? 0.05 : 0.08; // 95% reduction on data saver, 92% on normal
      final est = (originalSize * ratio).round();
      return est.clamp(5000, originalSize); // Minimum 5KB
    }
    
    // Video estimation: 720p transcoding reduces size heavily (usually ~90% for standard mobile captures)
    if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext)) {
      final ratio = dataSaver ? 0.06 : 0.12; 
      final est = (originalSize * ratio).round();
      return est.clamp(200000, originalSize); // Minimum 200KB
    }

    // Audio/Voice Notes: natively compressed
    if (['aac', 'm4a', 'wav', 'mp3'].contains(ext)) {
      return (originalSize * 0.4).round(); // ~60% reduction
    }

    // Documents/Zipped
    if (['txt', 'pdf', 'doc', 'docx', 'xls', 'xlsx'].contains(ext)) {
      return (originalSize * 0.6).round(); // ~40% reduction when zipped
    }

    return originalSize; // No compression changes for raw binaries
  }

  /// Generate a unique fingerprint of a file using filename and size
  static String _generateFingerprint(String fileName, int fileSize) {
    return '${fileName}_$fileSize';
  }

  /// Register an uploaded file to Hive deduplication cache
  static Future<void> registerUpload(String fileName, int fileSize, String publicUrl) async {
    try {
      final box = await Hive.openBox(_historyBoxName);
      final fingerprint = _generateFingerprint(fileName, fileSize);
      await box.put(fingerprint, publicUrl);
    } catch (e) {
      debugPrint('Deduplication register error: $e');
    }
  }

  /// Checks if file was recently uploaded and returns the cached public URL if duplicate found.
  static Future<String?> checkDuplicate(String fileName, int fileSize) async {
    try {
      final box = await Hive.openBox(_historyBoxName);
      final fingerprint = _generateFingerprint(fileName, fileSize);
      final cachedUrl = box.get(fingerprint) as String?;
      if (cachedUrl != null) {
        debugPrint('Deduplication: Duplicate file found! Using cached URL: $cachedUrl');
        return cachedUrl;
      }
    } catch (e) {
      debugPrint('Deduplication check error: $e');
    }
    return null;
  }
}
