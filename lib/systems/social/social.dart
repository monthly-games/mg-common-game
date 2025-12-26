/// Social System for MG-Games
///
/// Provides friends, guilds, cooperative raids, and leaderboards.
///
/// ## Basic Usage
/// ```dart
/// import 'package:mg_common_game/systems/social/social.dart';
///
/// final social = SocialManager();
/// social.setPlayerId('player123');
///
/// // Friends
/// await social.sendFriendRequest('friend456');
/// print('Friends: ${social.friendCount}');
///
/// // Guilds
/// await social.createGuild('Awesome Guild');
/// print('Guild: ${social.currentGuild?.name}');
///
/// // Raids
/// social.registerRaid(RaidBoss(...));
/// await social.submitRaidDamage('raid1', 1000);
///
/// // Leaderboards
/// final leaders = await social.fetchLeaderboard(LeaderboardType.weekly);
/// ```
///
/// ## Backend Integration
/// ```dart
/// final social = SocialManager();
///
/// // Connect to your backend
/// social.onSendFriendRequest = (userId) async {
///   return await api.sendFriendRequest(userId);
/// };
///
/// social.onFetchLeaderboard = (type, {limit = 100}) async {
///   return await api.getLeaderboard(type.name, limit);
/// };
/// ```
library social;

export 'social_types.dart';
export 'social_manager.dart';
