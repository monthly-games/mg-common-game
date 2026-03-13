import 'dart:async';
import 'package:flutter/material.dart';

enum AuthProvider {
  email,
  google,
  apple,
  facebook,
  twitter,
  guest,
}

enum AuthStatus {
  authenticated,
  unauthenticated,
  unknown,
}

class AuthUser {
  final String userId;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final AuthProvider provider;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  const AuthUser({
    required this.userId,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.provider,
    required this.emailVerified,
    required this.createdAt,
    required this.lastLoginAt,
  });

  AuthUser copyWith({
    String? userId,
    String? email,
    String? displayName,
    String? photoUrl,
    AuthProvider? provider,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return AuthUser(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      provider: provider ?? this.provider,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

class AuthSession {
  final String sessionId;
  final String userId;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final DateTime createdAt;
  final String? deviceId;

  const AuthSession({
    required this.sessionId,
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.createdAt,
    this.deviceId,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  Duration get remainingTime => expiresAt.difference(DateTime.now());
}

class AuthCredential {
  final String provider;
  final String? email;
  final String? password;
  final String? accessToken;
  final String? idToken;
  final String? secret;

  const AuthCredential({
    required this.provider,
    this.email,
    this.password,
    this.accessToken,
    this.idToken,
    this.secret,
  });
}

class AuthenticationManager {
  static final AuthenticationManager _instance = AuthenticationManager._();
  static AuthenticationManager get instance => _instance;

  AuthenticationManager._();

  AuthUser? _currentUser;
  AuthSession? _currentSession;
  final Map<String, AuthUser> _users = {};
  final Map<String, AuthSession> _sessions = {};
  final StreamController<AuthEvent> _eventController = StreamController.broadcast();
  Timer? _tokenRefreshTimer;

  Stream<AuthEvent> get onAuthEvent => _eventController.stream;
  AuthUser? get currentUser => _currentUser;
  AuthSession? get currentSession => _currentSession;
  bool get isAuthenticated => _currentUser != null;
  AuthStatus get authStatus {
    if (_currentUser != null) return AuthStatus.authenticated;
    return AuthStatus.unauthenticated;
  }

  Future<void> initialize() async {
    _startTokenRefreshTimer();
  }

  void _startTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _refreshTokenIfNeeded(),
    );
  }

  Future<AuthResult> signIn(AuthCredential credential) async {
    try {
      AuthUser? user;

      switch (credential.provider) {
        case 'email':
          user = await _signInWithEmail(credential);
          break;
        case 'google':
          user = await _signInWithGoogle(credential);
          break;
        case 'apple':
          user = await _signInWithApple(credential);
          break;
        case 'facebook':
          user = await _signInWithFacebook(credential);
          break;
        case 'twitter':
          user = await _signInWithTwitter(credential);
          break;
        case 'guest':
          user = await _signInAsGuest();
          break;
        default:
          return AuthResult(
            success: false,
            error: 'Unsupported auth provider',
          );
      }

      if (user == null) {
        return AuthResult(
          success: false,
          error: 'Authentication failed',
        );
      }

      _currentUser = user;
      _users[user.userId] = user;

      final session = await _createSession(user.userId);
      _currentSession = session;

      _eventController.add(AuthEvent(
        type: AuthEventType.signedIn,
        userId: user.userId,
        timestamp: DateTime.now(),
      ));

      return AuthResult(
        success: true,
        user: user,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<AuthUser?> _signInWithEmail(AuthCredential credential) async {
    final email = credential.email;
    final password = credential.password;

    if (email == null || password == null) {
      return null;
    }

    final user = _users.values.firstWhere(
      (u) => u.email == email,
      orElse: () => _createNewUser(
        email: email,
        provider: AuthProvider.email,
      ),
    );

    return user.copyWith(lastLoginAt: DateTime.now());
  }

  Future<AuthUser?> _signInWithGoogle(AuthCredential credential) async {
    return _createNewUser(
      email: 'user_${DateTime.now().millisecondsSinceEpoch}@google.com',
      provider: AuthProvider.google,
      displayName: 'Google User',
    );
  }

  Future<AuthUser?> _signInWithApple(AuthCredential credential) async {
    return _createNewUser(
      email: 'user_${DateTime.now().millisecondsSinceEpoch}@apple.com',
      provider: AuthProvider.apple,
      displayName: 'Apple User',
    );
  }

  Future<AuthUser?> _signInWithFacebook(AuthCredential credential) async {
    return _createNewUser(
      email: 'user_${DateTime.now().millisecondsSinceEpoch}@facebook.com',
      provider: AuthProvider.facebook,
      displayName: 'Facebook User',
    );
  }

  Future<AuthUser?> _signInWithTwitter(AuthCredential credential) async {
    return _createNewUser(
      email: 'user_${DateTime.now().millisecondsSinceEpoch}@twitter.com',
      provider: AuthProvider.twitter,
      displayName: 'Twitter User',
    );
  }

  Future<AuthUser?> _signInAsGuest() async {
    return _createNewUser(
      email: 'guest_${DateTime.now().millisecondsSinceEpoch}@guest.com',
      provider: AuthProvider.guest,
      displayName: 'Guest',
    );
  }

  AuthUser _createNewUser({
    required String email,
    required AuthProvider provider,
    String? displayName,
    String? photoUrl,
    bool emailVerified = false,
  }) {
    return AuthUser(
      userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      provider: provider,
      emailVerified: emailVerified,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
  }

  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final existingUser = _users.values.firstWhere(
        (u) => u.email == email,
        orElse: () => _users.values.first,
      );

      if (existingUser.email == email) {
        return AuthResult(
          success: false,
          error: 'Email already exists',
        );
      }

      final user = _createNewUser(
        email: email,
        provider: AuthProvider.email,
        displayName: displayName ?? email.split('@')[0],
      );

      _users[user.userId] = user;
      _currentUser = user;

      final session = await _createSession(user.userId);
      _currentSession = session;

      _eventController.add(AuthEvent(
        type: AuthEventType.signedUp,
        userId: user.userId,
        timestamp: DateTime.now(),
      ));

      return AuthResult(
        success: true,
        user: user,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    final userId = _currentUser?.userId;
    final sessionId = _currentSession?.sessionId;

    _currentUser = null;
    _sessions.remove(sessionId);
    _currentSession = null;

    if (userId != null) {
      _eventController.add(AuthEvent(
        type: AuthEventType.signedOut,
        userId: userId,
        timestamp: DateTime.now(),
      ));
    }
  }

  Future<AuthResult> refreshAccessToken() async {
    if (_currentSession == null) {
      return AuthResult(
        success: false,
        error: 'No active session',
      );
    }

    final newSession = await _createSession(_currentSession!.userId);
    _currentSession = newSession;

    return AuthResult(success: true);
  }

  Future<AuthSession> _createSession(String userId) async {
    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    final expiresAt = DateTime.now().add(const Duration(hours: 24));

    final session = AuthSession(
      sessionId: sessionId,
      userId: userId,
      accessToken: _generateToken(),
      refreshToken: _generateToken(),
      expiresAt: expiresAt,
      createdAt: DateTime.now(),
    );

    _sessions[sessionId] = session;
    return session;
  }

  String _generateToken() {
    return 'token_${DateTime.now().millisecondsSinceEpoch}_${_randomString(32)}';
  }

  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String result = '';
    for (int i = 0; i < length; i++) {
      result += chars[(random + i) % chars.length];
    }
    return result;
  }

  void _refreshTokenIfNeeded() {
    if (_currentSession == null) return;
    if (_currentSession!.isExpired) {
      refreshAccessToken();
    }
  }

  Future<AuthResult> sendPasswordResetEmail(String email) async {
    final user = _users.values.firstWhere(
      (u) => u.email == email,
      orElse: () => _users.values.first,
    );

    if (user.email != email) {
      return AuthResult(
        success: false,
        error: 'User not found',
      );
    }

    _eventController.add(AuthEvent(
      type: AuthEventType.passwordResetEmailSent,
      userId: user.userId,
      timestamp: DateTime.now(),
    ));

    return AuthResult(success: true);
  }

  Future<AuthResult> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    return AuthResult(success: true);
  }

  Future<AuthResult> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) {
      return AuthResult(
        success: false,
        error: 'No user signed in',
      );
    }

    _eventController.add(AuthEvent(
      type: AuthEventType.passwordChanged,
      userId: _currentUser!.userId,
      timestamp: DateTime.now(),
    ));

    return AuthResult(success: true);
  }

  Future<AuthResult> updateEmail(String newEmail) async {
    if (_currentUser == null) {
      return AuthResult(
        success: false,
        error: 'No user signed in',
      );
    }

    final updatedUser = _currentUser!.copyWith(email: newEmail);
    _users[_currentUser!.userId] = updatedUser;
    _currentUser = updatedUser;

    _eventController.add(AuthEvent(
      type: AuthEventType.emailChanged,
      userId: _currentUser!.userId,
      timestamp: DateTime.now(),
    ));

    return AuthResult(success: true);
  }

  Future<AuthResult> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    if (_currentUser == null) {
      return AuthResult(
        success: false,
        error: 'No user signed in',
      );
    }

    final updatedUser = _currentUser!.copyWith(
      displayName: displayName,
      photoUrl: photoUrl,
    );
    _users[_currentUser!.userId] = updatedUser;
    _currentUser = updatedUser;

    return AuthResult(success: true);
  }

  Future<void> deleteAccount() async {
    final userId = _currentUser?.userId;
    if (userId == null) return;

    _users.remove(userId);
    await signOut();

    _eventController.add(AuthEvent(
      type: AuthEventType.accountDeleted,
      userId: userId,
      timestamp: DateTime.now(),
    ));
  }

  void dispose() {
    _tokenRefreshTimer?.cancel();
    _eventController.close();
  }
}

class AuthResult {
  final bool success;
  final AuthUser? user;
  final String? error;

  const AuthResult({
    required this.success,
    this.user,
    this.error,
  });
}

class AuthEvent {
  final AuthEventType type;
  final String? userId;
  final DateTime timestamp;

  const AuthEvent({
    required this.type,
    this.userId,
    required this.timestamp,
  });
}

enum AuthEventType {
  signedIn,
  signedOut,
  signedUp,
  passwordResetEmailSent,
  passwordChanged,
  emailChanged,
  accountDeleted,
  tokenRefreshed,
}
