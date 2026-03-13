import 'dart:async';
import 'package:mg_common_game/storage/local_storage_service.dart';
import 'package:mg_common_game/storage/database_service.dart';

/// Migration status
enum MigrationStatus {
  pending,
  running,
  completed,
  failed,
  rolledBack,
}

/// Migration direction
enum MigrationDirection {
  up,
  down,
}

/// Migration record
class MigrationRecord {
  final String id;
  final String version;
  final String description;
  final MigrationStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? errorMessage;

  MigrationRecord({
    required this.id,
    required this.version,
    required this.description,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.errorMessage,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'version': version,
      'description': description,
      'status': status.name,
      'startedAt': startedAt?.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'errorMessage': errorMessage,
    };
  }

  /// Create from JSON
  factory MigrationRecord.fromJson(Map<String, dynamic> json) {
    return MigrationRecord(
      id: json['id'],
      version: json['version'],
      description: json['description'],
      status: MigrationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MigrationStatus.pending,
      ),
      startedAt: json['startedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['startedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['completedAt'])
          : null,
      errorMessage: json['errorMessage'],
    );
  }
}

/// Migration step
class MigrationStep {
  final String description;
  final Future<void> Function() migrate;
  final Future<void> Function()? rollback;

  MigrationStep({
    required this.description,
    required this.migrate,
    this.rollback,
  });
}

/// Migration class
class Migration {
  final String version;
  final String description;
  final List<MigrationStep> upSteps;
  final List<MigrationStep>? downSteps;

  Migration({
    required this.version,
    required this.description,
    required this.upSteps,
    this.downSteps,
  });

  /// Execute migration
  Future<void> execute(MigrationDirection direction) async {
    final steps = direction == MigrationDirection.up ? upSteps : (downSteps ?? upSteps);

    for (final step in steps) {
      await step.migrate();
    }
  }

  /// Rollback migration
  Future<void> rollback() async {
    if (downSteps != null) {
      for (final step in downSteps!.reversed) {
        await step.rollback?.call();
      }
    } else {
      for (final step in upSteps.reversed) {
        await step.rollback?.call();
      }
    }
  }
}

/// Migration service for handling data schema changes
class MigrationService {
  static final MigrationService _instance = MigrationService._internal();
  static MigrationService get instance => _instance;

  MigrationService._internal();

  final LocalStorageService _storage = LocalStorageService.instance;
  final DatabaseService _database = DatabaseService.instance;
  final List<Migration> _migrations = [];
  final List<MigrationRecord> _history = [];

  String? _currentVersion;

  /// Initialize migration service
  Future<void> initialize() async {
    await _storage.initialize();
    await _loadHistory();
    await _loadCurrentVersion();
  }

  /// Register a migration
  void registerMigration(Migration migration) {
    _migrations.add(migration);
    _migrations.sort((a, b) => a.version.compareTo(b.version));
  }

  /// Load migration history
  Future<void> _loadHistory() async {
    final historyJson = _storage.getJsonList('migration_history');
    if (historyJson != null) {
      _history.clear();
      for (final json in historyJson) {
        if (json is Map<String, dynamic>) {
          _history.add(MigrationRecord.fromJson(json));
        }
      }
    }
  }

  /// Save migration history
  Future<void> _saveHistory() async {
    final jsonList = _history.map((r) => r.toJson()).toList();
    await _storage.setJsonList('migration_history', jsonList);
  }

  /// Load current schema version
  Future<void> _loadCurrentVersion() async {
    _currentVersion = _storage.getString('schema_version');
  }

  /// Save current schema version
  Future<void> _saveCurrentVersion(String version) async {
    _currentVersion = version;
    await _storage.setString('schema_version', version);
  }

  /// Get current schema version
  String? getCurrentVersion() => _currentVersion;

  /// Get all pending migrations
  List<Migration> getPendingMigrations() {
    if (_currentVersion == null) {
      return _migrations;
    }

    return _migrations.where((m) {
      return m.version.compareTo(_currentVersion!) > 0;
    }).toList();
  }

  /// Run all pending migrations
  Future<bool> migrate({bool onConflict = false}) async {
    final pending = getPendingMigrations();

    if (pending.isEmpty) {
      return true;
    }

    try {
      for (final migration in pending) {
        final success = await _runMigration(migration);

        if (!success && !onConflict) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Run a single migration
  Future<bool> _runMigration(Migration migration) async {
    final record = MigrationRecord(
      id: 'migration_${migration.version}_${DateTime.now().millisecondsSinceEpoch}',
      version: migration.version,
      description: migration.description,
      status: MigrationStatus.running,
      startedAt: DateTime.now(),
    );

    _history.add(record);
    await _saveHistory();

    try {
      // Execute migration steps
      await migration.execute(MigrationDirection.up);

      // Update record
      record.status = MigrationStatus.completed;
      record.completedAt = DateTime.now();
      await _saveHistory();

      // Update current version
      await _saveCurrentVersion(migration.version);

      return true;
    } catch (e) {
      // Rollback on error
      await migration.rollback();

      record.status = MigrationStatus.failed;
      record.completedAt = DateTime.now();
      record.errorMessage = e.toString();
      await _saveHistory();

      return false;
    }
  }

  /// Rollback to a specific version
  Future<bool> rollbackTo(String targetVersion) async {
    if (_currentVersion == null) {
      return false;
    }

    try {
      // Get migrations to rollback (in reverse order)
      final toRollback = _migrations.where((m) {
        return m.version.compareTo(_currentVersion!) <= 0 &&
               m.version.compareTo(targetVersion) > 0;
      }).toList()
        ..sort((a, b) => b.version.compareTo(a.version));

      for (final migration in toRollback) {
        await migration.rollback();

        final record = MigrationRecord(
          id: 'rollback_${migration.version}_${DateTime.now().millisecondsSinceEpoch}',
          version: migration.version,
          description: 'Rollback: ${migration.description}',
          status: MigrationStatus.rolledBack,
          startedAt: DateTime.now(),
          completedAt: DateTime.now(),
        );

        _history.add(record);
      }

      await _saveHistory();
      await _saveCurrentVersion(targetVersion);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get migration history
  List<MigrationRecord> getHistory() => List.unmodifiable(_history);

  /// Clear migration history (use with caution)
  Future<void> clearHistory() async {
    _history.clear();
    await _saveHistory();
  }

  /// Check if migration is needed
  bool needsMigration() {
    return getPendingMigrations().isNotEmpty;
  }

  // ==================== Built-in Migrations ====================

  /// Register built-in migrations
  void registerBuiltInMigrations() {
    // Migration 1.0.0: Initial schema
    registerMigration(Migration(
      version: '1.0.0',
      description: 'Initial database schema',
      upSteps: [
        MigrationStep(
          description: 'Create initial tables',
          migrate: () async {
            // Database schema is created by DatabaseService
            await _database.initialize();
          },
        ),
      ],
    ));

    // Migration 1.1.0: Add user settings
    registerMigration(Migration(
      version: '1.1.0',
      description: 'Add user preferences table',
      upSteps: [
        MigrationStep(
          description: 'Create user_preferences table',
          migrate: () async {
            await _database.execute('''
              CREATE TABLE IF NOT EXISTS user_preferences (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id TEXT NOT NULL,
                preference_key TEXT NOT NULL,
                preference_value TEXT,
                updated_at INTEGER,
                UNIQUE(user_id, preference_key)
              )
            ''');
          },
          rollback: () async {
            await _database.execute('DROP TABLE IF EXISTS user_preferences');
          },
        ),
      ],
    ));

    // Migration 1.2.0: Add analytics events
    registerMigration(Migration(
      version: '1.2.0',
      description: 'Add analytics events table',
      upSteps: [
        MigrationStep(
          description: 'Create analytics_events table',
          migrate: () async {
            await _database.execute('''
              CREATE TABLE IF NOT EXISTS analytics_events (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id TEXT,
                event_name TEXT NOT NULL,
                event_data TEXT,
                timestamp INTEGER,
                synced INTEGER DEFAULT 0
              )
            ''');
          },
          rollback: () async {
            await _database.execute('DROP TABLE IF EXISTS analytics_events');
          },
        ),
      ],
    ));

    // Migration 1.3.0: Add cache tables
    registerMigration(Migration(
      version: '1.3.0',
      description: 'Add cache tables',
      upSteps: [
        MigrationStep(
          description: 'Create cache table',
          migrate: () async {
            await _database.execute('''
              CREATE TABLE IF NOT EXISTS cache (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL,
                expires_at INTEGER,
                created_at INTEGER
              )
            ''');
          },
          rollback: () async {
            await _database.execute('DROP TABLE IF EXISTS cache');
          },
        ),
      ],
    ));
  }
}
