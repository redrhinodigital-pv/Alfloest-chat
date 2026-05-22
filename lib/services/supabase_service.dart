import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Riverpod provider for SupabaseService
final supabaseServiceProvider = Provider<SupabaseService>((ref) => SupabaseService());

/// Helper utility for handling streams with automatic retry logic
class StreamUtils {
  /// Wraps a stream callback with automatic retry logic on error/timeout.
  /// Suppresses raw errors from propagating to the UI directly.
  static Stream<T> retryStream<T>(
    Stream<T> Function() streamFactory, {
    Duration delay = const Duration(seconds: 3),
    int? maxRetries,
  }) {
    late StreamController<T> controller;
    StreamSubscription<T>? subscription;
    int attempt = 0;
    bool isClosed = false;

    void startListening() {
      if (isClosed) return;
      
      try {
        final stream = streamFactory();
        subscription = stream.listen(
          (data) {
            attempt = 0; // Reset attempt count on successful data
            if (!controller.isClosed) {
              controller.add(data);
            }
          },
          onError: (error) {
            debugPrint('StreamUtils: Error in stream (attempt $attempt): $error');
            subscription?.cancel();
            
            if (isClosed || controller.isClosed) return;

            attempt++;
            if (maxRetries != null && attempt >= maxRetries) {
              controller.addError(error);
              return;
            }

            Future.delayed(delay, () {
              startListening();
            });
          },
          onDone: () {
            if (!controller.isClosed) {
              controller.close();
            }
          },
          cancelOnError: false,
        );
      } catch (e) {
        debugPrint('StreamUtils: Exception creating stream (attempt $attempt): $e');
        if (isClosed || controller.isClosed) return;
        
        attempt++;
        if (maxRetries != null && attempt >= maxRetries) {
          controller.addError(e);
          return;
        }
        
        Future.delayed(delay, () {
          startListening();
        });
      }
    }

    controller = StreamController<T>(
      onListen: () {
        attempt = 0;
        startListening();
      },
      onCancel: () {
        isClosed = true;
        subscription?.cancel();
      },
    );

    return controller.stream;
  }
}

/// Supabase Database Core Service — Generic CRUD operations wrapper
class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Public getter to access raw Supabase client if absolutely needed by repositories
  SupabaseClient get client => _supabase;
  SupabaseClient get db => _supabase;

  // ─────────────────────────────────────────────
  // Standard CRUD Methods
  // ─────────────────────────────────────────────

  /// Insert a single row into a table
  Future<void> insertRow({
    required String table, 
    required Map<String, dynamic> data,
  }) async {
    await _supabase.from(table).insert(data);
  }

  /// Update a specific row matching the ID
  Future<void> updateRow({
    required String table, 
    required String id, 
    required Map<String, dynamic> data,
  }) async {
    await _supabase.from(table).update(data).eq('id', id);
  }
  
  /// Upsert (Update if exists, Insert if missing)
  Future<void> upsertRow({
    required String table, 
    required Map<String, dynamic> data,
  }) async {
    await _supabase.from(table).upsert(data);
  }

  /// Fetch a single row by ID
  Future<Map<String, dynamic>?> getRow({
    required String table, 
    required String id,
  }) async {
    return await _supabase.from(table).select().eq('id', id).maybeSingle();
  }

  /// Delete a specific row by ID
  Future<void> deleteRow({
    required String table, 
    required String id,
  }) async {
    await _supabase.from(table).delete().eq('id', id);
  }

  // ─────────────────────────────────────────────
  // Streaming (via Supabase streamBuilder logic)
  // ─────────────────────────────────────────────

  /// Stream a table (Useful for lists like chat threads)
  Stream<List<Map<String, dynamic>>> streamTable({
    required String table,
    String? eqField,
    dynamic eqValue,
    String orderBy = 'created_at',
    bool ascending = false,
  }) {
    if (eqField != null) {
      return _supabase.from(table).stream(primaryKey: ['id'])
          .eq(eqField, eqValue)
          .order(orderBy, ascending: ascending);
    }
    return _supabase.from(table).stream(primaryKey: ['id'])
        .order(orderBy, ascending: ascending);
  }

  /// Stream a specific row by ID (Useful for real-time profile/status updates)
  Stream<Map<String, dynamic>?> streamRow({
    required String table, 
    required String id,
  }) {
    return _supabase.from(table).stream(primaryKey: ['id']).eq('id', id)
        .map((list) => list.isNotEmpty ? list.first : null);
  }
}
