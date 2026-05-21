import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors/exceptions.dart';

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Upload voice note (AAC format)
  Future<String> uploadVoiceNote({
    required String? filePath,
    required Uint8List? bytes,
    required String chatId,
    required String messageId,
  }) async {
    try {
      final path = 'voice_notes/$chatId/$messageId.aac';

      if (bytes != null) {
        await _supabase.storage.from('chat-media').uploadBinary(
          path,
          bytes,
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

      if (bytes != null) {
        await _supabase.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
      } else {
        await _supabase.storage.from('avatars').upload(
          path,
          io.File(filePath!),
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
      }

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

      if (bytes != null) {
        await _supabase.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
      } else {
        await _supabase.storage.from('avatars').upload(
          path,
          io.File(filePath!),
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
      }

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
  }) async {
    try {
      final sanitizedFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'shared_media/$chatId/$timestamp-$sanitizedFileName';

      if (bytes != null) {
        await _supabase.storage.from('chat-media').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mimeType),
        );
      } else {
        await _supabase.storage.from('chat-media').upload(
          path,
          io.File(filePath!),
          fileOptions: FileOptions(contentType: mimeType),
        );
      }

      return _supabase.storage.from('chat-media').getPublicUrl(path);
    } catch (e) {
      throw AppStorageException('Failed to upload media', originalError: e);
    }
  }
}
