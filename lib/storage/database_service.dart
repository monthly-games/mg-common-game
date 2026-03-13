import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Database service for complex data storage using SQLite
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;

  DatabaseService._internal();

  Database? _database;

  /// Get the database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mg_game.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // User table
    await db.execute('''
      CREATE TABLE users (
        user_id TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        email TEXT,
        level INTEGER DEFAULT 1,
        xp INTEGER DEFAULT 0,
        created_at INTEGER,
        last_login INTEGER,
        settings TEXT
      )
    ''');

    // Inventory table
    await db.execute('''
      CREATE TABLE inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        item_id TEXT NOT NULL,
        item_name TEXT NOT NULL,
        quantity INTEGER DEFAULT 1,
        item_type TEXT,
        durability REAL,
        metadata TEXT,
        created_at INTEGER,
        FOREIGN KEY (user_id) REFERENCES users (user_id)
      )
    ''');

    // Currency table
    await db.execute('''
      CREATE TABLE currency (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        currency_id TEXT NOT NULL,
        amount INTEGER DEFAULT 0,
        updated_at INTEGER,
        FOREIGN KEY (user_id) REFERENCES users (user_id),
        UNIQUE(user_id, currency_id)
      )
    ''');

    // Friends table
    await db.execute('''
      CREATE TABLE friends (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        friend_id TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        created_at INTEGER,
        updated_at INTEGER,
        FOREIGN KEY (user_id) REFERENCES users (user_id),
        UNIQUE(user_id, friend_id)
      )
    ''');

    // Quests table
    await db.execute('''
      CREATE TABLE user_quests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        quest_id TEXT NOT NULL,
        status TEXT DEFAULT 'active',
        progress TEXT,
        completed_at INTEGER,
        claimed_at INTEGER,
        FOREIGN KEY (user_id) REFERENCES users (user_id),
        UNIQUE(user_id, quest_id)
      )
    ''');

    // Achievements table
    await db.execute('''
      CREATE TABLE user_achievements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        achievement_id TEXT NOT NULL,
        progress REAL DEFAULT 0,
        is_completed INTEGER DEFAULT 0,
        unlocked_at INTEGER,
        claimed_at INTEGER,
        FOREIGN KEY (user_id) REFERENCES users (user_id),
        UNIQUE(user_id, achievement_id)
      )
    ''');

    // Chat messages table
    await db.execute('''
      CREATE TABLE chat_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        channel_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        sender_name TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp INTEGER,
        type TEXT,
        metadata TEXT
      )
    ''');

    // Mail table
    await db.execute('''
      CREATE TABLE mail (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mail_id TEXT NOT NULL,
        receiver_id TEXT NOT NULL,
        sender_id TEXT,
        sender_name TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT,
        type TEXT,
        is_read INTEGER DEFAULT 0,
        is_collected INTEGER DEFAULT 0,
        attachments TEXT,
        created_at INTEGER,
        expires_at INTEGER,
        FOREIGN KEY (receiver_id) REFERENCES users (user_id)
      )
    ''');

    // Sessions table
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        session_token TEXT NOT NULL,
        created_at INTEGER,
        expires_at INTEGER,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES users (user_id)
      )
    ''');

    // Analytics events table
    await db.execute('''
      CREATE TABLE analytics_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        event_name TEXT NOT NULL,
        event_data TEXT,
        timestamp INTEGER,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Create indexes for better performance
    await _createIndexes(db);
  }

  /// Create database indexes
  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX idx_inventory_user ON inventory(user_id)');
    await db.execute('CREATE INDEX idx_currency_user ON currency(user_id)');
    await db.execute('CREATE INDEX idx_friends_user ON friends(user_id)');
    await db.execute('CREATE INDEX idx_friends_status ON friends(status)');
    await db.execute('CREATE INDEX idx_quests_user ON user_quests(user_id)');
    await db.execute('CREATE INDEX idx_achievements_user ON user_achievements(user_id)');
    await db.execute('CREATE INDEX idx_chat_channel ON chat_messages(channel_id)');
    await db.execute('CREATE INDEX idx_mail_receiver ON mail(receiver_id)');
    await db.execute('CREATE INDEX idx_sessions_user ON sessions(user_id)');
    await db.execute('CREATE INDEX idx_analytics_user ON analytics_events(user_id)');
    await db.execute('CREATE INDEX idx_analytics_synced ON analytics_events(synced)');
  }

  /// Upgrade database schema
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle schema upgrades
    if (oldVersion < 2) {
      // Add new columns or tables for version 2
    }
  }

  // ==================== Generic CRUD Operations ====================

  /// Insert a record
  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return await db.insert(table, values, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Query records
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// Update records
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, values, where: where, whereArgs: whereArgs);
  }

  /// Delete records
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  /// Execute a raw query
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  /// Execute a raw SQL statement
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    final db = await database;
    await db.execute(sql, arguments);
  }

  // ==================== Transaction Operations ====================

  /// Execute operations in a transaction
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  // ==================== Batch Operations ====================

  /// Execute multiple operations in a batch
  Future<List<Object?>> batch(List<BatchOperation> operations) async {
    final db = await database;
    final batch = db.batch();

    for (final op in operations) {
      switch (op.type) {
        case BatchOperationType.insert:
          batch.insert(op.table, op.data);
          break;
        case BatchOperationType.update:
          batch.update(op.table, op.data, where: op.where, whereArgs: op.whereArgs);
          break;
        case BatchOperationType.delete:
          batch.delete(op.table, where: op.where, whereArgs: op.whereArgs);
          break;
      }
    }

    return await batch.commit(continueOnError: false);
  }

  // ==================== Utility Operations ====================

  /// Get count of records
  Future<int> count(String table, {String? where, List<Object?>? whereArgs}) async {
    final result = await query(
      table,
      columns: ['COUNT(*) as count'],
      where: where,
      whereArgs: whereArgs,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Check if record exists
  Future<bool> exists(String table, {String? where, List<Object?>? whereArgs}) async {
    final count = await this.count(table, where: where, whereArgs: whereArgs);
    return count > 0;
  }

  /// Clear all data from a table
  Future<void> clearTable(String table) async {
    final db = await database;
    await db.delete(table);
  }

  /// Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // ==================== Game Specific Queries ====================

  /// Get user data with all related information
  Future<Map<String, dynamic>?> getUserFullData(String userId) async {
    final db = await database;

    // Get user basic info
    final users = await db.query(
      'users',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (users.isEmpty) return null;

    final user = users.first;

    // Get inventory
    final inventory = await db.query(
      'inventory',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    // Get currency
    final currency = await db.query(
      'currency',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    // Get friends
    final friends = await db.query(
      'friends',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return {
      ...user,
      'inventory': inventory,
      'currency': currency,
      'friends': friends,
    };
  }

  /// Clean up old data
  Future<void> cleanupOldData({Duration? maxAge}) async {
    final db = await database;
    final cutoffTime = DateTime.now().subtract(maxAge ?? const Duration(days: 30)).millisecondsSinceEpoch;

    // Delete old chat messages
    await db.delete(
      'chat_messages',
      where: 'timestamp < ?',
      whereArgs: [cutoffTime],
    );

    // Delete old mail
    await db.delete(
      'mail',
      where: 'expires_at < ?',
      whereArgs: [cutoffTime],
    );

    // Delete old sessions
    await db.delete(
      'sessions',
      where: 'expires_at < ?',
      whereArgs: [cutoffTime],
    );

    // Delete synced analytics events
    await db.delete(
      'analytics_events',
      where: 'synced = 1 AND timestamp < ?',
      whereArgs: [cutoffTime],
    );
  }
}

/// Batch operation type
enum BatchOperationType { insert, update, delete }

/// Batch operation
class BatchOperation {
  final BatchOperationType type;
  final String table;
  final Map<String, dynamic> data;
  final String? where;
  final List<Object?>? whereArgs;

  BatchOperation({
    required this.type,
    required this.table,
    required this.data,
    this.where,
    this.whereArgs,
  });
}
