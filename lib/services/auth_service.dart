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
  // Removed Google OAuth Auth
  // ─────────────────────────────────────────────

  // ─────────────────────────────────────────────
  // Email/Password Auth
  // ─────────────────────────────────────────────

  /// Sign in with email and password
  Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw AppAuthException('Sign-in failed: $e', originalError: e);
    }
  }

  /// Sign up with email and password
  Future<void> signUpWithEmailPassword(String email, String password, String username) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );
    } catch (e) {
      throw AppAuthException('Sign-up failed: $e', originalError: e);
    }
  }

  /// Send forgot password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb ? Uri.base.origin : 'io.supabase.alfloest://reset-password/',
      );
    } catch (e) {
      throw AppAuthException('Failed to send reset email: $e', originalError: e);
    }
  }

  /// Reset/update password for user
  Future<void> resetPassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw AppAuthException('Failed to update password: $e', originalError: e);
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
