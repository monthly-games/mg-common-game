# MG Common Game - Architecture Documentation

## Overview

MG Common Game follows a layered architecture pattern with clear separation of concerns. The system is built on Flutter/Dart and implements a singleton-based manager pattern for core services.

## Table of Contents

1. [Architecture Principles](#architecture-principles)
2. [System Layers](#system-layers)
3. [Manager Pattern](#manager-pattern)
4. [Data Flow](#data-flow)
5. [Storage Architecture](#storage-architecture)
6. [Network Architecture](#network-architecture)
7. [Security Architecture](#security-architecture)
8. [Analytics Architecture](#analytics-architecture)
9. [Concurrency Model](#concurrency-model)
10. [Error Handling](#error-handling)

---

## Architecture Principles

### 1. Single Responsibility Principle
Each manager class has a single, well-defined responsibility:
- `UserManager` handles user data and profile
- `InventoryManager` manages inventory items
- `QuestManager` tracks quest progress
- `AnalyticsManager` handles event tracking

### 2. Dependency Inversion
High-level modules don't depend on low-level modules. Both depend on abstractions through interfaces.

### 3. Open/Closed Principle
Classes are open for extension but closed for modification through configuration objects and strategy patterns.

### 4. Observer Pattern
Streams are used extensively for reactive communication between components.

### 5. Singleton Pattern
All managers use the singleton pattern to ensure single instance and global access.

---

## System Layers

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│                   (UI Components/Widgets)                │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                     Business Logic Layer                 │
│              (Managers, Services, Controllers)           │
│  ┌──────────┬──────────┬──────────┬──────────────────┐  │
│  │   User   │ Inventory │  Quest   │   Analytics      │  │
│  │ Manager  │ Manager   │ Manager  │   Manager        │  │
│  └──────────┴──────────┴──────────┴──────────────────┘  │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                      Data Access Layer                   │
│  ┌──────────────┬──────────────┬──────────────────────┐ │
│  │   Storage    │   Network    │    Security          │ │
│  │   Service    │   Service    │    Services          │ │
│  └──────────────┴──────────────┴──────────────────────┘ │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                   Infrastructure Layer                   │
│  ┌──────────────┬──────────────┬──────────────────────┐ │
│  │  File System │  HTTP Client │  Local Storage       │ │
│  └──────────────┴──────────────┴──────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### Presentation Layer
**Purpose**: User interface and interaction
**Components**: Widgets, Pages, Views
**Responsibilities**:
- Display data to users
- Capture user input
- Visualize game state
- Handle user gestures

### Business Logic Layer
**Purpose**: Core game logic and business rules
**Components**: Managers, Services, Controllers
**Responsibilities**:
- Implement game rules
- Coordinate between systems
- Validate user actions
- Manage game state

### Data Access Layer
**Purpose**: Data persistence and external communication
**Components**: Storage Service, Network Service, Security Services
**Responsibilities**:
- Persist data locally
- Communicate with servers
- Encrypt sensitive data
- Cache frequently accessed data

### Infrastructure Layer
**Purpose**: Low-level system operations
**Components**: File System, HTTP Client, Local Storage
**Responsibilities**:
- File I/O operations
- Network requests
- Key-value storage
- Platform-specific operations

---

## Manager Pattern

All managers follow the singleton pattern:

```dart
class ExampleManager {
  // Private constructor
  ExampleManager._internal();

  // Static instance
  static final ExampleManager _instance = ExampleManager._internal();

  // Public accessor
  static ExampleManager get instance => _instance;

  // Initialization flag
  bool _isInitialized = false;

  // Initialize method
  Future<void> initialize({Config? config}) async {
    if (_isInitialized) return;
    // Setup logic here
    _isInitialized = true;
  }

  // Dispose method
  void dispose() {
    // Cleanup logic here
  }
}
```

### Manager Lifecycle

```
┌─────────────┐
│   Create    │
│  Instance   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Initialize  │◄─────────────────┐
│  (async)    │                  │
└──────┬──────┘                  │
       │                         │
       ▼                         │
┌─────────────┐                  │
│     Use     │                  │
│  Instance   │                  │
└──────┬──────┘                  │
       │                         │
       ▼                         │
┌─────────────┐                  │
│   Dispose   │──────────────────┘
└─────────────┘
```

### Stream-Based Communication

Managers communicate through streams for reactive updates:

```dart
class ExampleManager {
  final StreamController<Event> _eventController =
    StreamController.broadcast();

  Stream<Event> get eventStream => _eventController.stream;

  void _emitEvent(Event event) {
    _eventController.add(event);
  }

  void dispose() {
    _eventController.close();
  }
}
```

---

## Data Flow

### Read Operation Flow

```
┌──────────────┐
│ UI Component │
└──────┬───────┘
       │ Request
       ▼
┌──────────────┐
│   Manager    │
└──────┬───────┘
       │ Query
       ▼
┌──────────────┐
│ Storage/     │
│ Network      │
└──────┬───────┘
       │ Return
       ▼
┌──────────────┐
│   Manager    │
└──────┬───────┘
       │ Emit via Stream
       ▼
┌──────────────┐
│ UI Component │
└──────────────┘
```

### Write Operation Flow

```
┌──────────────┐
│ UI Component │
└──────┬───────┘
       │ Action
       ▼
┌──────────────┐
│   Manager    │
└──────┬───────┘
       │ Validate
       ▼
┌──────────────┐
│   Manager    │
└──────┬───────┘
       │ Persist
       ▼
┌──────────────┐
│ Storage/     │
│ Network      │
└──────┬───────┘
       │ Confirm
       ▼
┌──────────────┐
│   Manager    │
└──────┬───────┘
       │ Emit Event
       ▼
┌──────────────┐
│ UI Component │
└──────────────┘
```

---

## Storage Architecture

### Local Storage Service

The `LocalStorageService` provides a unified interface for local data persistence:

```dart
class LocalStorageService {
  Future<void> initialize();
  Future<bool> setString(String key, String value);
  Future<String?> getString(String key);
  Future<bool> setJson(String key, Map<String, dynamic> value);
  Map<String, dynamic>? getJson(String key);
  Future<bool> setJsonList(String key, List<Map<String, dynamic>> value);
  List<Map<String, dynamic>>? getJsonList(String key);
  Future<bool> remove(String key);
  Future<bool> clear();
}
```

### Storage Patterns

#### 1. Single Entity Storage
```dart
// Store single entity
await _storage.setJson('user_$userId', user.toJson());

// Retrieve single entity
final userJson = _storage.getJson('user_$userId');
final user = userJson != null ? User.fromJson(userJson) : null;
```

#### 2. List Storage
```dart
// Store list of entities
await _storage.setJsonList('quests', quests.map((q) => q.toJson()).toList());

// Retrieve list
final questsJson = _storage.getJsonList('quests');
final quests = questsJson?.map((j) => Quest.fromJson(j)).toList() ?? [];
```

#### 3. Cache Storage
```dart
// Store with timestamp
final cache = {
  'data': data.toJson(),
  'timestamp': DateTime.now().millisecondsSinceEpoch,
  'ttl': ttl.inMilliseconds,
};
await _storage.setJson('cache_key', cache);

// Check validity
final cached = _storage.getJson('cache_key');
if (cached != null) {
  final timestamp = DateTime.fromMillisecondsSinceEpoch(cached['timestamp']);
  final ttl = Duration(milliseconds: cached['ttl']);
  if (DateTime.now().isBefore(timestamp.add(ttl))) {
    return cached['data'];
  }
}
```

### Storage Hierarchy

```
Storage/
├── user/              # User-specific data
│   ├── user_{id}
│   ├── profile_{id}
│   └── settings_{id}
├── game/              # Game state
│   ├── quests
│   ├── achievements
│   └── inventory_{id}
├── session/           # Session data
│   ├── session_{id}
│   └── auth_tokens
├── cache/             # Cached data
│   ├── shop_items
│   └── leaderboards
└── security/          # Security data
    ├── 2fa_configs
    └── sessions
```

---

## Network Architecture

### HTTP Service

The `HttpService` provides a wrapper around HTTP requests:

```dart
class HttpService {
  Future<Response> get(String path, {Map<String, dynamic>? queryParams});
  Future<Response> post(String path, {dynamic body});
  Future<Response> put(String path, {dynamic body});
  Future<Response> delete(String path);
  Future<Response> patch(String path, {dynamic body});
}
```

### Request/Response Flow

```
┌──────────────┐
│   Manager    │
└──────┬───────┘
       │ Request
       ▼
┌──────────────┐
│ HttpService  │
└──────┬───────┘
       │ Add Headers
       ▼
┌──────────────┐
│ HTTP Client  │
└──────┬───────┘
       │ Send Request
       ▼
┌──────────────┐
│   Server     │
└──────┬───────┘
       │ Response
       ▼
┌──────────────┐
│ HTTP Client  │
└──────┬───────┘
       │ Parse
       ▼
┌──────────────┐
│ HttpService  │
└──────┬───────┘
       │ Return
       ▼
┌──────────────┐
│   Manager    │
└──────────────┘
```

### Error Handling Strategy

```dart
try {
  final response = await _httpService.get('/api/users/$userId');
  if (response.statusCode == 200) {
    return User.fromJson(response.data);
  } else if (response.statusCode == 404) {
    throw UserNotFoundException();
  }
} on NetworkException catch (e) {
  // Handle network errors
  throw UserDataFetchException();
} on ParseException catch (e) {
  // Handle parsing errors
  throw UserInvalidDataException();
}
```

---

## Security Architecture

### Security Layer Components

```
Security Layer
├── Account Security Manager
│   ├── Session Management
│   ├── Password Policy
│   ├── Two-Factor Authentication
│   └── Failed Attempt Tracking
├── Content Filter
│   ├── Profanity Filter
│   ├── Spam Filter
│   ├── Harassment Filter
│   └── Personal Info Filter
└── Report System
    ├── Report Submission
    ├── Report Review
    └── User Actions
```

### Security Data Flow

```
┌──────────────┐
│ User Action  │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  Validation  │◄─────────────────┐
│  (Security)  │                  │
└──────┬───────┘                  │
       │ Valid                    │
       ▼                          │
┌──────────────┐                  │
│   Manager    │                  │
└──────┬───────┘                  │
       │                          │
       ▼                          │
┌──────────────┐                  │
│ Storage/     │                  │
│ Network      │                  │
└──────────────┘                  │
       │                          │
       ▼                          │
┌──────────────┐                  │
│ Security     │──────────────────┘
│  Event Log   │
└──────────────┘
```

### Encryption Strategy

```dart
// Sensitive data encryption
String encrypt(String data) {
  final key = _getEncryptionKey();
  final encrypted = _encrypter.encrypt(data, key: key);
  return encrypted.base64;
}

String decrypt(String encryptedData) {
  final key = _getEncryptionKey();
  final decrypted = _encrypter.decrypt64(encryptedData, key: key);
  return decrypted;
}
```

---

## Analytics Architecture

### Analytics Components

```
Analytics System
├── Event Tracker
│   ├── Event Capture
│   ├── Event Buffering
│   └── Batch Upload
├── Performance Monitor
│   ├── FPS Tracking
│   ├── Memory Tracking
│   └── CPU Tracking
├── Crash Reporter
│   ├── Auto-Capture
│   ├── Stack Trace Parsing
│   └── Crash Statistics
└── A/B Testing
    ├── Experiment Management
    ├── Variant Assignment
    └── Result Tracking
```

### Event Flow

```
┌──────────────┐
│ User Action  │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Event Track  │
└──────┬───────┘
       │ Add to Buffer
       ▼
┌──────────────┐
│ Event Buffer │
└──────┬───────┘
       │ Buffer Full?
       ▼
┌──────────────┐
│ Batch Upload │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Analytics    │
│   Server     │
└──────────────┘
```

---

## Concurrency Model

### Async/Await Pattern

All I/O operations use async/await:

```dart
Future<User> getUser(String userId) async {
  // Check cache first
  final cached = _storage.getJson('user_$userId');
  if (cached != null) {
    return User.fromJson(cached);
  }

  // Fetch from network
  final response = await _httpService.get('/users/$userId');
  await _storage.setJson('user_$userId', response.data);

  return User.fromJson(response.data);
}
```

### Stream Processing

Streams for real-time updates:

```dart
// Subscribe to stream
manager.eventStream.listen((event) {
  // Handle event
  _updateUI(event);
});

// Cancel subscription
subscription.cancel();
```

### Synchronization

```dart
class ConcurrentOperation {
  final Lock _lock = Lock();

  Future<void> safeOperation() async {
    await _lock.synchronized(() async {
      // Critical section
      await _performOperation();
    });
  }
}
```

---

## Error Handling

### Exception Hierarchy

```
Exception
├── MgException (base)
│   ├── NetworkException
│   │   ├── HttpException
│   │   └── TimeoutException
│   ├── StorageException
│   │   ├── IOException
│   │   └── SerializationException
│   ├── ValidationException
│   │   ├── AuthException
│   │   └── DataValidationException
│   └── SecurityException
│       ├── AccountLockedException
│       └── UnauthorizedAccessException
```

### Error Recovery Strategy

```dart
try {
  await riskyOperation();
} on TemporaryException catch (e) {
  // Retry with backoff
  await Future.delayed(Duration(seconds: 1));
  await riskyOperation();
} on PermanentException catch (e) {
  // Log and notify user
  _logger.error(e);
  _showErrorToUser(e);
} on Exception catch (e) {
  // Unexpected error
  _logger.error(e);
  _reportError(e);
  rethrow;
}
```

---

## Best Practices

### 1. Initialization Order

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services in order
  await LocalStorageService.instance.initialize();
  await HttpService.instance.initialize();

  // Initialize managers
  await UserManager.instance.initialize();
  await InventoryManager.instance.initialize();

  runApp(MyApp());
}
```

### 2. Resource Management

```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = manager.stream.listen((data) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build widget
  }
}
```

### 3. Testing Strategy

```dart
// Mock manager for testing
class MockUserManager implements UserManager {
  User? _mockUser;

  @override
  User? get currentUser => _mockUser;

  void setMockUser(User user) {
    _mockUser = user;
  }
}
```

---

## Performance Considerations

### 1. Lazy Loading
Load data only when needed to reduce startup time.

### 2. Caching
Cache frequently accessed data to reduce network calls.

### 3. Batch Operations
Group multiple operations together to reduce overhead.

### 4. Stream Debouncing
Debounce rapid stream updates to prevent excessive rebuilds.

```dart
manager.stream
  .debounceTime(Duration(milliseconds: 300))
  .listen((data) {
    setState(() {});
  });
```

---

## Scalability Considerations

### 1. Horizontal Scaling
Stateless managers can be easily scaled horizontally.

### 2. Database Sharding
Large user bases can be sharded by user ID.

### 3. CDN Caching
Static assets can be cached on CDN nodes.

### 4. Event Streaming
Analytics events can be streamed for real-time processing.

---

## Future Enhancements

1. **Microservices Architecture**: Break down monolithic managers into microservices
2. **GraphQL API**: Replace REST with GraphQL for more efficient data fetching
3. **Real-time Updates**: Implement WebSocket connections for live updates
4. **Offline-First**: Improve offline support with better sync mechanisms
5. **Machine Learning**: Add ML-powered features for personalization

---

## Conclusion

The MG Common Game architecture provides a solid foundation for building scalable, maintainable game applications. The clear separation of concerns, consistent patterns, and comprehensive documentation make it easy to understand and extend the system.
