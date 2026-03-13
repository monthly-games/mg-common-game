# MG Common Game - Deployment Guide

## Overview

This guide covers the deployment process for applications built with MG Common Game framework. It includes build configuration, environment setup, deployment strategies, CI/CD pipelines, and production considerations.

## Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Build Configuration](#build-configuration)
3. [Environment Setup](#environment-setup)
4. [Building for Production](#building-for-production)
5. [Deployment Strategies](#deployment-strategies)
6. [CI/CD Pipeline](#cicd-pipeline)
7. [Production Considerations](#production-considerations)
8. [Monitoring and Maintenance](#monitoring-and-maintenance)
9. [Rollback Procedures](#rollback-procedures)
10. [Troubleshooting](#troubleshooting)

---

## Pre-Deployment Checklist

Before deploying your application, ensure you have completed the following:

### Code Quality
- [ ] All tests pass (unit, widget, integration)
- [ ] Code coverage is above 80%
- [ ] No compiler warnings or errors
- [ ] Code reviewed and approved
- [ ] Debug code removed (`print`, `debugPrint`)

### Security
- [ ] API endpoints secured with HTTPS
- [ ] Sensitive data encrypted
- [ ] API keys and secrets stored securely
- [ ] Authentication and authorization implemented
- [ ] Content filtering enabled
- [ ] Rate limiting configured

### Performance
- [ ] App optimized for size
- [ ] Memory usage profiled
- [ ] Performance benchmarks met
- [ ] Analytics and crash reporting configured
- [ ] Lazy loading implemented where appropriate

### Configuration
- [ ] Production environment variables set
- [ ] API URLs configured for production
- [ ] Analytics tracking IDs set
- [ ] Crash reporting enabled
- [ ] Feature flags configured

### Documentation
- [ ] API documentation up to date
- [ ] Architecture diagrams complete
- [ ] Deployment procedures documented
- [ ] Runbooks created for common issues

---

## Build Configuration

### Android Configuration

Edit `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 33

    defaultConfig {
        applicationId "com.yourcompany.game"
        minSdkVersion 21
        targetSdkVersion 33
        versionCode 1
        versionName "1.0.0"

        ndk {
            abiFilters 'armeabi-v7a', 'arm64-v8a', 'x86_64'
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'

            // Enable code obfuscation
            proguardFiles 'proguard-project.txt'
        }
        debug {
            applicationIdSuffix ".debug"
            versionNameSuffix "-debug"
        }
    }

    // Split APKs by ABI
    splits {
        abi {
            enable true
            reset()
            include 'armeabi-v7a', 'arm64-v8a', 'x86_64'
            universalApk false
        }
    }
}
```

### iOS Configuration

Edit `ios/Runner/Info.plist`:

```xml
<key>CFBundleIdentifier</key>
<string>com.yourcompany.game</string>
<key>CFBundleVersion</key>
<string>1.0.0</string>
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>

<!-- Add necessary permissions -->
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library for profile pictures</string>
<key>NSCameraUsageDescription</key>
<string>We need camera access for taking photos</string>
```

Edit `ios/Podfile`:

```ruby
platform :ios, '12.0'

use_frameworks!
inhibit_all_warnings!

def shared_pods
  pod 'Firebase/Analytics'
  pod 'Firebase/Crashlytics'
end

target 'Runner' do
  shared_pods
end
```

### Flutter Build Configuration

Create `flutter_apis.txt` for ProGuard:

```
# Keep model classes
-keep class com.yourcompany.game.models.** { *; }
-keep class mg.common.game.models.** { *; }

# Keep analytics classes
-keep class mg.common.game.analytics.** { *; }

# Keep security classes
-keep class mg.common.game.security.** { *; }
```

---

## Environment Setup

### Environment Variables

Create `.env` files for different environments:

#### `.env.development`
```env
API_BASE_URL=https://dev-api.yourgame.com
ANALYTICS_URL=https://dev-analytics.yourgame.com
ENABLE_CRASH_REPORTING=true
ENABLE_DEBUG_LOGGING=true
SESSION_TIMEOUT_DAYS=7
MAX_CONCURRENT_SESSIONS=5
```

#### `.env.staging`
```env
API_BASE_URL=https://staging-api.yourgame.com
ANALYTICS_URL=https://staging-analytics.yourgame.com
ENABLE_CRASH_REPORTING=true
ENABLE_DEBUG_LOGGING=false
SESSION_TIMEOUT_DAYS=7
MAX_CONCURRENT_SESSIONS=5
```

#### `.env.production`
```env
API_BASE_URL=https://api.yourgame.com
ANALYTICS_URL=https://analytics.yourgame.com
ENABLE_CRASH_REPORTING=true
ENABLE_DEBUG_LOGGING=false
SESSION_TIMEOUT_DAYS=30
MAX_CONCURRENT_SESSIONS=3
```

### Environment Loading

Create an environment loader:

```dart
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static Future<void> load() async {
    String envFile = '.env.production';

    if (const bool.fromEnvironment('dart.vm.product') == false) {
      final env = const String.fromEnvironment('ENV', defaultValue: 'development');
      envFile = '.env.$env';
    }

    await dotenv.load(fileName: envFile);
  }

  static String get apiBaseUrl => dotenv.env['API_BASE_URL']!;
  static String get analyticsUrl => dotenv.env['ANALYTICS_URL']!;
  static bool get enableCrashReporting => dotenv.env['ENABLE_CRASH_REPORTING'] == 'true';
  static bool get enableDebugLogging => dotenv.env['ENABLE_DEBUG_LOGGING'] == 'true';
}
```

### Initialization with Environment

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment
  await Environment.load();

  // Initialize HTTP service with environment URL
  await HttpService.instance.initialize(
    baseUrl: Environment.apiBaseUrl,
    enableLogging: Environment.enableDebugLogging,
  );

  // Initialize managers with production config
  await AnalyticsManager.instance.initialize(
    config: AnalyticsConfig(
      enableReporting: Environment.enableCrashReporting,
      serverUrl: Environment.analyticsUrl,
    ),
  );

  runApp(MyGameApp());
}
```

---

## Building for Production

### Android Build

#### Debug Build
```bash
flutter build apk --debug
```

#### Release Build
```bash
flutter build apk --release

# Build for specific ABI
flutter build apk --release --target-platform android-arm64

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

#### Split APKs
```bash
flutter build apk --release --split-per-abi

# Output:
# - build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
# - build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
# - build/app/outputs/flutter-apk/app-x86_64-release.apk
```

### iOS Build

#### Debug Build
```bash
flutter build ios --debug
```

#### Release Build
```bash
flutter build ios --release

# Build for specific architecture
flutter build ios --release --no-codesign

# Archive and export
cd ios
pod install
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -sdk iphoneos \
  -configuration Release \
  -archivePath build/Runner.xcarchive \
  archive
```

### Web Build

```bash
flutter build web --release

# Output: build/web/
```

### Build Verification

```bash
# Check build size
flutter build apk --release --analyze-size

# Run flutter doctor
flutter doctor -v

# Verify dependencies
flutter pub deps
```

---

## Deployment Strategies

### 1. Blue-Green Deployment

Deploy to production with zero downtime:

```
Current Version (Blue)        New Version (Green)
      │                              │
      └─────── Users ─────────────────┘
              Traffic
```

**Implementation:**

```dart
class DeploymentManager {
  static const String blueVersion = '1.0.0';
  static const String greenVersion = '1.1.0';

  String? _currentVersion = blueVersion;

  Future<void> switchVersion() async {
    // Save current version
    await _saveVersion(_currentVersion!);

    // Switch to new version
    _currentVersion = _currentVersion == blueVersion
      ? greenVersion
      : blueVersion;

    // Update config
    await _updateConfig();

    // Notify users
    await _notifyUsers();
  }

  Future<void> _saveVersion(String version) async {
    await _storage.setString('deployed_version', version);
  }

  Future<void> _updateConfig() async {
    // Update configuration for new version
    final config = await _fetchConfig(_currentVersion!);
    await _applyConfig(config);
  }

  Future<void> _notifyUsers() async {
    // Show update notification
    // Optionally force update for critical changes
  }
}
```

### 2. Canary Release

Release to small percentage of users first:

```dart
class FeatureFlagManager {
  static const double canaryPercentage = 0.1; // 10%

  static bool shouldUseNewFeature(String userId) {
    // Use consistent hash to determine canary group
    final hash = userId.hashCode.abs();
    final threshold = (canaryPercentage * 4294967296).toInt();
    return hash < threshold;
  }

  static String getVersion(String userId) {
    return shouldUseNewFeature(userId) ? '1.1.0' : '1.0.0';
  }
}
```

### 3. A/B Testing Deployment

Deploy with A/B testing:

```dart
class DeploymentABTest {
  static const String experimentId = 'new_ui_design';

  static String getVariant(String userId) {
    final variant = ABTestingManager.instance.assignVariant(
      experimentId,
      userId,
    );

    return variant; // 'control' or 'treatment'
  }

  static void trackDeployment(String userId, String variant) {
    AnalyticsManager.instance.trackEvent(
      eventName: 'deployment_variant',
      category: EventCategory.deployment,
      parameters: {
        'variant': variant,
        'version': '1.1.0',
      },
      userId: userId,
    );
  }
}
```

---

## CI/CD Pipeline

### GitHub Actions Configuration

Create `.github/workflows/deploy.yml`:

```yaml
name: Build and Deploy

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.0'

      - name: Install dependencies
        run: flutter pub get

      - name: Run tests
        run: flutter test --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: coverage/lcov.info

  build-android:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
      - uses: actions/checkout@v3

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.0'

      - name: Setup Java
        uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: '17'

      - name: Build Android
        run: |
          flutter build appbundle --release
          flutter build apk --release --split-per-abi

      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: android-release
          path: |
            build/app/outputs/bundle/release/*.aab
            build/app/outputs/flutter-apk/*.apk

  build-ios:
    needs: test
    runs-on: macos-latest
    if: github.ref == 'refs/heads/main'

    steps:
      - uses: actions/checkout@v3

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.0'

      - name: Build iOS
        run: flutter build ios --release --no-codesign

      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: ios-release
          path: build/ios/

  deploy:
    needs: [build-android, build-ios]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
      - name: Deploy to Play Store
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.SERVICE_ACCOUNT_JSON }}
          packageName: com.yourcompany.game
          releaseFiles: build/app/outputs/bundle/release/*.aab
          track: internal
          status: completed

      - name: Deploy to App Store
        uses: apple-actions/deploy-for-ios@v1
        with:
          api-key: ${{ secrets.APP_STORE_CONNECT_API_KEY }}
          app-path: build/ios/
```

### GitLab CI Configuration

Create `.gitlab-ci.yml`:

```yaml
stages:
  - test
  - build
  - deploy

variables:
  FLUTTER_VERSION: "3.10.0"

test:
  stage: test
  image: cirrusci/flutter:{$FLUTTER_VERSION}
  script:
    - flutter pub get
    - flutter test --coverage
  coverage: '/LINES.*\s+(\d+\.\d+)%/'
  artifacts:
    paths:
      - coverage/

build-android:
  stage: build
  image: cirrusci/flutter:{$FLUTTER_VERSION}
  script:
    - flutter build appbundle --release
    - flutter build apk --release --split-per-abi
  artifacts:
    paths:
      - build/app/outputs/

build-ios:
  stage: build
  tags:
    - ios
  script:
    - flutter build ios --release
  artifacts:
    paths:
      - build/ios/

deploy-production:
  stage: deploy
  image: alpine:latest
  dependencies:
    - build-android
    - build-ios
  script:
    - echo "Deploying to production stores..."
    # Add deployment scripts here
  only:
    - main
```

---

## Production Considerations

### 1. Error Handling

Implement comprehensive error handling:

```dart
class ProductionErrorHandler {
  static void initialize() {
    // Catch all Flutter errors
    FlutterError.onError = (details) {
      // Log to crash reporter
      CrashReporter.instance.reportException(
        details.exception,
        details.stack,
        CrashSeverity.critical,
      );

      // Log to analytics
      AnalyticsManager.instance.trackEvent(
        eventName: 'flutter_error',
        category: EventCategory.error,
        parameters: {
          'error': details.exceptionAsString(),
        },
      );
    };

    // Catch all async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      CrashReporter.instance.reportException(
        error,
        stack,
        CrashSeverity.critical,
      );
      return true;
    };
  }
}
```

### 2. Performance Monitoring

Enable performance monitoring:

```dart
class PerformanceMonitor {
  static void initialize() {
    // Start performance monitoring
    AnalyticsManager.instance.performanceMonitor.startMonitoring();

    // Set performance thresholds
    AnalyticsManager.instance.performanceMonitor.setThreshold(
      MetricType.fps,
      threshold: 30,
      severity: AlertSeverity.warning,
    );

    // Listen to performance alerts
    AnalyticsManager.instance.performanceMonitor.alertStream.listen((alert) {
      _handlePerformanceAlert(alert);
    });
  }

  static void _handlePerformanceAlert(PerformanceAlert alert) {
    // Log performance issues
    AnalyticsManager.instance.trackEvent(
      eventName: 'performance_alert',
      category: EventCategory.performance,
      parameters: {
        'metric_type': alert.metricType.name,
        'value': alert.value,
        'threshold': alert.threshold,
        'severity': alert.severity.name,
      },
    );
  }
}
```

### 3. Security Hardening

Implement security measures:

```dart
class SecurityConfigurator {
  static Future<void> configure() async {
    // Enable certificate pinning
    HttpService.instance.setCertificatePinning([
      'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='
    ]);

    // Enable SSL pinning
    HttpService.instance.setSSLPinningEnabled(true);

    // Configure content filter
    await ContentFilter.instance.initialize(
      config: ContentFilterConfig(
        enableProfanityFilter: true,
        enableSpamFilter: true,
        enableHarassmentFilter: true,
        enablePersonalInfoFilter: true,
      ),
    );

    // Configure account security
    await AccountSecurityManager.instance.initialize(
      config: SecurityConfig(
        maxFailedAttempts: 5,
        lockoutDuration: Duration(minutes: 30),
        sessionTimeout: Duration(days: 7),
        require2FA: false,
        enableIPTracking: true,
        enableDeviceFingerprinting: true,
      ),
    );
  }
}
```

### 4. Data Backup

Implement backup strategy:

```dart
class BackupManager {
  static Future<void> backupUserData(String userId) async {
    final backup = {
      'timestamp': DateTime.now().toIso8601String(),
      'userId': userId,
      'user': UserManager.instance.getUser(userId)?.toJson(),
      'inventory': await InventoryManager.instance.getInventory(userId),
      'quests': await QuestManager.instance.getQuests(userId),
      'achievements': await AchievementManager.instance.getAchievements(userId),
    };

    // Upload to cloud storage
    await _uploadBackup(backup);
  }

  static Future<void> restoreUserData(String userId) async {
    // Download backup from cloud
    final backup = await _downloadBackup(userId);

    // Restore data
    if (backup['user'] != null) {
      await UserManager.instance.restoreUser(backup['user']);
    }
    if (backup['inventory'] != null) {
      await InventoryManager.instance.restoreInventory(backup['inventory']);
    }
    // ... restore other data
  }

  static Future<void> _uploadBackup(Map<String, dynamic> backup) async {
    // Implement cloud storage upload
  }

  static Future<Map<String, dynamic>> _downloadBackup(String userId) async {
    // Implement cloud storage download
    return {};
  }
}
```

---

## Monitoring and Maintenance

### Health Checks

Implement health check endpoints:

```dart
class HealthChecker {
  static Future<Map<String, dynamic>> check() async {
    return {
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
      'checks': {
        'storage': await _checkStorage(),
        'network': await _checkNetwork(),
        'analytics': await _checkAnalytics(),
        'security': await _checkSecurity(),
      },
    };
  }

  static Future<Map<String, dynamic>> _checkStorage() async {
    try {
      await LocalStorageService.instance.setString('health_check', 'test');
      await LocalStorageService.instance.remove('health_check');
      return {'status': 'ok'};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> _checkNetwork() async {
    try {
      await HttpService.instance.get('/health');
      return {'status': 'ok'};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> _checkAnalytics() async {
    final manager = AnalyticsManager.instance;
    return {
      'status': 'ok',
      'eventsBuffered': manager.eventsBuffered,
      'lastUpload': manager.lastUpload?.toIso8601String(),
    };
  }

  static Future<Map<String, dynamic>> _checkSecurity() async {
    final manager = AccountSecurityManager.instance;
    final stats = manager.getStatistics();
    return {
      'status': 'ok',
      'activeSessions': stats['activeSessions'],
      'lockedAccounts': stats['lockedAccounts'],
    };
  }
}
```

### Log Aggregation

Implement centralized logging:

```dart
class LogAggregator {
  static final List<LogEntry> _logs = [];
  static const int _maxLogs = 1000;

  static void log(String message, {LogLevel level = LogLevel.info}) {
    final entry = LogEntry(
      message: message,
      level: level,
      timestamp: DateTime.now(),
    );

    _logs.add(entry);

    // Keep only recent logs
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }

    // Upload to server if error
    if (level == LogLevel.error || level == LogLevel.critical) {
      _uploadLog(entry);
    }
  }

  static Future<void> _uploadLog(LogEntry entry) async {
    try {
      await HttpService.instance.post(
        '/logs',
        body: entry.toJson(),
      );
    } catch (e) {
      // Silently fail to avoid infinite loop
    }
  }

  static List<LogEntry> getLogs({LogLevel? minLevel}) {
    if (minLevel == null) return List.from(_logs);

    return _logs.where((log) => log.level.index >= minLevel.index).toList();
  }
}

enum LogLevel { debug, info, warning, error, critical }

class LogEntry {
  final String message;
  final LogLevel level;
  final DateTime timestamp;

  LogEntry({required this.message, required this.level, required this.timestamp});

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'level': level.name,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
```

---

## Rollback Procedures

### Version Rollback

Implement rollback mechanism:

```dart
class RollbackManager {
  static Future<void> rollback(String previousVersion) async {
    // Update to previous version
    await _updateAppVersion(previousVersion);

    // Clear caches
    await _clearCaches();

    // Restart app
    await _restartApp();

    // Notify users
    await _notifyRollback(previousVersion);
  }

  static Future<void> _updateAppVersion(String version) async {
    await _storage.setString('app_version', version);
  }

  static Future<void> _clearCaches() async {
    await _storage.clear();
  }

  static Future<void> _restartApp() async {
    // Platform-specific restart implementation
  }

  static Future<void> _notifyRollback(String version) async {
    // Show rollback notification to users
  }
}
```

### Data Rollback

Implement data rollback:

```dart
class DataRollbackManager {
  static Future<void> rollbackToSnapshot(String snapshotId) async {
    // Download snapshot
    final snapshot = await _downloadSnapshot(snapshotId);

    // Restore data
    await _restoreSnapshot(snapshot);

    // Verify integrity
    await _verifyDataIntegrity();
  }

  static Future<Map<String, dynamic>> _downloadSnapshot(String snapshotId) async {
    final response = await HttpService.instance.get('/snapshots/$snapshotId');
    return response.data;
  }

  static Future<void> _restoreSnapshot(Map<String, dynamic> snapshot) async {
    // Restore all data from snapshot
  }

  static Future<void> _verifyDataIntegrity() async {
    // Verify data integrity after rollback
  }
}
```

---

## Troubleshooting

### Common Issues

#### Issue 1: Build Fails

**Symptoms**: Flutter build command fails with errors

**Solutions**:
```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Upgrade Flutter
flutter upgrade

# Check Flutter doctor
flutter doctor -v

# Remove .gradle cache (Android)
cd android
./gradlew clean

# Remove Pods (iOS)
cd ios
rm -rf Pods
pod install
```

#### Issue 2: App Crashes on Startup

**Symptoms**: App crashes immediately after launch

**Solutions**:
1. Check initialization order
2. Verify all managers are initialized
3. Check for missing environment variables
4. Review crash logs in Crashlytics

#### Issue 3: High Memory Usage

**Symptoms**: App uses excessive memory

**Solutions**:
1. Profile memory usage with DevTools
2. Implement lazy loading
3. Clear caches regularly
4. Dispose unused resources

#### Issue 4: Network Requests Fail

**Symptoms**: API calls fail or timeout

**Solutions**:
1. Check network connectivity
2. Verify API URLs are correct
3. Check SSL certificate configuration
4. Review timeout settings
5. Implement retry logic

---

## Post-Deployment Checklist

After deployment, verify the following:

- [ ] App launches successfully
- [ ] Login works correctly
- [ ] Core features function properly
- [ ] Analytics events are received
- [ ] Crash reports are being collected
- [ ] Performance metrics are within thresholds
- [ ] Security measures are working
- [ ] User feedback is positive
- [ ] Error rates are low
- [ ] Server load is acceptable

---

## Conclusion

This deployment guide provides a comprehensive approach to deploying applications built with MG Common Game framework. Follow these procedures to ensure smooth, reliable deployments and maintain high-quality production applications.

For additional information, refer to:
- [API Documentation](API_DOCUMENTATION.md)
- [Architecture Documentation](ARCHITECTURE.md)
- [Getting Started Guide](GETTING_STARTED.md)

Good luck with your deployment!
