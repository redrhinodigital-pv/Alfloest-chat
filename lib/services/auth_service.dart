import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors/exceptions.dart';

// Riverpod provider for AuthService to keep architecture clean
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Auth Service handling user authentication using Supabase
class AuthService {
  // Get the Supabase client instance
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Returns the currently authenticated user (null if not logged in)
  User? get currentUser => _supabase.auth.currentUser;

  /// Current user UID (nullable)
  String? get currentUid => _supabase.auth.currentUser?.id;

  /// Stream of authentication state changes (handles auto-refresh & session persistence)
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Check if a user is currently signed in
  bool get isSignedIn => _supabase.auth.currentUser != null;

  // ─────────────────────────────────────────────
  // Google OAuth Auth
  // ─────────────────────────────────────────────

  /// Sign in with Google securely across Web and Native.
  /// Uses Supabase's built-in OAuth flow which cleanly redirects via browser.
  Future<void> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        // On Web, passing null dynamically redirects back to the current window.location.origin
        // Ensure you configure "http://localhost:3000" or your production domain in Supabase -> Authentication -> URL Configuration
        redirectTo: kIsWeb ? null : 'io.supabase.alfloest://login-callback/',
      );
    } catch (e) {
      throw AppAuthException('Google sign-in failed: $e', originalError: e);
    }
  }

  // ─────────────────────────────────────────────
  // Session Management
  // ─────────────────────────────────────────────

  /// Sign out the current user securely from Supabase
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw AppAuthException('Sign out failed', originalError: e);
    }
  }
}
