import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../core/enums/enums.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

class SessionUser {
  final String uid;
  SessionUser(this.uid);
}

final authStateProvider = StreamProvider<SessionUser?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges.asyncMap((e) async {
    final user = e.session?.user;
    if (user != null) {
      // Auto-sync profile on auth state event to ensure profile is created 
      // immediately after successful Google login redirect
      try {
        await repo.createOrUpdateUser(user);
      } catch (_) {} // Ignore initial fetch errors if any
      return SessionUser(user.id);
    }
    return null;
  });
});

class AuthViewModel extends StateNotifier<AuthViewState> {
  final AuthRepository _repo;

  AuthViewModel(this._repo) : super(const AuthViewState());



  Future<void> signInWithEmailPassword(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.signInWithEmailPassword(email, password);
      state = state.copyWith(isLoading: false, status: AuthStatus.authenticated);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signUpWithEmailPassword(String email, String password, String username) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.signUpWithEmailPassword(email, password, username);
      state = state.copyWith(isLoading: false, status: AuthStatus.authenticated);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _repo.signOut();
    state = const AuthViewState(status: AuthStatus.unauthenticated);
  }
}

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthViewState>((ref) {
  return AuthViewModel(ref.watch(authRepositoryProvider));
});

class AuthViewState {
  final AuthStatus status;
  final bool isLoading;
  final String? error;

  const AuthViewState({
    this.status = AuthStatus.initial,
    this.isLoading = false,
    this.error,
  });

  AuthViewState copyWith({
    AuthStatus? status,
    bool? isLoading,
    String? error,
  }) {
    return AuthViewState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
