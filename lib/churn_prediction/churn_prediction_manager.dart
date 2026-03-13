import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 이탈 위험 레벨
enum ChurnRiskLevel {
  low,           // 낮음 (0-30%)
  medium,        // 중간 (31-60%)
  high,          // 높음 (61-80%)
  critical,      // 위험 (81-100%)
}

/// 개입 전략
enum InterventionStrategy {
  reward,        // 보상
  notification,  // 알림
  personalized,  // 개인화된 메시지
  social,        // 소셜 장려
  difficulty,    // 난이도 조정
  none,          // 개입 없음
}

/// 행동 패턴
class BehaviorPattern {
  final String id;
  final String name;
  final double weight;
  final Map<String, double> thresholds;

  const BehaviorPattern({
    required this.id,
    required this.name,
    required this.weight,
    required this.thresholds,
  });
}

/// 이탈 예측 결과
class ChurnPredictionResult {
  final String userId;
  final ChurnRiskLevel riskLevel;
  final double probability;
  final List<String> riskFactors;
  final DateTime predictedChurnDate;
  final InterventionStrategy recommendedStrategy;
  final Map<String, dynamic>? metadata;

  const ChurnPredictionResult({
    required this.userId,
    required this.riskLevel,
    required this.probability,
    required this.riskFactors,
    required this.predictedChurnDate,
    required this.recommendedStrategy,
    this.metadata,
  });

  /// 위험한지 여부
  bool get isAtRisk => riskLevel == ChurnRiskLevel.high ||
      riskLevel == ChurnRiskLevel.critical;
}

/// 개입 캠페인
class InterventionCampaign {
  final String id;
  final String name;
  final String description;
  final InterventionStrategy strategy;
  final Map<String, dynamic> parameters;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final int targetedUsers;

  const InterventionCampaign({
    required this.id,
    required this.name,
    required this.description,
    required this.strategy,
    required this.parameters,
    this.isActive = false,
    this.startDate,
    this.endDate,
    this.targetedUsers = 0,
  });
}

/// 사용자 활동 지표
class UserActivityMetrics {
  final String userId;
  final int sessionCount;
  final double avgSessionDuration;
  final int daysSinceLastLogin;
  final double engagementScore;
  final double socialScore;
  final double spendingScore;
  final DateTime lastUpdated;

  const UserActivityMetrics({
    required this.userId,
    required this.sessionCount,
    required this.avgSessionDuration,
    required this.daysSinceLastLogin,
    required this.engagementScore,
    required this.socialScore,
    required this.spendingScore,
    required this.lastUpdated,
  });

  /// 활동 지표
  bool get isActive => daysSinceLastLogin <= 7;

  /// 휴면 지표
  bool get isDormant => daysSinceLastLogin > 30;
}

/// 이탈 예측 모델
class ChurnPredictionModel {
  final String id;
  final String name;
  final double accuracy;
  final double precision;
  final double recall;
  final DateTime? lastTrained;

  const ChurnPredictionModel({
    required this.id,
    required this.name,
    required this.accuracy,
    required this.precision,
    required this.recall,
    this.lastTrained,
  });
}

/// 이탈 예측 관리자
class ChurnPredictionManager {
  static final ChurnPredictionManager _instance = ChurnPredictionManager._();
  static ChurnPredictionManager get instance => _instance;

  ChurnPredictionManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  final Map<String, UserActivityMetrics> _userMetrics = {};
  final Map<String, ChurnPredictionResult> _predictions = {};
  final Map<String, InterventionCampaign> _campaigns = {};
  final Map<String, ChurnPredictionModel> _models = {};

  final StreamController<ChurnPredictionResult> _predictionController =
      StreamController<ChurnPredictionResult>.broadcast();
  final StreamController<InterventionCampaign> _campaignController =
      StreamController<InterventionCampaign>.broadcast();

  Stream<ChurnPredictionResult> get onPredictionUpdate => _predictionController.stream;
  Stream<InterventionCampaign> get onCampaignUpdate => _campaignController.stream;

  Timer? _analysisTimer;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 모델 로드
    _loadModels();

    // 캠페인 로드
    _loadCampaigns();

    // 사용자 지표 로드
    await _loadUserMetrics();

    // 정기 분석 시작
    _startPeriodicAnalysis();

    debugPrint('[ChurnPrediction] Initialized');
  }

  void _loadModels() {
    _models['baseline'] = const ChurnPredictionModel(
      id: 'baseline',
      name: 'Baseline Model',
      accuracy: 0.85,
      precision: 0.82,
      recall: 0.78,
    );

    _models['advanced'] = const ChurnPredictionModel(
      id: 'advanced',
      name: 'Advanced Model',
      accuracy: 0.92,
      precision: 0.89,
      recall: 0.87,
    );
  }

  void _loadCampaigns() {
    _campaigns['reward_campaign'] = InterventionCampaign(
      id: 'reward_campaign',
      name: '보상 지급 캠페인',
      description: '위험 사용자에게 보상 지급',
      strategy: InterventionStrategy.reward,
      parameters: {
        'gold': 10000,
        'gems': 500,
      },
      isActive: true,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
    );

    _campaigns['notification_campaign'] = InterventionCampaign(
      id: 'notification_campaign',
      name: '알림 캠페인',
      description: '맞춤형 알림 전송',
      strategy: InterventionStrategy.notification,
      parameters: {
        'frequency': 'daily',
        'message': '돌아오세요!',
      },
      isActive: true,
    );
  }

  Future<void> _loadUserMetrics() async {
    // 시뮬레이션: 사용자 활동 지표 로드
    if (_currentUserId != null) {
      _userMetrics[_currentUserId!] = UserActivityMetrics(
        userId: _currentUserId!,
        sessionCount: 50,
        avgSessionDuration: 300.0,
        daysSinceLastLogin: 1,
        engagementScore: 0.8,
        socialScore: 0.7,
        spendingScore: 0.6,
        lastUpdated: DateTime.now(),
      );
    }
  }

  void _startPeriodicAnalysis() {
    _analysisTimer?.cancel();
    _analysisTimer = Timer.periodic(const Duration(hours: 6), (_) {
      analyzeChurnRisk();
    });
  }

  /// 사용자 활동 업데이트
  Future<void> updateUserActivity({
    required String userId,
    int? sessionCount,
    double? sessionDuration,
    int? socialInteractions,
    double? spendingAmount,
  }) async {
    final existing = _userMetrics[userId];

    final updated = UserActivityMetrics(
      userId: userId,
      sessionCount: sessionCount ?? (existing?.sessionCount ?? 0),
      avgSessionDuration: sessionDuration ?? (existing?.avgSessionDuration ?? 0.0),
      daysSinceLastLogin: 0, // 활동했으므로 0
      engagementScore: _calculateEngagementScore(
        sessionCount ?? existing?.sessionCount ?? 0,
        sessionDuration ?? existing?.avgSessionDuration ?? 0.0,
      ),
      socialScore: _calculateSocialScore(
        socialInteractions ?? existing?.socialScore.toInt() ?? 0,
      ),
      spendingScore: _calculateSpendingScore(
        spendingAmount ?? existing?.spendingScore ?? 0.0,
      ),
      lastUpdated: DateTime.now(),
    );

    _userMetrics[userId] = updated;

    await _saveUserMetrics(updated);

    debugPrint('[ChurnPrediction] Activity updated: $userId');
  }

  double _calculateEngagementScore(int sessions, double avgDuration) {
    // 활동 점수 계산
    final sessionScore = min(sessions / 100.0, 1.0);
    final durationScore = min(avgDuration / 600.0, 1.0); // 10분 기준

    return (sessionScore + durationScore) / 2;
  }

  double _calculateSocialScore(int interactions) {
    return min(interactions / 50.0, 1.0);
  }

  double _calculateSpendingScore(double amount) {
    return min(amount / 100.0, 1.0); // 100달러 기준
  }

  /// 이탈 위험 분석
  Future<ChurnPredictionResult> analyzeChurnRisk({
    String? userId,
    String? modelId,
  }) async {
    userId ??= _currentUserId;
    if (userId == null) {
      throw Exception('User ID required');
    }

    final metrics = _userMetrics[userId];
    if (metrics == null) {
      throw Exception('User metrics not found');
    }

    // 위험 요소 식별
    final riskFactors = <String>[];
    double probability = 0.0;

    // 로그인 간격
    if (metrics.daysSinceLastLogin > 7) {
      probability += 0.3;
      riskFactors.add('장기 미접속');
    }

    // 활동 점수
    if (metrics.engagementScore < 0.3) {
      probability += 0.25;
      riskFactors.add('낮은 활동 점수');
    }

    // 소셜 점수
    if (metrics.socialScore < 0.2) {
      probability += 0.2;
      riskFactors.add('소셜 참여 부족');
    }

    // 지출 점수
    if (metrics.spendingScore < 0.1) {
      probability += 0.15;
      riskFactors.add('지출 감소');
    }

    // 세션 지속 시간
    if (metrics.avgSessionDuration < 60.0) {
      probability += 0.1;
      riskFactors.add('짧은 세션 시간');
    }

    // 확률 제한
    probability = min(probability, 1.0);

    // 위험 레벨 결정
    final riskLevel = _getRiskLevel(probability);

    // 예상 이탈 날짜
    final predictedDate = DateTime.now().add(
      Duration(days: _getDaysToChurn(probability)),
    );

    // 개입 전략 추천
    final strategy = _recommendStrategy(probability, metrics);

    final prediction = ChurnPredictionResult(
      userId: userId,
      riskLevel: riskLevel,
      probability: probability,
      riskFactors: riskFactors,
      predictedChurnDate: predictedDate,
      recommendedStrategy: strategy,
      metadata: {
        'modelId': modelId ?? 'baseline',
        'analyzedAt': DateTime.now().toIso8601String(),
      },
    );

    _predictions[userId] = prediction;
    _predictionController.add(prediction);

    // 위험 사용자에 대한 자동 개입
    if (prediction.isAtRisk) {
      await _executeIntervention(userId, prediction);
    }

    debugPrint('[ChurnPrediction] Risk analyzed: $userId - ${riskLevel.name} (${(probability * 100).toStringAsFixed(1)}%)');

    return prediction;
  }

  ChurnRiskLevel _getRiskLevel(double probability) {
    if (probability <= 0.3) return ChurnRiskLevel.low;
    if (probability <= 0.6) return ChurnRiskLevel.medium;
    if (probability <= 0.8) return ChurnRiskLevel.high;
    return ChurnRiskLevel.critical;
  }

  int _getDaysToChurn(double probability) {
    // 확률이 높을수록 빨리 이탈
    return ((1.0 - probability) * 90).toInt(); // 최대 90일
  }

  InterventionStrategy _recommendStrategy(
    double probability,
    UserActivityMetrics metrics,
  ) {
    if (probability >= 0.8) {
      return InterventionStrategy.reward;
    } else if (probability >= 0.6) {
      return InterventionStrategy.personalized;
    } else if (metrics.socialScore < 0.3) {
      return InterventionStrategy.social;
    } else {
      return InterventionStrategy.notification;
    }
  }

  /// 개입 실행
  Future<void> _executeIntervention(
    String userId,
    ChurnPredictionResult prediction,
  ) async {
    final campaign = _campaigns.values.firstWhere(
      (c) => c.strategy == prediction.recommendedStrategy && c.isActive,
      orElse: () => _campaigns.values.first,
    );

    await executeCampaign(campaign.id, [userId]);

    debugPrint('[ChurnPrediction] Intervention executed: $userId - ${campaign.name}');
  }

  /// 캠페인 실행
  Future<void> executeCampaign(
    String campaignId,
    List<String> userIds,
  ) async {
    final campaign = _campaigns[campaignId];
    if (campaign == null || !campaign.isActive) return;

    // 캠페인 파라미터 적용
    switch (campaign.strategy) {
      case InterventionStrategy.reward:
        for (final userId in userIds) {
          final gold = campaign.parameters['gold'] as int? ?? 0;
          final gems = campaign.parameters['gems'] as int? ?? 0;

          if (gold > 0) {
            // 보상 지급 로직
            debugPrint('[ChurnPrediction] Reward granted: $userId - $gold gold');
          }

          if (gems > 0) {
            // 보상 지급 로직
            debugPrint('[ChurnPrediction] Reward granted: $userId - $gems gems');
          }
        }
        break;

      case InterventionStrategy.notification:
        for (final userId in userIds) {
          final message = campaign.parameters['message'] as String? ?? '돌아오세요!';

          // 알림 전송 로직
          debugPrint('[ChurnPrediction] Notification sent: $userId - $message');
        }
        break;

      case InterventionStrategy.social:
        for (final userId in userIds) {
          // 소셜 장려 로직
          debugPrint('[ChurnPrediction] Social encouragement: $userId');
        }
        break;

      default:
        break;
    }

    debugPrint('[ChurnPrediction] Campaign executed: ${campaign.name} - ${userIds.length} users');
  }

  /// 일괄 분석
  Future<List<ChurnPredictionResult>> analyzeChurnRisk() async {
    final results = <ChurnPredictionResult>[];

    for (final userId in _userMetrics.keys) {
      try {
        final prediction = await analyzeChurnRisk(userId: userId);
        results.add(prediction);
      } catch (e) {
        debugPrint('[ChurnPrediction] Analysis failed for $userId: $e');
      }
    }

    // 위험 사용자 정렬
    results.sort((a, b) => b.probability.compareTo(a.probability));

    debugPrint('[ChurnPrediction] Batch analysis completed: ${results.length} users');

    return results;
  }

  /// 위험 사용자 목록
  List<ChurnPredictionResult> getAtRiskUsers({
    ChurnRiskLevel? minLevel,
  }) {
    var predictions = _predictions.values.toList();

    if (minLevel != null) {
      predictions = predictions.where((p) =>
          p.riskLevel.index >= minLevel.index).toList();
    }

    predictions.sort((a, b) => b.probability.compareTo(a.probability));

    return predictions;
  }

  /// 이탈 예측 통계
  Map<String, dynamic> getChurnStatistics() {
    final totalUsers = _predictions.length;
    if (totalUsers == 0) {
      return {
        'totalUsers': 0,
        'averageRisk': 0.0,
        'riskDistribution': {},
      };
    }

    final avgRisk = _predictions.values
        .map((p) => p.probability)
        .reduce((a, b) => a + b) / totalUsers;

    final riskDistribution = <String, int>{};
    for (final level in ChurnRiskLevel.values) {
      riskDistribution[level.name] = _predictions.values
          .where((p) => p.riskLevel == level)
          .length;
    }

    return {
      'totalUsers': totalUsers,
      'averageRisk': avgRisk,
      'riskDistribution': riskDistribution,
      'highRiskCount': riskDistribution['high']! + riskDistribution['critical']!,
    };
  }

  /// 리텐션 리포트
  Map<String, dynamic> generateRetentionReport({
    int days = 30,
  }) {
    final now = DateTime.now();
    final cutoffDate = now.subtract(Duration(days: days));

    final activeUsers = _userMetrics.values
        .where((m) => m.lastUpdated.isAfter(cutoffDate))
        .length;

    final churnedUsers = _predictions.values
        .where((p) => p.isAtRisk)
        .length;

    final retentionRate = activeUsers > 0
        ? (activeUsers - churnedUsers) / activeUsers
        : 0.0;

    return {
      'period': '$days days',
      'activeUsers': activeUsers,
      'churnedUsers': churnedUsers,
      'retentionRate': retentionRate,
      'generatedAt': now.toIso8601String(),
    };
  }

  /// 캠페인 생성
  Future<void> createCampaign({
    required String name,
    required String description,
    required InterventionStrategy strategy,
    required Map<String, dynamic> parameters,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final campaign = InterventionCampaign(
      id: 'campaign_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      strategy: strategy,
      parameters: parameters,
      isActive: false,
      startDate: startDate,
      endDate: endDate,
    );

    _campaigns[campaign.id] = campaign;
    _campaignController.add(campaign);

    debugPrint('[ChurnPrediction] Campaign created: ${campaign.name}');
  }

  /// 캠페인 활성화/비활성화
  Future<void> toggleCampaign(String campaignId, bool isActive) async {
    final campaign = _campaigns[campaignId];
    if (campaign == null) return;

    final updated = InterventionCampaign(
      id: campaign.id,
      name: campaign.name,
      description: campaign.description,
      strategy: campaign.strategy,
      parameters: campaign.parameters,
      isActive: isActive,
      startDate: campaign.startDate,
      endDate: campaign.endDate,
      targetedUsers: campaign.targetedUsers,
    );

    _campaigns[campaignId] = updated;
    _campaignController.add(updated);

    debugPrint('[ChurnPrediction] Campaign ${isActive ? "activated" : "deactivated"}: ${campaign.name}');
  }

  /// 모델 재학습
  Future<void> retrainModel(String modelId) async {
    final model = _models[modelId];
    if (model == null) return;

    // 모델 재학습 (시뮬레이션)
    await Future.delayed(const Duration(minutes: 10));

    final updated = ChurnPredictionModel(
      id: model.id,
      name: model.name,
      accuracy: min(model.accuracy + 0.02, 1.0),
      precision: min(model.precision + 0.02, 1.0),
      recall: min(model.recall + 0.02, 1.0),
      lastTrained: DateTime.now(),
    );

    _models[modelId] = updated;

    debugPrint('[ChurnPrediction] Model retrained: $modelId');
  }

  /// 사용자 지표 저장
  Future<void> _saveUserMetrics(UserActivityMetrics metrics) async {
    await _prefs?.setString(
      'metrics_${metrics.userId}',
      jsonEncode({
        'userId': metrics.userId,
        'sessionCount': metrics.sessionCount,
        'avgSessionDuration': metrics.avgSessionDuration,
        'daysSinceLastLogin': metrics.daysSinceLastLogin,
        'engagementScore': metrics.engagementScore,
        'socialScore': metrics.socialScore,
        'spendingScore': metrics.spendingScore,
        'lastUpdated': metrics.lastUpdated.toIso8601String(),
      }),
    );
  }

  void dispose() {
    _analysisTimer?.cancel();
    _predictionController.close();
    _campaignController.close();
  }
}
