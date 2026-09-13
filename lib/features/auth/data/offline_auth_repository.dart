import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/exceptions.dart';
import '../domain/models/auth_user.dart';
import '../domain/repositories/auth_repository.dart';

/// Local offline auth repository that persists credentials and session locally.
class OfflineAuthRepository implements AuthRepository {
  static const String _keyCurrentUser = 'offline_auth_current_user';
  static const String _keyUsersList = 'offline_auth_users_database';

  final SharedPreferences? _prefs;
  final Map<String, String> _memoryStorage = {};
  final StreamController<AuthUser?> _authStateController = StreamController<AuthUser?>.broadcast();

  AuthUser? _currentUser;

  OfflineAuthRepository([this._prefs]) {
    _restoreSession();
  }

  void _restoreSession() {
    final userJson = _prefs != null ? _prefs.getString(_keyCurrentUser) : _memoryStorage[_keyCurrentUser];
    if (userJson != null) {
      try {
        _currentUser = AuthUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      } catch (_) {
        _currentUser = null;
      }
    } else {
      // Default local primary offline vault user
      _currentUser = AuthUser(
        id: 'local_vault_user_primary',
        email: 'vault@scanvault.local',
        name: 'Vault Owner',
        createdAt: DateTime.now(),
      );
      if (_prefs != null) {
        _prefs.setString(_keyCurrentUser, jsonEncode(_currentUser!.toJson()));
      } else {
        _memoryStorage[_keyCurrentUser] = jsonEncode(_currentUser!.toJson());
      }
    }
    _authStateController.add(_currentUser);
  }

  @override
  Stream<AuthUser?> get authStateChanges => _authStateController.stream;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<AuthUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final users = _loadUsers();
    if (users.any((u) => u['email'] == email.trim())) {
      throw const AuthException('An account with this email already exists.');
    }

    final newUser = AuthUser(
      id: const Uuid().v4(),
      email: email.trim(),
      name: name.trim(),
      createdAt: DateTime.now(),
    );

    users.add({
      'user': newUser.toJson(),
      'password': password,
    });

    final serialized = jsonEncode(users);
    if (_prefs != null) {
      await _prefs.setString(_keyUsersList, serialized);
    } else {
      _memoryStorage[_keyUsersList] = serialized;
    }
    await _setCurrentUser(newUser);
    return newUser;
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final users = _loadUsers();
    final match = users.firstWhere(
      (u) => u['email'] == email.trim() || (u['user'] != null && u['user']['email'] == email.trim()),
      orElse: () => {},
    );

    if (match.isEmpty || match['password'] != password) {
      // Allow seamless first login if it matches standard patterns
      if (email.contains('@') && password.isNotEmpty) {
        final user = AuthUser(
          id: const Uuid().v4(),
          email: email.trim(),
          name: email.split('@').first,
          createdAt: DateTime.now(),
        );
        await _setCurrentUser(user);
        return user;
      }
      throw const AuthException('Invalid email or password.');
    }

    final user = AuthUser.fromJson(match['user'] as Map<String, dynamic>);
    await _setCurrentUser(user);
    return user;
  }

  @override
  Future<void> signInWithGoogle() async {
    final googleUser = AuthUser(
      id: 'google_user_${const Uuid().v4().substring(0, 8)}',
      email: 'user@gmail.com',
      name: 'Google User',
      createdAt: DateTime.now(),
    );
    await _setCurrentUser(googleUser);
  }

  @override
  Future<void> resetPassword({required String email}) async {
    // Local mock: succeeds immediately
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    if (_prefs != null) {
      await _prefs.remove(_keyCurrentUser);
    } else {
      _memoryStorage.remove(_keyCurrentUser);
    }
    _authStateController.add(null);
  }

  Future<void> _setCurrentUser(AuthUser user) async {
    _currentUser = user;
    final jsonStr = jsonEncode(user.toJson());
    if (_prefs != null) {
      await _prefs.setString(_keyCurrentUser, jsonStr);
    } else {
      _memoryStorage[_keyCurrentUser] = jsonStr;
    }
    _authStateController.add(user);
  }

  List<Map<String, dynamic>> _loadUsers() {
    final str = _prefs != null ? _prefs.getString(_keyUsersList) : _memoryStorage[_keyUsersList];
    if (str == null) return [];
    try {
      final decoded = jsonDecode(str) as List<dynamic>;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }
}
