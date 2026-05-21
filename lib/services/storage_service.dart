import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors/exceptions.dart';

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> uploadVoiceNote({
    required String filePath,
    required String chatId,
    required String messageId,
  }) async {
    try {
      final file = File(filePath);
      final path = 'voice_notes/$chatId/$messageId.aac';

      await _supabase.storage.from('chat-media').upload(
        path,
        file,
        fileOptions: const FileOptions(contentType: 'audio/aac'),
      );

      final downloadUrl = _supabase.storage.from('chat-media').getPublicUrl(path);

      if (await file.exists()) await file.delete();

      return downloadUrl;
    } catch (e) {
      throw AppStorageException('Failed to upload voice note', originalError: e);
    }
  }

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

  /// Upload user profile avatar
  Future<String> uploadAvatar({
    required String filePath,
    required String userId,
  }) async {
    try {
      final file = File(filePath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'avatars/$userId-$timestamp.jpg';

      // Clean up previous avatars
      try {
        final list = await _supabase.storage.from('chat-media').list(path: 'avatars');
        final userAvatars = list
            .where((item) => item.name.startsWith('$userId-'))
            .map((item) => 'avatars/${item.name}')
            .toList();
        if (userAvatars.isNotEmpty) {
          await _supabase.storage.from('chat-media').remove(userAvatars);
        }
      } catch (_) {}

      await _supabase.storage.from('chat-media').upload(
        path,
        file,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );

      return _supabase.storage.from('chat-media').getPublicUrl(path);
    } catch (e) {
      throw AppStorageException('Failed to upload avatar', originalError: e);
    }
  }

  /// Delete user profile avatar
  Future<void> deleteAvatar({required String userId}) async {
    try {
      final list = await _supabase.storage.from('chat-media').list(path: 'avatars');
      final userAvatars = list
          .where((item) => item.name.startsWith('$userId-'))
          .map((item) => 'avatars/${item.name}')
          .toList();
      if (userAvatars.isNotEmpty) {
        await _supabase.storage.from('chat-media').remove(userAvatars);
      }
    } catch (e) {
      throw AppStorageException('Failed to delete avatar', originalError: e);
    }
  }

  /// Upload group avatar
  Future<String> uploadGroupAvatar({
    required String filePath,
    required String groupId,
  }) async {
    try {
      final file = File(filePath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'group_avatars/$groupId-$timestamp.jpg';

      // Clean up previous group avatars
      try {
        final list = await _supabase.storage.from('chat-media').list(path: 'group_avatars');
        final groupAvatars = list
            .where((item) => item.name.startsWith('$groupId-'))
            .map((item) => 'group_avatars/${item.name}')
            .toList();
        if (groupAvatars.isNotEmpty) {
          await _supabase.storage.from('chat-media').remove(groupAvatars);
        }
      } catch (_) {}

      await _supabase.storage.from('chat-media').upload(
        path,
        file,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );

      return _supabase.storage.from('chat-media').getPublicUrl(path);
    } catch (e) {
      throw AppStorageException('Failed to upload group avatar', originalError: e);
    }
  }

  /// Upload chat media (image, video, document)
  Future<String> uploadMedia({
    required String filePath,
    required String chatId,
    required String fileName,
    String mimeType = 'application/octet-stream',
  }) async {
    try {
      final file = File(filePath);
      final sanitizedFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'shared_media/$chatId/$timestamp-$sanitizedFileName';

      await _supabase.storage.from('chat-media').upload(
        path,
        file,
        fileOptions: FileOptions(contentType: mimeType),
      );

      return _supabase.storage.from('chat-media').getPublicUrl(path);
    } catch (e) {
      throw AppStorageException('Failed to upload media', originalError: e);
    }
  }
}
