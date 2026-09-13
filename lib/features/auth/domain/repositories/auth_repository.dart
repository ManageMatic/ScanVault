import '../models/auth_user.dart';

/// Abstract interface for authentication operations.
abstract class AuthRepository {
  /// Stream of authentication state changes.
  Stream<AuthUser?> get authStateChanges;

  /// Returns currently signed-in user or null if unauthenticated.
  AuthUser? get currentUser;

  /// Register user with email and password.
  Future<AuthUser> signUp({
    required String name,
    required String email,
    required String password,
  });

  /// Sign in user with email and password.
  Future<AuthUser> signIn({
    required String email,
    required String password,
  });

  /// Trigger OAuth Google sign-in.
  Future<void> signInWithGoogle();

  /// Send password reset link to user email.
  Future<void> resetPassword({required String email});

  /// Sign out current user.
  Future<void> signOut();
}
