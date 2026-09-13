import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser, AuthException;
import '../../../../core/errors/exceptions.dart';
import '../domain/models/auth_user.dart';
import '../domain/repositories/auth_repository.dart';

/// Concrete Supabase Auth implementation.
class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _supabaseClient;
  final StreamController<AuthUser?> _authStateController = StreamController<AuthUser?>.broadcast();

  String? _extractAvatarUrl(User user) {
    final meta = user.userMetadata;
    if (meta != null) {
      if (meta['avatar_url'] is String && (meta['avatar_url'] as String).isNotEmpty) {
        return meta['avatar_url'] as String;
      }
      if (meta['picture'] is String && (meta['picture'] as String).isNotEmpty) {
        return meta['picture'] as String;
      }
      if (meta['avatar'] is String && (meta['avatar'] as String).isNotEmpty) {
        return meta['avatar'] as String;
      }
    }
    if (user.identities != null) {
      for (final identity in user.identities!) {
        final idData = identity.identityData;
        if (idData != null) {
          if (idData['avatar_url'] is String && (idData['avatar_url'] as String).isNotEmpty) {
            return idData['avatar_url'] as String;
          }
          if (idData['picture'] is String && (idData['picture'] as String).isNotEmpty) {
            return idData['picture'] as String;
          }
        }
      }
    }
    return null;
  }

  String _extractName(User user) {
    final meta = user.userMetadata;
    if (meta != null) {
      if (meta['full_name'] is String && (meta['full_name'] as String).isNotEmpty) {
        return meta['full_name'] as String;
      }
      if (meta['name'] is String && (meta['name'] as String).isNotEmpty) {
        return meta['name'] as String;
      }
    }
    if (user.identities != null) {
      for (final identity in user.identities!) {
        final idData = identity.identityData;
        if (idData != null) {
          if (idData['full_name'] is String && (idData['full_name'] as String).isNotEmpty) {
            return idData['full_name'] as String;
          }
          if (idData['name'] is String && (idData['name'] as String).isNotEmpty) {
            return idData['name'] as String;
          }
        }
      }
    }
    return user.email?.split('@').first ?? 'User';
  }

  SupabaseAuthRepository([SupabaseClient? client])
      : _supabaseClient = client ?? Supabase.instance.client {
    _supabaseClient.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final user = session?.user;
      if (user != null) {
        _authStateController.add(AuthUser(
          id: user.id,
          email: user.email ?? '',
          name: _extractName(user),
          avatarUrl: _extractAvatarUrl(user),
          createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
        ));
      } else {
        _authStateController.add(null);
      }
    });
  }

  @override
  Stream<AuthUser?> get authStateChanges => _authStateController.stream;

  @override
  AuthUser? get currentUser {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) return null;
    return AuthUser(
      id: user.id,
      email: user.email ?? '',
      name: _extractName(user),
      avatarUrl: _extractAvatarUrl(user),
      createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
    );
  }

  @override
  Future<AuthUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final res = await _supabaseClient.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'name': name.trim()},
      );
      final user = res.user;
      if (user == null) {
        throw const AuthException('Registration failed. Please check credentials.');
      }
      return AuthUser(
        id: user.id,
        email: user.email ?? email,
        name: name,
        createdAt: DateTime.now(),
      );
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _supabaseClient.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = res.user;
      if (user == null) {
        throw const AuthException('Invalid login credentials.');
      }
      final name = user.userMetadata?['name'] as String? ?? email.split('@').first;
      return AuthUser(
        id: user.id,
        email: user.email ?? email,
        name: name,
        createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
      );
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      await _supabaseClient.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'scanvault://login-callback',
      );
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> resetPassword({required String email}) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'scanvault://reset-callback',
      );
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabaseClient.auth.signOut();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
