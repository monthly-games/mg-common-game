/// Standard analytics events for MG-Games
///
/// Defines all common event names and parameters for consistency.
library analytics_events;

/// Event categories
class AnalyticsCategory {
  static const String game = 'game';
  static const String ui = 'ui';
  static const String monetization = 'monetization';
  static const String social = 'social';
  static const String progression = 'progression';
  static const String engagement = 'engagement';
  static const String error = 'error';
}

/// Standard event names
class AnalyticsEvent {
  // ============================================================
  // Game Events
  // ============================================================

  /// Game session started
  static const String gameStart = 'game_start';

  /// Game session ended
  static const String gameEnd = 'game_end';

  /// Level/stage started
  static const String levelStart = 'level_start';

  /// Level/stage completed
  static const String levelComplete = 'level_complete';

  /// Level/stage failed
  static const String levelFail = 'level_fail';

  /// Game paused
  static const String gamePause = 'game_pause';

  /// Game resumed
  static const String gameResume = 'game_resume';

  /// Tutorial started
  static const String tutorialStart = 'tutorial_start';

  /// Tutorial completed
  static const String tutorialComplete = 'tutorial_complete';

  /// Tutorial skipped
  static const String tutorialSkip = 'tutorial_skip';

  // ============================================================
  // Progression Events
  // ============================================================

  /// Player level up
  static const String levelUp = 'level_up';

  /// Achievement unlocked
  static const String achievementUnlocked = 'achievement_unlocked';

  /// Quest completed
  static const String questComplete = 'quest_complete';

  /// Milestone reached
  static const String milestoneReached = 'milestone_reached';

  /// Content unlocked
  static const String contentUnlock = 'content_unlock';

  /// Prestige/rebirth
  static const String prestige = 'prestige';

  // ============================================================
  // Monetization Events
  // ============================================================

  /// In-app purchase started
  static const String purchaseStart = 'purchase_start';

  /// In-app purchase completed
  static const String purchaseComplete = 'purchase_complete';

  /// In-app purchase failed
  static const String purchaseFail = 'purchase_fail';

  /// Ad requested
  static const String adRequest = 'ad_request';

  /// Ad loaded
  static const String adLoaded = 'ad_loaded';

  /// Ad shown
  static const String adShow = 'ad_show';

  /// Ad clicked
  static const String adClick = 'ad_click';

  /// Ad reward earned
  static const String adRewardEarned = 'ad_reward_earned';

  /// Ad failed
  static const String adFail = 'ad_fail';

  /// Virtual currency earned
  static const String currencyEarn = 'currency_earn';

  /// Virtual currency spent
  static const String currencySpend = 'currency_spend';

  // ============================================================
  // Gacha/Shop Events
  // ============================================================

  /// Gacha pull performed
  static const String gachaPull = 'gacha_pull';

  /// Shop item viewed
  static const String shopView = 'shop_view';

  /// Shop item purchased
  static const String shopPurchase = 'shop_purchase';

  // ============================================================
  // UI Events
  // ============================================================

  /// Screen viewed
  static const String screenView = 'screen_view';

  /// Button clicked
  static const String buttonClick = 'button_click';

  /// Menu opened
  static const String menuOpen = 'menu_open';

  /// Settings changed
  static const String settingsChange = 'settings_change';

  // ============================================================
  // Social Events
  // ============================================================

  /// Share action
  static const String share = 'share';

  /// Invite sent
  static const String inviteSend = 'invite_send';

  /// Friend added
  static const String friendAdd = 'friend_add';

  /// Leaderboard viewed
  static const String leaderboardView = 'leaderboard_view';

  // ============================================================
  // Engagement Events
  // ============================================================

  /// App opened
  static const String appOpen = 'app_open';

  /// Daily login
  static const String dailyLogin = 'daily_login';

  /// Return after absence
  static const String returnUser = 'return_user';

  /// Notification received
  static const String notificationReceive = 'notification_receive';

  /// Notification clicked
  static const String notificationClick = 'notification_click';

  /// Session duration threshold
  static const String sessionMilestone = 'session_milestone';

  // ============================================================
  // Error Events
  // ============================================================

  /// App error
  static const String appError = 'app_error';

  /// Network error
  static const String networkError = 'network_error';

  /// Purchase error
  static const String purchaseError = 'purchase_error';
}

/// Standard parameter names
class AnalyticsParam {
  // Game parameters
  static const String gameId = 'game_id';
  static const String gameName = 'game_name';
  static const String gameGenre = 'game_genre';
  static const String gameVersion = 'game_version';

  // Level/stage parameters
  static const String levelId = 'level_id';
  static const String levelName = 'level_name';
  static const String levelNumber = 'level_number';
  static const String difficulty = 'difficulty';
  static const String attempts = 'attempts';
  static const String score = 'score';
  static const String stars = 'stars';
  static const String duration = 'duration';
  static const String result = 'result';

  // Player parameters
  static const String playerId = 'player_id';
  static const String playerLevel = 'player_level';
  static const String playerExp = 'player_exp';
  static const String daysPlayed = 'days_played';
  static const String totalPlaytime = 'total_playtime';

  // Currency parameters
  static const String currencyType = 'currency_type';
  static const String currencyAmount = 'currency_amount';
  static const String currencyBalance = 'currency_balance';
  static const String source = 'source';

  // Item parameters
  static const String itemId = 'item_id';
  static const String itemName = 'item_name';
  static const String itemType = 'item_type';
  static const String itemRarity = 'item_rarity';
  static const String quantity = 'quantity';
  static const String price = 'price';

  // Purchase parameters
  static const String productId = 'product_id';
  static const String productName = 'product_name';
  static const String productPrice = 'product_price';
  static const String currency = 'currency';
  static const String transactionId = 'transaction_id';

  // Ad parameters
  static const String adType = 'ad_type';
  static const String adPlacement = 'ad_placement';
  static const String adNetwork = 'ad_network';
  static const String rewardType = 'reward_type';
  static const String rewardAmount = 'reward_amount';

  // UI parameters
  static const String screenName = 'screen_name';
  static const String screenClass = 'screen_class';
  static const String buttonId = 'button_id';
  static const String buttonName = 'button_name';

  // Social parameters
  static const String shareMethod = 'share_method';
  static const String shareContent = 'share_content';
  static const String friendId = 'friend_id';

  // Error parameters
  static const String errorCode = 'error_code';
  static const String errorMessage = 'error_message';
  static const String errorStack = 'error_stack';

  // Achievement parameters
  static const String achievementId = 'achievement_id';
  static const String achievementName = 'achievement_name';

  // Quest parameters
  static const String questId = 'quest_id';
  static const String questName = 'quest_name';
  static const String questType = 'quest_type';

  // Gacha parameters
  static const String bannerId = 'banner_id';
  static const String pullType = 'pull_type';
  static const String pullCount = 'pull_count';
  static const String pityCount = 'pity_count';

  // Session parameters
  static const String sessionId = 'session_id';
  static const String sessionNumber = 'session_number';
  static const String sessionDuration = 'session_duration';

  // Misc
  static const String timestamp = 'timestamp';
  static const String platform = 'platform';
  static const String deviceModel = 'device_model';
  static const String osVersion = 'os_version';
  static const String appVersion = 'app_version';
  static const String buildNumber = 'build_number';
  static const String success = 'success';
  static const String reason = 'reason';
  static const String value = 'value';
}

/// User property names
class AnalyticsUserProperty {
  static const String firstOpenTime = 'first_open_time';
  static const String lastActiveTime = 'last_active_time';
  static const String totalPlaytime = 'total_playtime';
  static const String totalSessions = 'total_sessions';
  static const String playerLevel = 'player_level';
  static const String totalSpend = 'total_spend';
  static const String isPayer = 'is_payer';
  static const String vipLevel = 'vip_level';
  static const String currentChapter = 'current_chapter';
  static const String achievementCount = 'achievement_count';
  static const String tutorialComplete = 'tutorial_complete';
  static const String notificationEnabled = 'notification_enabled';
  static const String language = 'language';
  static const String country = 'country';
}

/// Pre-built event data builders
class AnalyticsEventData {
  /// Build level start event data
  static Map<String, dynamic> levelStart({
    required String levelId,
    String? levelName,
    int? levelNumber,
    String? difficulty,
    int? attempts,
  }) {
    return {
      AnalyticsParam.levelId: levelId,
      if (levelName != null) AnalyticsParam.levelName: levelName,
      if (levelNumber != null) AnalyticsParam.levelNumber: levelNumber,
      if (difficulty != null) AnalyticsParam.difficulty: difficulty,
      if (attempts != null) AnalyticsParam.attempts: attempts,
      AnalyticsParam.timestamp: DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Build level complete event data
  static Map<String, dynamic> levelComplete({
    required String levelId,
    required int score,
    int? stars,
    int? duration,
    String? difficulty,
  }) {
    return {
      AnalyticsParam.levelId: levelId,
      AnalyticsParam.score: score,
      AnalyticsParam.result: 'success',
      if (stars != null) AnalyticsParam.stars: stars,
      if (duration != null) AnalyticsParam.duration: duration,
      if (difficulty != null) AnalyticsParam.difficulty: difficulty,
      AnalyticsParam.timestamp: DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Build level fail event data
  static Map<String, dynamic> levelFail({
    required String levelId,
    int? score,
    String? reason,
    int? duration,
  }) {
    return {
      AnalyticsParam.levelId: levelId,
      AnalyticsParam.result: 'fail',
      if (score != null) AnalyticsParam.score: score,
      if (reason != null) AnalyticsParam.reason: reason,
      if (duration != null) AnalyticsParam.duration: duration,
      AnalyticsParam.timestamp: DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Build currency spend event data
  static Map<String, dynamic> currencySpend({
    required String currencyType,
    required int amount,
    required String source,
    String? itemId,
    int? balance,
  }) {
    return {
      AnalyticsParam.currencyType: currencyType,
      AnalyticsParam.currencyAmount: amount,
      AnalyticsParam.source: source,
      if (itemId != null) AnalyticsParam.itemId: itemId,
      if (balance != null) AnalyticsParam.currencyBalance: balance,
      AnalyticsParam.timestamp: DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Build currency earn event data
  static Map<String, dynamic> currencyEarn({
    required String currencyType,
    required int amount,
    required String source,
    int? balance,
  }) {
    return {
      AnalyticsParam.currencyType: currencyType,
      AnalyticsParam.currencyAmount: amount,
      AnalyticsParam.source: source,
      if (balance != null) AnalyticsParam.currencyBalance: balance,
      AnalyticsParam.timestamp: DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Build gacha pull event data
  static Map<String, dynamic> gachaPull({
    required String bannerId,
    required String pullType,
    required int pullCount,
    required List<String> itemsReceived,
    int? pityCount,
    String? currencyType,
    int? currencySpent,
  }) {
    return {
      AnalyticsParam.bannerId: bannerId,
      AnalyticsParam.pullType: pullType,
      AnalyticsParam.pullCount: pullCount,
      'items_received': itemsReceived,
      if (pityCount != null) AnalyticsParam.pityCount: pityCount,
      if (currencyType != null) AnalyticsParam.currencyType: currencyType,
      if (currencySpent != null) AnalyticsParam.currencyAmount: currencySpent,
      AnalyticsParam.timestamp: DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Build ad event data
  static Map<String, dynamic> adEvent({
    required String adType,
    required String placement,
    String? network,
    bool? success,
    String? rewardType,
    int? rewardAmount,
  }) {
    return {
      AnalyticsParam.adType: adType,
      AnalyticsParam.adPlacement: placement,
      if (network != null) AnalyticsParam.adNetwork: network,
      if (success != null) AnalyticsParam.success: success,
      if (rewardType != null) AnalyticsParam.rewardType: rewardType,
      if (rewardAmount != null) AnalyticsParam.rewardAmount: rewardAmount,
      AnalyticsParam.timestamp: DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Build purchase event data
  static Map<String, dynamic> purchase({
    required String productId,
    required double price,
    required String currency,
    String? transactionId,
    bool success = true,
    String? errorCode,
  }) {
    return {
      AnalyticsParam.productId: productId,
      AnalyticsParam.productPrice: price,
      AnalyticsParam.currency: currency,
      AnalyticsParam.success: success,
      if (transactionId != null) AnalyticsParam.transactionId: transactionId,
      if (errorCode != null) AnalyticsParam.errorCode: errorCode,
      AnalyticsParam.timestamp: DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Build screen view event data
  static Map<String, dynamic> screenView({
    required String screenName,
    String? screenClass,
    String? previousScreen,
  }) {
    return {
      AnalyticsParam.screenName: screenName,
      if (screenClass != null) AnalyticsParam.screenClass: screenClass,
      if (previousScreen != null) 'previous_screen': previousScreen,
      AnalyticsParam.timestamp: DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Build error event data
  static Map<String, dynamic> error({
    required String errorCode,
    required String errorMessage,
    String? errorStack,
    String? context,
  }) {
    return {
      AnalyticsParam.errorCode: errorCode,
      AnalyticsParam.errorMessage: errorMessage,
      if (errorStack != null) AnalyticsParam.errorStack: errorStack,
      if (context != null) 'error_context': context,
      AnalyticsParam.timestamp: DateTime.now().millisecondsSinceEpoch,
    };
  }
}
