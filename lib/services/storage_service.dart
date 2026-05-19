import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/errors/exceptions.dart';

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

      await _supabase.storage.from('chat_media').upload(
        path,
        file,
        fileOptions: const FileOptions(contentType: 'audio/aac'),
      );

      final downloadUrl = _supabase.storage.from('chat_media').getPublicUrl(path);

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
      await _supabase.storage.from('chat_media').remove([path]);
    } catch (e) {
      throw AppStorageException('Failed to delete voice note', originalError: e);
    }
  }
}
