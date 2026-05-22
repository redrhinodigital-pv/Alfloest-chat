import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:http/http.dart' as http;
import '../core/errors/exceptions.dart';

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Helper to simulate upload progress based on file size
  void _simulateProgress(void Function(double)? onProgress, int fileSize) {
    if (onProgress == null) return;
    int steps = 10;
    if (fileSize > 1024 * 1024) { // > 1MB
      steps = 25;
    } else if (fileSize > 100 * 1024) { // > 100KB
      steps = 15;
    }
    double currentProgress = 0.0;
    final stepSize = 0.9 / steps;
    
    int currentStep = 0;
    Stream.periodic(const Duration(milliseconds: 80)).take(steps).listen((_) {
      currentStep++;
      currentProgress = currentStep * stepSize;
      onProgress(currentProgress);
    });
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
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      case 'aac':
        return 'audio/aac';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
        return 'audio/ogg';
      default:
        return 'application/octet-stream';
    }
  }

  /// Upload voice note (AAC format)
  Future<String> uploadVoiceNote({
    required String? filePath,
    required Uint8List? bytes,
    required String chatId,
    required String messageId,
    void Function(double)? onProgress,
  }) async {
    try {
      final path = 'voice_notes/$chatId/$messageId.aac';
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

      final fileSize = uploadBytes?.length ?? 10240;
      _simulateProgress(onProgress, fileSize);

      if (kIsWeb || uploadBytes != null) {
        if (uploadBytes == null && filePath != null) {
          uploadBytes = await XFile(filePath).readAsBytes();
        }
        await _supabase.storage.from('chat-media').uploadBinary(
          path,
          uploadBytes!,
          fileOptions: const FileOptions(contentType: 'audio/aac'),
        );
      } else {
        final file = io.File(filePath!);
        await _supabase.storage.from('chat-media').upload(
          path,
          file,
          fileOptions: const FileOptions(contentType: 'audio/aac'),
        );
        // Clean up original file on mobile
        if (await file.exists()) {
          await file.delete();
        }
      }

      onProgress?.call(1.0);
      final downloadUrl = _supabase.storage.from('chat-media').getPublicUrl(path);
      return downloadUrl;
    } catch (e) {
      throw AppStorageException('Failed to upload voice note', originalError: e);
    }
  }

  /// Delete voice note
  Future<void> deleteVoiceNote({
    required String chatId,
    required String messageId,
  }) async {
    try {
      final path = 'voice_notes/$chatId/$messageId.aac';
      await _supabase.storage.from('chat-media').remove([path]);
    } catch (e) {
      throw AppStorageException('Failed to delete voice note', originalError: e);
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
      final path = '$userId-$timestamp.jpg';

      // Clean up previous user avatars from the bucket
      try {
        final list = await _supabase.storage.from('avatars').list();
        final userAvatars = list
            .where((item) => item.name.startsWith('$userId-'))
            .map((item) => item.name)
            .toList();
        if (userAvatars.isNotEmpty) {
          await _supabase.storage.from('avatars').remove(userAvatars);
        }
      } catch (_) {}

      Uint8List? uploadBytes = bytes;
      if (uploadBytes == null && filePath != null) {
        if (kIsWeb) {
          uploadBytes = await XFile(filePath).readAsBytes();
        }
      }

      final fileSize = uploadBytes?.length ?? 102400;
      _simulateProgress(onProgress, fileSize);

      if (kIsWeb || uploadBytes != null) {
        if (uploadBytes == null && filePath != null) {
          uploadBytes = await XFile(filePath).readAsBytes();
        }
        await _supabase.storage.from('avatars').uploadBinary(
          path,
          uploadBytes!,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
      } else {
        await _supabase.storage.from('avatars').upload(
          path,
          io.File(filePath!),
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
      }

      onProgress?.call(1.0);
      return _supabase.storage.from('avatars').getPublicUrl(path);
    } catch (e) {
      throw AppStorageException('Failed to upload avatar', originalError: e);
    }
  }

  /// Delete user profile avatar
  Future<void> deleteAvatar({required String userId}) async {
    try {
      final list = await _supabase.storage.from('avatars').list();
      final userAvatars = list
          .where((item) => item.name.startsWith('$userId-'))
          .map((item) => item.name)
          .toList();
      if (userAvatars.isNotEmpty) {
        await _supabase.storage.from('avatars').remove(userAvatars);
      }
    } catch (e) {
      throw AppStorageException('Failed to delete avatar', originalError: e);
    }
  }

  /// Upload group avatar to the 'avatars' bucket
  Future<String> uploadGroupAvatar({
    required String? filePath,
    required Uint8List? bytes,
    required String groupId,
    void Function(double)? onProgress,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'group-$groupId-$timestamp.jpg';

      // Clean up previous group avatars
      try {
        final list = await _supabase.storage.from('avatars').list();
        final groupAvatars = list
            .where((item) => item.name.startsWith('group-$groupId-'))
            .map((item) => item.name)
            .toList();
        if (groupAvatars.isNotEmpty) {
          await _supabase.storage.from('avatars').remove(groupAvatars);
        }
      } catch (_) {}

      Uint8List? uploadBytes = bytes;
      if (uploadBytes == null && filePath != null) {
        if (kIsWeb) {
          uploadBytes = await XFile(filePath).readAsBytes();
        }
      }

      final fileSize = uploadBytes?.length ?? 102400;
      _simulateProgress(onProgress, fileSize);

      if (kIsWeb || uploadBytes != null) {
        if (uploadBytes == null && filePath != null) {
          uploadBytes = await XFile(filePath).readAsBytes();
        }
        await _supabase.storage.from('avatars').uploadBinary(
          path,
          uploadBytes!,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
      } else {
        await _supabase.storage.from('avatars').upload(
          path,
          io.File(filePath!),
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
      }

      onProgress?.call(1.0);
      return _supabase.storage.from('avatars').getPublicUrl(path);
    } catch (e) {
      throw AppStorageException('Failed to upload group avatar', originalError: e);
    }
  }

  /// Upload chat media (image, video, document) to the 'chat-media' bucket
  Future<String> uploadMedia({
    required String? filePath,
    required Uint8List? bytes,
    required String chatId,
    required String fileName,
    String mimeType = 'application/octet-stream',
    void Function(double)? onProgress,
  }) async {
    try {
      final sanitizedFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'shared_media/$chatId/$timestamp-$sanitizedFileName';

      Uint8List? uploadBytes = bytes;
      if (uploadBytes == null && filePath != null) {
        if (kIsWeb) {
          uploadBytes = await XFile(filePath).readAsBytes();
        }
      }

      final resolvedMimeType = mimeType == 'application/octet-stream' 
          ? _lookupMimeType(fileName)
          : mimeType;

      final fileSize = uploadBytes?.length ?? 102400;
      _simulateProgress(onProgress, fileSize);

      if (kIsWeb || uploadBytes != null) {
        if (uploadBytes == null && filePath != null) {
          uploadBytes = await XFile(filePath).readAsBytes();
        }
        await _supabase.storage.from('chat-media').uploadBinary(
          path,
          uploadBytes!,
          fileOptions: FileOptions(contentType: resolvedMimeType),
        );
      } else {
        await _supabase.storage.from('chat-media').upload(
          path,
          io.File(filePath!),
          fileOptions: FileOptions(contentType: resolvedMimeType),
        );
      }

      onProgress?.call(1.0);
      return _supabase.storage.from('chat-media').getPublicUrl(path);
    } catch (e) {
      throw AppStorageException('Failed to upload media', originalError: e);
    }
  }
}
