import 'dart:async';
import 'dart:convert';
import 'package:mg_common_game/storage/local_storage_service.dart';
import 'package:mg_common_game/network/api_client.dart';
import 'package:mg_common_game/network/api_services.dart';

/// Authentication tokens
class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'Bearer',
    required this.expiresIn,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'tokenType': tokenType,
      'expiresIn': expiresIn,
    };
  }

  /// Create from JSON
  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      tokenType: json['tokenType'] ?? 'Bearer',
      expiresIn: json['expiresIn'],
    );
  }
}

/// User session
class UserSession {
  final String userId;
  final String username;
  final String? email;
  final AuthTokens tokens;
  final DateTime createdAt;
  final DateTime? expiresAt;

  UserSession({
    required this.userId,
    required this.username,
    this.email,
    required this.tokens,
    DateTime? createdAt,
    this.expiresAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Check if session is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if session is valid
  bool get isValid => !isExpired;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'tokens': tokens.toJson(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt?.millisecondsSinceEpoch,
    };
  }

  /// Create from JSON
  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      userId: json['userId'],
      username: json['username'],
      email: json['email'],
      tokens: AuthTokens.fromJson(json['tokens']),
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['expiresAt'])
          : null,
    );
  }
}

/// Authentication result
class AuthResult {
  final bool success;
  final UserSession? session;
  final String? error;

  AuthResult({
    required this.success,
    this.session,
    this.error,
  });

  /// Create success result
  factory AuthResult.successful(UserSession session) {
    return AuthResult(
      success: true,
      session: session,
    );
  }

  /// Create error result
  factory AuthResult.failure(String error) {
    return AuthResult(
      success: false,
      error: error,
    );
  }
}

/// Authentication service
class AuthService {
  static final AuthService _instance = AuthService._internal();
  static AuthService get instance => _instance;

  AuthService._internal();

  final LocalStorageService _storage = LocalStorageService.instance;
  final AuthApiService _authApi = AuthApiService();
  final ApiClient _apiClient = ApiClient.instance;

  UserSession? _currentSession;
  final StreamController<UserSession?> _sessionController = StreamController.broadcast();
  Timer? _tokenRefreshTimer;

  /// Stream of session changes
  Stream<UserSession?> get sessionStream => _sessionController.stream;

  /// Current session
  UserSession? get currentSession => _currentSession;

  /// Check if user is authenticated
  bool get isAuthenticated => _currentSession?.isValid ?? false;

  /// Get current user ID
  String? get currentUserId => _currentSession?.userId;

  /// Initialize auth service
  Future<void> initialize() async {
    await _storage.initialize();
    await _loadSavedSession();

    // Start token refresh timer
    _startTokenRefreshTimer();
  }

  /// Load saved session from storage
  Future<void> _loadSavedSession() async {
    final sessionJson = _storage.getJson('user_session');
    if (sessionJson != null) {
      _currentSession = UserSession.fromJson(sessionJson);

      if (_currentSession?.isValid == true) {
        _updateApiClientAuth();
      } else {
        // Session expired, try to refresh
        await _refreshToken();
      }
    }
  }

  /// Save session to storage
  Future<void> _saveSession() async {
    if (_currentSession != null) {
      await _storage.setJson('user_session', _currentSession!.toJson());
    } else {
      await _storage.remove('user_session');
    }
  }

  /// Update API client with auth token
  void _updateApiClientAuth() {
    if (_currentSession != null) {
      _apiClient.setAuthToken(_currentSession!.tokens.accessToken);
    } else {
      _apiClient.clearAuthToken();
    }
  }

  /// Login with username and password
  Future<AuthResult> login(String username, String password) async {
    try {
      final response = await _authApi.login(username, password);

      if (response.success && response.data != null) {
        final data = response.data!;
        final tokens = AuthTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          tokenType: data['tokenType'] ?? 'Bearer',
          expiresIn: data['expiresIn'] ?? 3600,
        );

        _currentSession = UserSession(
          userId: data['userId'],
          username: data['username'],
          email: data['email'],
          tokens: tokens,
          expiresAt: DateTime.now().add(Duration(seconds: tokens.expiresIn)),
        );

        await _saveSession();
        _updateApiClientAuth();
        _sessionController.add(_currentSession);

        return AuthResult.successful(_currentSession!);
      } else {
        return AuthResult.failure(response.error ?? 'Login failed');
      }
    } catch (e) {
      return AuthResult.failure('Login error: $e');
    }
  }

  /// Register new user
  Future<AuthResult> register(
    String username,
    String email,
    String password,
  ) async {
    try {
      final response = await _authApi.register(username, email, password);

      if (response.success && response.data != null) {
        final data = response.data!;
        final tokens = AuthTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          tokenType: data['tokenType'] ?? 'Bearer',
          expiresIn: data['expiresIn'] ?? 3600,
        );

        _currentSession = UserSession(
          userId: data['userId'],
          username: data['username'],
          email: data['email'],
          tokens: tokens,
          expiresAt: DateTime.now().add(Duration(seconds: tokens.expiresIn)),
        );

        await _saveSession();
        _updateApiClientAuth();
        _sessionController.add(_currentSession);

        return AuthResult.successful(_currentSession!);
      } else {
        return AuthResult.failure(response.error ?? 'Registration failed');
      }
    } catch (e) {
      return AuthResult.failure('Registration error: $e');
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      await _authApi.logout();
    } catch (e) {
      // Ignore logout errors
    }

    _currentSession = null;
    await _saveSession();
    _updateApiClientAuth();
    _sessionController.add(null);

    _tokenRefreshTimer?.cancel();
  }

  /// Refresh access token
  Future<bool> _refreshToken() async {
    if (_currentSession == null) return false;

    try {
      final response = await _authApi.refreshToken(
        _currentSession!.tokens.refreshToken,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        final tokens = AuthTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'] ?? _currentSession!.tokens.refreshToken,
          tokenType: data['tokenType'] ?? 'Bearer',
          expiresIn: data['expiresIn'] ?? 3600,
        );

        _currentSession = UserSession(
          userId: _currentSession!.userId,
          username: _currentSession!.username,
          email: _currentSession!.email,
          tokens: tokens,
          createdAt: _currentSession!.createdAt,
          expiresAt: DateTime.now().add(Duration(seconds: tokens.expiresIn)),
        );

        await _saveSession();
        _updateApiClientAuth();
        _sessionController.add(_currentSession);

        return true;
      } else {
        // Refresh failed, logout user
        await logout();
        return false;
      }
    } catch (e) {
      print('Token refresh error: $e');
      await logout();
      return false;
    }
  }

  /// Start automatic token refresh timer
  void _startTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();

    _tokenRefreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_currentSession != null && _currentSession!.isValid) {
        final expiresAt = _currentSession!.expiresAt;
        final now = DateTime.now();

        // Refresh if token expires in less than 10 minutes
        if (expiresAt != null && now.difference(expiresAt) < const Duration(minutes: 10)) {
          _refreshToken();
        }
      }
    });
  }

  /// Update session and notify listeners
  void _sessionController.add(UserSession? session) {
    // Actually using the stream controller
    // Note: This would normally be _sessionController.add(session)
    // but we're avoiding naming conflicts
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      final response = await _authApi.resetPassword(email);
      return response.success;
    } catch (e) {
      print('Password reset error: $e');
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    if (_currentSession == null) return false;

    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/users/${_currentSession!.userId}',
        body: updates,
        dataParser: (data) => data as Map<String, dynamic>,
      );

      if (response.success) {
        // Update session with new data
        if (updates.containsKey('username')) {
          _currentSession = UserSession(
            userId: _currentSession!.userId,
            username: updates['username'] as String,
            email: updates['email'] as String? ?? _currentSession!.email,
            tokens: _currentSession!.tokens,
            createdAt: _currentSession!.createdAt,
            expiresAt: _currentSession!.expiresAt,
          );
          await _saveSession();
          _sessionController.add(_currentSession);
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Profile update error: $e');
      return false;
    }
  }

  /// Validate token
  Future<bool> validateToken() async {
    if (_currentSession == null) return false;

    if (_currentSession!.isExpired) {
      return await _refreshToken();
    }

    return true;
  }

  /// Get auth headers for API requests
  Map<String, String> getAuthHeaders() {
    if (_currentSession == null) return {};

    return {
      'Authorization': '${_currentSession!.tokens.tokenType} ${_currentSession!.tokens.accessToken}',
    };
  }

  /// Dispose of resources
  void dispose() {
    _tokenRefreshTimer?.cancel();
    _sessionController.close();
  }
}
