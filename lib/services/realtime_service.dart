import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Riverpod provider for RealtimeService
final realtimeServiceProvider = Provider<RealtimeService>((ref) => RealtimeService());

/// Supabase Realtime Service — Handing WebSockets specific real-time logic.
/// Useful for observing live INSERTS/UPDATES outside of standard streaming hooks.
class RealtimeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Subscribe to all messages for a specific chat
  /// Triggers on every INSERT operation into the 'messages' table for the chatId
  RealtimeChannel subscribeToChatMessages({
    required String chatId,
    required void Function(Map<String, dynamic> payload) onMessageReceived,
  }) {
    final channel = _supabase.channel('public:messages:chat_id=eq.$chatId');
    
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'chatId',
        value: chatId,
      ),
      callback: (PostgresChangePayload payload) {
        onMessageReceived(payload.newRecord);
      },
    ).subscribe();

    return channel;
  }

  /// Subscribe to a user's presence/status updates (online/offline)
  RealtimeChannel subscribeToUserStatus({
    required String userId,
    required void Function(Map<String, dynamic> payload) onStatusUpdate,
  }) {
    final channel = _supabase.channel('public:users:id=eq.$userId');
    
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'users',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id', // Assuming your user table has an 'id' column matching the user
        value: userId,
      ),
      callback: (PostgresChangePayload payload) {
        onStatusUpdate(payload.newRecord);
      },
    ).subscribe();

    return channel;
  }

  /// Unsubscribe from a specific realtime channel to free resources
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }

  /// Clean up and remove all active realtime channels 
  /// (e.g., when the user signs out)
  Future<void> unsubscribeAll() async {
    await _supabase.removeAllChannels();
  }
}
