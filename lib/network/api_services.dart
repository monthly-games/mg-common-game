import 'package:mg_common_game/network/api_client.dart';

/// User API service
class UserApiService {
  final ApiClient _client = ApiClient.instance;

  /// Get user profile
  Future<ApiResponse<Map<String, dynamic>>> getUserProfile(String userId) async {
    return await _client.get<Map<String, dynamic>>(
      '/users/$userId',
      dataParser: (data) => data as Map<String, dynamic>,
    );
  }

  /// Update user profile
  Future<ApiResponse<Map<String, dynamic>>> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    return await _client.put<Map<String, dynamic>>(
      '/users/$userId',
      body: updates,
      dataParser: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get user progress
  Future<ApiResponse<Map<String, dynamic>>> getUserProgress(String userId) async {
    return await _client.get<Map<String, dynamic>>(
      '/users/$userId/progress',
      dataParser: (data) => data as Map<String, dynamic>,
    );
  }

  /// Update user settings
  Future<ApiResponse<void>> updateUserSettings(
    String userId,
    Map<String, dynamic> settings,
  ) async {
    return await _client.put<void>(
      '/users/$userId/settings',
      body: settings,
      dataParser: (_) => null,
    );
  }

  /// Delete user account
  Future<ApiResponse<void>> deleteUser(String userId) async {
    return await _client.delete<void>(
      '/users/$userId',
      dataParser: (_) => null,
    );
  }
}

/// Inventory API service
class InventoryApiService {
  final ApiClient _client = ApiClient.instance;

  /// Get user inventory
  Future<ApiResponse<List<Map<String, dynamic>>>> getInventory(String userId) async {
    return await _client.get<List<Map<String, dynamic>>>(
      '/inventory/$userId',
      dataParser: (data) => (data['items'] as List).cast<Map<String, dynamic>>(),
    );
  }

  /// Add item to inventory
  Future<ApiResponse<Map<String, dynamic>>> addItem(
    String userId,
    String itemId,
    int quantity,
  ) async {
    return await _client.post<Map<String, dynamic>>(
      '/inventory/$userId/items',
      body: {
        'itemId': itemId,
        'quantity': quantity,
      },
      dataParser: (data) => data as Map<String, dynamic>,
    );
  }

  /// Remove item from inventory
  Future<ApiResponse<void>> removeItem(
    String userId,
    String itemId,
    int quantity,
  ) async {
    return await _client.request<void>(
      method: 'DELETE',
      path: '/inventory/$userId/items/$itemId',
      body: {'quantity': quantity},
      dataParser: (_) => null,
    );
  }

  /// Use item
  Future<ApiResponse<Map<String, dynamic>>> useItem(
    String userId,
    String itemId,
  ) async {
    return await _client.post<Map<String, dynamic>>(
      '/inventory/$userId/items/$itemId/use',
      dataParser: (data) => data as Map<String, dynamic>,
    );
  }
}

/// Shop API service
class ShopApiService {
  final ApiClient _client = ApiClient.instance;

  /// Get shop items
  Future<ApiResponse<List<Map<String, dynamic>>>> getShopItems({
    String? category,
    String? currency,
  }) async {
    return await _client.get<List<Map<String, dynamic>>>(
      '/shop/items',
      options: ApiOptions(
        queryParameters: {
          if (category != null) 'category': category,
          if (currency != null) 'currency': currency,
        },
      ),
      dataParser: (data) => (data['items'] as List).cast<Map<String, dynamic>>(),
    );
  }

  /// Purchase item
  Future<ApiResponse<Map<String, dynamic>>> purchaseItem(
    String userId,
    String itemId,
    int quantity,
  ) async {
    return await _client.post<Map<String, dynamic>>(
      '/shop/purchase',
      body: {
        'userId': userId,
        'itemId': itemId,
        'quantity': quantity,
      },
      dataParser: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get purchase history
  Future<ApiResponse<List<Map<String, dynamic>>>> getPurchaseHistory(
    String userId,
  ) async {
    return await _client.get<List<Map<String, dynamic>>>(
      '/shop/purchases/$userId',
      dataParser: (data) => (data['purchases'] as List).cast<Map<String, dynamic>>(),
    );
  }
}

/// Quest API service
class QuestApiService {
  final ApiClient _client = ApiClient.instance;

  /// Get available quests
  Future<ApiResponse<List<Map<String, dynamic>>>> getQuests(String userId) async {
    return await _client.get<List<Map<String, dynamic>>>(
      '/quests/$userId',
      dataParser: (data) => (data['quests'] as List).cast<Map<String, dynamic>>(),
    );
  }

  /// Update quest progress
  Future<ApiResponse<Map<String, dynamic>>> updateProgress(
    String userId,
    String questId,
    String objectiveId,
    int progress,
  ) async {
    return await _client.post<Map<String, dynamic>>(
      '/quests/$userId/$questId/progress',
      body: {
        'objectiveId': objectiveId,
        'progress': progress,
      },
      dataParser: (data) => data as Map<String, dynamic>,
    );
  }

  /// Claim quest rewards
  Future<ApiResponse<Map<String, dynamic>>> claimRewards(
    String userId,
    String questId,
  ) async {
    return await _client.post<Map<String, dynamic>>(
      '/quests/$userId/$questId/claim',
      dataParser: (data) => data as Map<String, dynamic>,
    );
  }
}

/// Achievement API service
class AchievementApiService {
  final ApiClient _client = ApiClient.instance;

  /// Get achievements
  Future<ApiResponse<List<Map<String, dynamic>>>> getAchievements(
    String userId, {
    String? category,
  }) async {
    return await _client.get<List<Map<String, dynamic>>>(
      '/achievements/$userId',
      options: ApiOptions(
        queryParameters: {
          if (category != null) 'category': category,
        },
      ),
      dataParser: (data) => (data['achievements'] as List).cast<Map<String, dynamic>>(),
    );
  }

  /// Unlock achievement
  Future<ApiResponse<Map<String, dynamic>>> unlockAchievement(
    String userId,
    String achievementId,
  ) async {
    return await _client.post<Map<String, dynamic>>(
      '/achievements/$userId/unlock',
      body: {'achievementId': achievementId},
      dataParser: (data) => data as Map<String, dynamic>,
    );
  }

  /// Claim achievement reward
  Future<ApiResponse<Map<String, dynamic>>> claimReward(
    String userId,
    String achievementId,
  ) async {
    return await _client.post<Map<String, dynamic>>(
      '/achievements/$userId/$achievementId/claim',
      dataParser: (data) => data as Map<String, dynamic>,
    );
  }
}

/// Social API service
class SocialApiService {
  final ApiClient _client = ApiClient.instance;

  /// Get friends list
  Future<ApiResponse<List<Map<String, dynamic>>>> getFriends(String userId) async {
    return await _client.get<List<Map<String, dynamic>>>(
      '/social/$userId/friends',
      dataParser: (data) => (data['friends'] as List).cast<Map<String, dynamic>>(),
    );
  }

  /// Send friend request
  Future<ApiResponse<Map<String, dynamic>>> sendFriendRequest(
    String userId,
    String friendId,
  ) async {
    return await _client.post<Map<String, dynamic>>(
      '/social/$userId/friends/requests',
      body: {'friendId': friendId},
      dataParser: (data) => data as Map<String, dynamic>,
    );
  }

  /// Accept friend request
  Future<ApiResponse<void>> acceptFriendRequest(
    String userId,
    String requestId,
  ) async {
    return await _client.post<void>(
      '/social/$userId/friends/requests/$requestId/accept',
      dataParser: (_) => null,
    );
  }

  /// Get friend requests
  Future<ApiResponse<List<Map<String, dynamic>>>> getFriendRequests(
    String userId,
  ) async {
    return await _client.get<List<Map<String, dynamic>>>(
      '/social/$userId/friends/requests',
      dataParser: (data) => (data['requests'] as List).cast<Map<String, dynamic>>(),
    );
  }

  /// Remove friend
  Future<ApiResponse<void>> removeFriend(
    String userId,
    String friendId,
  ) async {
    return await _client.delete<void>(
      '/social/$userId/friends/$friendId',
      dataParser: (_) => null,
    );
  }

  /// Block user
  Future<ApiResponse<void>> blockUser(
    String userId,
    String blockedUserId,
  ) async {
    return await _client.post<void>(
      '/social/$userId/blocked',
      body: {'blockedUserId': blockedUserId},
      dataParser: (_) => null,
    );
  }
}

/// Chat API service
class ChatApiService {
  final ApiClient _client = ApiClient.instance;

  /// Get chat messages
  Future<ApiResponse<List<Map<String, dynamic>>>> getMessages(
    String channelId, {
    int limit = 50,
    int? offset,
  }) async {
    return await _client.get<List<Map<String, dynamic>>>(
      '/chat/channels/$channelId/messages',
      options: ApiOptions(
        queryParameters: {
          'limit': limit,
          if (offset != null) 'offset': offset,
        },
      ),
      dataParser: (data) => (data['messages'] as List).cast<Map<String, dynamic>>(),
    );
  }

  /// Send message
  Future<ApiResponse<Map<String, dynamic>>> sendMessage(
    String channelId,
    String senderId,
    String content,
  ) async {
    return await _client.post<Map<String, dynamic>>(
      '/chat/channels/$channelId/messages',
      body: {
        'senderId': senderId,
        'content': content,
      },
      dataParser: (data) => data as Map<String, dynamic>,
    );
  }

  /// Create channel
  Future<ApiResponse<Map<String, dynamic>>> createChannel(
    String type,
    String name,
    List<String> members,
  ) async {
    return await _client.post<Map<String, dynamic>>(
      '/chat/channels',
      body: {
        'type': type,
        'name': name,
        'members': members,
      },
      dataParser: (data) => data as Map<String, dynamic>,
    );
  }

  /// Join channel
  Future<ApiResponse<void>> joinChannel(
    String channelId,
    String userId,
  ) async {
    return await _client.post<void>(
      '/chat/channels/$channelId/join',
      body: {'userId': userId},
      dataParser: (_) => null,
    );
  }

  /// Leave channel
  Future<ApiResponse<void>> leaveChannel(
    String channelId,
    String userId,
  ) async {
    return await _client.post<void>(
      '/chat/channels/$channelId/leave',
      body: {'userId': userId},
      dataParser: (_) => null,
    );
  }
}

/// Leaderboard API service
class LeaderboardApiService {
  final ApiClient _client = ApiClient.instance;

  /// Get leaderboard
  Future<ApiResponse<List<Map<String, dynamic>>>> getLeaderboard(
    String leaderboardId, {
    int limit = 100,
    int? offset,
  }) async {
    return await _client.get<List<Map<String, dynamic>>>(
      '/leaderboards/$leaderboardId',
      options: ApiOptions(
        queryParameters: {
          'limit': limit,
          if (offset != null) 'offset': offset,
        },
      ),
      dataParser: (data) => (data['entries'] as List).cast<Map<String, dynamic>>(),
    );
  }

  /// Get user rank
  Future<ApiResponse<Map<String, dynamic>>> getUserRank(
    String leaderboardId,
    String userId,
  ) async {
    return await _client.get<Map<String, dynamic>>(
      '/leaderboards/$leaderboardId/users/$userId',
      dataParser: (data) => data as Map<String, dynamic>,
    );
  }

  /// Submit score
  Future<ApiResponse<Map<String, dynamic>>> submitScore(
    String leaderboardId,
    String userId,
    double score,
  ) async {
    return await _client.post<Map<String, dynamic>>(
      '/leaderboards/$leaderboardId/scores',
      body: {
        'userId': userId,
        'score': score,
      },
      dataParser: (data) => data as Map<String, dynamic>,
    );
  }
}

/// Authentication API service
class AuthApiService {
  final ApiClient _client = ApiClient.instance;

  /// Login
  Future<ApiResponse<Map<String, dynamic>>> login(
    String username,
    String password,
  ) async {
    return await _client.post<Map<String, dynamic>>(
      '/auth/login',
      body: {
        'username': username,
        'password': password,
      },
      dataParser: (data) => data as Map<String, dynamic>,
    );
  }

  /// Register
  Future<ApiResponse<Map<String, dynamic>>> register(
    String username,
    String email,
    String password,
  ) async {
    return await _client.post<Map<String, dynamic>>(
      '/auth/register',
      body: {
        'username': username,
        'email': email,
        'password': password,
      },
      dataParser: (data) => data as Map<String, dynamic>,
    );
  }

  /// Refresh token
  Future<ApiResponse<Map<String, dynamic>>> refreshToken(
    String refreshToken,
  ) async {
    return await _client.post<Map<String, dynamic>>(
      '/auth/refresh',
      body: {'refreshToken': refreshToken},
      dataParser: (data) => data as Map<String, dynamic>,
    );
  }

  /// Logout
  Future<ApiResponse<void>> logout() async {
    return await _client.post<void>(
      '/auth/logout',
      dataParser: (_) => null,
    );
  }

  /// Reset password
  Future<ApiResponse<void>> resetPassword(String email) async {
    return await _client.post<void>(
      '/auth/reset-password',
      body: {'email': email},
      dataParser: (_) => null,
    );
  }
}
