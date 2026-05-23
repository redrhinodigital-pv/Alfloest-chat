import 'dart:io' as io;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import '../core/errors/exceptions.dart';

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

/// Upload task state container for active queue tracking
class UploadProgressState {
  final String taskId;
  final double progress; // 0.0 to 1.0
  final bool isCompleted;
  final bool isFailed;
  final String? error;
  final String? resultUrl;
  final String? thumbnailUrl;

  UploadProgressState({
    required this.taskId,
    required this.progress,
    this.isCompleted = false,
    this.isFailed = false,
    this.error,
    this.resultUrl,
    this.thumbnailUrl,
  });
}

/// Production-ready Supabase storage upload and caching engine
class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _urlCacheBoxName = 'storage_url_cache';

  /// Broadcast stream to notify UI about upload queue progress states
  static final StreamController<UploadProgressState> uploadProgressStream =
      StreamController<UploadProgressState>.broadcast();

  /// Map tracking cancelled task IDs
  final Set<String> _cancelledTasks = {};

  /// Abort/cancel an active upload task
  void cancelUpload(String taskId) {
    _cancelledTasks.add(taskId);
    debugPrint('Upload Cancelled: Task $taskId flag set.');
  }

  /// Check if a task is cancelled and throws exception if true
  void _checkCancelled(String taskId) {
    if (_cancelledTasks.contains(taskId)) {
      _cancelledTasks.remove(taskId); // Reset token
      throw AppStorageException('Upload was cancelled by user.', originalError: 'Cancelled');
    }
  }

  /// Helper to retry an operation with exponential backoff
  Future<T> _executeWithRetry<T>(Future<T> Function() action, {int maxRetries = 3}) async {
    int attempts = 0;
    while (true) {
      try {
        return await action();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          rethrow;
        }
        final backoffMs = 500 * (1 << attempts); // 1s, 2s, 4s...
        debugPrint('Supabase Upload: Attempt $attempts failed, retrying in ${backoffMs}ms: $e');
        await Future.delayed(Duration(milliseconds: backoffMs));
      }
    }
  }

  /// Cache public URLs locally in Hive box to reduce API load
  Future<void> _cachePublicUrl(String path, String url) async {
    try {
      final box = await Hive.openBox(_urlCacheBoxName);
      await box.put(path, url);
    } catch (_) {}
  }



  /// Helper to map extensions to MIME types
  String _lookupMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'mpeg':
        return 'video/mpeg';
      case 'webm':
        return 'video/webm';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'zip':
        return 'application/zip';
      case 'txt':
        return 'text/plain';
      case 'aac':
        return 'audio/aac';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      default:
        return 'application/octet-stream';
    }
  }

  /// Upload voice note (speech-optimized Mono, 16kHz AAC)
  Future<String> uploadVoiceNote({
    required String? filePath,
    required Uint8List? bytes,
    required String chatId,
    required String messageId,
    required String userId,
    void Function(double)? onProgress,
  }) async {
    final taskId = messageId;
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'users/$userId/voice/$timestamp-$messageId.aac';

      Uint8List? uploadBytes = bytes;
      if (uploadBytes == null && filePath != null) {
        if (kIsWeb) {
          if (filePath.startsWith('blob:') || filePath.startsWith('http')) {
            try {
              final res = await http.get(Uri.parse(filePath));
              uploadBytes = res.bodyBytes;
            } catch (_) {
              uploadBytes = await XFile(filePath).readAsBytes();
            }
          } else {
            uploadBytes = await XFile(filePath).readAsBytes();
          }
        }
      }

      uploadProgressStream.add(UploadProgressState(taskId: taskId, progress: 0.1));
      onProgress?.call(0.1);
      _checkCancelled(taskId);

      if (kIsWeb || uploadBytes != null) {
        if (uploadBytes == null && filePath != null) {
          uploadBytes = await XFile(filePath).readAsBytes();
        }
        _checkCancelled(taskId);

        await _executeWithRetry(() => _supabase.storage.from('chat-media').uploadBinary(
          path,
          uploadBytes!,
          fileOptions: const FileOptions(contentType: 'audio/aac'),
        ));
      } else {
        final file = io.File(filePath!);
        _checkCancelled(taskId);

        await _executeWithRetry(() => _supabase.storage.from('chat-media').upload(
          path,
          file,
          fileOptions: const FileOptions(contentType: 'audio/aac'),
        ));
        
        try {
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }

      _checkCancelled(taskId);
      final downloadUrl = _supabase.storage.from('chat-media').getPublicUrl(path);
      await _cachePublicUrl(path, downloadUrl);

      uploadProgressStream.add(UploadProgressState(
        taskId: taskId,
        progress: 1.0,
        isCompleted: true,
        resultUrl: downloadUrl,
      ));
      onProgress?.call(1.0);

      return downloadUrl;
    } catch (e) {
      uploadProgressStream.add(UploadProgressState(
        taskId: taskId,
        progress: 0.0,
        isFailed: true,
        error: e.toString(),
      ));
      throw AppStorageException('Failed to upload voice note', originalError: e);
    }
  }

  /// Upload user profile avatar to the 'avatars' bucket
  Future<String> uploadAvatar({
    required String? filePath,
    required Uint8List? bytes,
    required String userId,
    void Function(double)? onProgress,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'profiles/$userId-$timestamp.jpg';

      // Clean up previous user avatars
      try {
        final list = await _supabase.storage.from('avatars').list(path: 'profiles');
        final userAvatars = list
            .where((item) => item.name.startsWith(userId))
            .map((item) => 'profiles/${item.name}')
            .toList();
        if (userAvatars.isNotEmpty) {
          await _supabase.storage.from('avatars').remove(userAvatars);
        }
      } catch (_) {}

      Uint8List? uploadBytes = bytes;
      if (uploadBytes == null && filePath != null) {
        uploadBytes = await XFile(filePath).readAsBytes();
      }

      onProgress?.call(0.2);

      await _executeWithRetry(() => _supabase.storage.from('avatars').uploadBinary(
        path,
        uploadBytes!,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      ));

      onProgress?.call(1.0);
      final url = _supabase.storage.from('avatars').getPublicUrl(path);
      await _cachePublicUrl(path, url);
      return url;
    } catch (e) {
      throw AppStorageException('Failed to upload avatar', originalError: e);
    }
  }

  /// Upload group avatar
  Future<String> uploadGroupAvatar({
    required String? filePath,
    required Uint8List? bytes,
    required String groupId,
    void Function(double)? onProgress,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'groups/$groupId-$timestamp.jpg';

      // Clean up previous group avatars
      try {
        final list = await _supabase.storage.from('avatars').list(path: 'groups');
        final groupAvatars = list
            .where((item) => item.name.startsWith(groupId))
            .map((item) => 'groups/${item.name}')
            .toList();
        if (groupAvatars.isNotEmpty) {
          await _supabase.storage.from('avatars').remove(groupAvatars);
        }
      } catch (_) {}

      Uint8List? uploadBytes = bytes;
      if (uploadBytes == null && filePath != null) {
        uploadBytes = await XFile(filePath).readAsBytes();
      }

      onProgress?.call(0.2);

      await _executeWithRetry(() => _supabase.storage.from('avatars').uploadBinary(
        path,
        uploadBytes!,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      ));

      onProgress?.call(1.0);
      final url = _supabase.storage.from('avatars').getPublicUrl(path);
      await _cachePublicUrl(path, url);
      return url;
    } catch (e) {
      throw AppStorageException('Failed to upload group avatar', originalError: e);
    }
  }

  /// Centralized Premium Upload Engine supporting progress reporting, folder layout, cancel tokens and micro-thumbnails
  Future<String> uploadMedia({
    required String? filePath,
    required Uint8List? bytes,
    required String chatId,
    required String userId,
    required String fileName,
    required String taskId,
    Uint8List? thumbnailBytes,
    String mimeType = 'application/octet-stream',
    void Function(double)? onProgress,
  }) async {
    try {
      final sanitizedFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = fileName.split('.').last.toLowerCase();

      // Resolve subfolder paths cleanly
      String subFolder = 'docs';
      if (['jpg', 'jpeg', 'png', 'webp', 'gif', 'heic'].contains(ext)) {
        subFolder = 'images';
      } else if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext)) {
        subFolder = 'videos';
      }

      final mediaPath = 'users/$userId/$subFolder/$timestamp-$sanitizedFileName';
      final thumbPath = 'users/$userId/thumbnails/$timestamp-$sanitizedFileName.webp';

      // Read bytes if needed
      Uint8List? uploadBytes = bytes;
      if (uploadBytes == null && filePath != null) {
        uploadBytes = await XFile(filePath).readAsBytes();
      }
      if (uploadBytes == null) throw Exception('No file data provided.');

      // 1. Upload Thumbnail if exists
      String? thumbUrl;
      if (thumbnailBytes != null && thumbnailBytes.isNotEmpty) {
        try {
          _checkCancelled(taskId);
          await _executeWithRetry(() => _supabase.storage.from('chat-media').uploadBinary(
            thumbPath,
            thumbnailBytes,
            fileOptions: const FileOptions(contentType: 'image/webp'),
          ));
          thumbUrl = _supabase.storage.from('chat-media').getPublicUrl(thumbPath);
          await _cachePublicUrl(thumbPath, thumbUrl);
        } catch (e) {
          debugPrint('Thumbnail upload failed, proceeding anyway: $e');
        }
      }

      // 2. Upload Main File
      uploadProgressStream.add(UploadProgressState(taskId: taskId, progress: 0.1, thumbnailUrl: thumbUrl));
      onProgress?.call(0.1);
      _checkCancelled(taskId);

      final resolvedMimeType = mimeType == 'application/octet-stream'
          ? _lookupMimeType(fileName)
          : mimeType;

      if (kIsWeb || filePath == null) {
        _checkCancelled(taskId);
        await _executeWithRetry(() => _supabase.storage.from('chat-media').uploadBinary(
          mediaPath,
          uploadBytes!,
          fileOptions: FileOptions(contentType: resolvedMimeType),
        ));
      } else {
        _checkCancelled(taskId);
        await _executeWithRetry(() => _supabase.storage.from('chat-media').upload(
          mediaPath,
          io.File(filePath),
          fileOptions: FileOptions(contentType: resolvedMimeType),
        ));
      }

      _checkCancelled(taskId);
      final downloadUrl = _supabase.storage.from('chat-media').getPublicUrl(mediaPath);
      await _cachePublicUrl(mediaPath, downloadUrl);

      // 3. Mark task completed in queue
      uploadProgressStream.add(UploadProgressState(
        taskId: taskId,
        progress: 1.0,
        isCompleted: true,
        resultUrl: downloadUrl,
        thumbnailUrl: thumbUrl,
      ));
      onProgress?.call(1.0);

      return downloadUrl;
    } catch (e) {
      uploadProgressStream.add(UploadProgressState(
        taskId: taskId,
        progress: 0.0,
        isFailed: true,
        error: e.toString(),
      ));
      throw AppStorageException('Failed to upload media', originalError: e);
    }
  }

  /// Delete user profile avatar from the 'avatars' bucket
  Future<void> deleteAvatar({required String userId}) async {
    try {
      final list = await _supabase.storage.from('avatars').list(path: 'profiles');
      final userAvatars = list
          .where((item) => item.name.startsWith(userId))
          .map((item) => 'profiles/${item.name}')
          .toList();
      if (userAvatars.isNotEmpty) {
        await _supabase.storage.from('avatars').remove(userAvatars);
      }
    } catch (e) {
      throw AppStorageException('Failed to delete avatar', originalError: e);
    }
  }
}

