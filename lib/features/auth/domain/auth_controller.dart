import 'package:flutter/material.dart';
import 'models/auth_user.dart';
import 'repositories/auth_repository.dart';

/// Controller managing auth state, errors, and authentication actions.
class AuthController extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthController(this._authRepository) {
    _currentUser = _authRepository.currentUser;
    _authRepository.authStateChanges.listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  AuthUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _currentUser = await _authRepository.signIn(email: email, password: password);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = _parseErrorMessage(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _currentUser = await _authRepository.signUp(name: name, email: email, password: password);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = _parseErrorMessage(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authRepository.signInWithGoogle();
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = _parseErrorMessage(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resetPassword({required String email}) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authRepository.resetPassword(email: email);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = _parseErrorMessage(e);
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authRepository.signOut();
      _currentUser = null;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _parseErrorMessage(dynamic error) {
    final str = error.toString().toLowerCase();
    if (str.contains('invalid login') || str.contains('invalid credentials') || str.contains('invalid email or password')) {
      return 'Invalid email or password.';
    }
    if (str.contains('already exists') || str.contains('user already registered')) {
      return 'An account with this email already exists.';
    }
    if (str.contains('socket') || str.contains('network') || str.contains('connection')) {
      return 'Unable to connect. Please check your internet connection.';
    }
    return error.toString().replaceAll('Exception:', '').trim();
  }
}
