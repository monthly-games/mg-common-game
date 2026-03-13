# MG Common Game - Getting Started Guide

## Overview

MG Common Game is a comprehensive Flutter framework for building mobile games with common features like user management, inventory systems, quests, achievements, analytics, and more.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Initial Setup](#initial-setup)
4. [Basic Usage](#basic-usage)
5. [Common Patterns](#common-patterns)
6. [Best Practices](#best-practices)
7. [Examples](#examples)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before you begin, ensure you have the following:

- **Flutter SDK**: 3.0.0 or higher
- **Dart SDK**: 2.17.0 or higher
- **Development Environment**:
  - Android Studio / VS Code with Flutter extensions
  - iOS Simulator (for iOS development) or Android Emulator
- **Basic Knowledge**:
  - Flutter/Dart fundamentals
  - Asynchronous programming (async/await)
  - Stream-based programming

---

## Installation

### Step 1: Add Dependency

Add `mg_common_game` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  mg_common_game:
    path: ../mg-common-game  # or version from pub.dev
```

### Step 2: Install Dependencies

Run the following command in your project root:

```bash
flutter pub get
```

### Step 3: Import the Package

In your Dart files:

```dart
import 'package:mg_common_game/user/user_manager.dart';
import 'package:mg_common_game/inventory/inventory_manager.dart';
import 'package:mg_common_game/quest/quest_manager.dart';
// ... other imports
```

---

## Initial Setup

### Initialize Services

In your `main.dart` file, initialize all required services:

```dart
import 'package:flutter/material.dart';
import 'package:mg_common_game/storage/local_storage_service.dart';
import 'package:mg_common_game/network/http_service.dart';
import 'package:mg_common_game/user/user_manager.dart';
import 'package:mg_common_game/inventory/inventory_manager.dart';
import 'package:mg_common_game/quest/quest_manager.dart';
import 'package:mg_common_game/analytics/analytics_manager.dart';
import 'package:mg_common_game/security/account_security_manager.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage service
  await LocalStorageService.instance.initialize();

  // Initialize HTTP service with base URL
  await HttpService.instance.initialize(
    baseUrl: 'https://api.yourgame.com',
    enableLogging: true,
  );

  // Initialize managers
  await UserManager.instance.initialize();
  await InventoryManager.instance.initialize();
  await QuestManager.instance.initialize();
  await AnalyticsManager.instance.initialize();
  await AccountSecurityManager.instance.initialize();

  // Run the app
  runApp(MyGameApp());
}
```

### Configure Managers

Customize manager behavior with configuration objects:

```dart
// Configure analytics
await AnalyticsManager.instance.initialize(
  config: AnalyticsConfig(
    enableAutoTracking: true,
    batchSize: 50,
    uploadInterval: Duration(minutes: 5),
    serverUrl: 'https://analytics.yourgame.com',
  ),
);

// Configure security
await AccountSecurityManager.instance.initialize(
  config: SecurityConfig(
    maxFailedAttempts: 5,
    lockoutDuration: Duration(minutes: 30),
    sessionTimeout: Duration(days: 7),
    require2FA: false,
  ),
);
```

---

## Basic Usage

### User Management

```dart
// Login user
final user = await UserManager.instance.login(
  username: 'player1',
  password: 'securepassword',
);

if (user != null) {
  print('Logged in: ${user.username}');
  print('Level: ${user.level}');
} else {
  print('Login failed');
}

// Get current user
final currentUser = UserManager.instance.currentUser;

// Update user profile
await UserManager.instance.updateProfile(
  username: 'player1',
  settings: {
    'soundEnabled': true,
    'musicVolume': 0.8,
  },
);

// Logout
await UserManager.instance.logout();
```

### Inventory Management

```dart
// Get user's inventory
final inventory = await InventoryManager.instance.getInventory('user_1');

// Add item to inventory
await InventoryManager.instance.addItem(
  userId: 'user_1',
  itemId: 'sword_1',
  quantity: 1,
);

// Remove item from inventory
await InventoryManager.instance.removeItem(
  userId: 'user_1',
  itemId: 'potion_1',
  quantity: 2,
);

// Update item durability
await InventoryManager.instance.updateItemDurability(
  userId: 'user_1',
  itemId: 'sword_1',
  durability: 85,
);
```

### Quest Management

```dart
// Get available quests
final quests = await QuestManager.instance.getQuests('user_1');

// Accept a quest
await QuestManager.instance.acceptQuest(
  userId: 'user_1',
  questId: 'daily_quest_1',
);

// Update quest progress
await QuestManager.instance.updateQuestProgress(
  userId: 'user_1',
  questId: 'daily_quest_1',
  objectiveId: 'obj_1',
  progress: 5,
);

// Claim quest rewards
final rewards = await QuestManager.instance.claimQuestRewards(
  userId: 'user_1',
  questId: 'daily_quest_1',
);
```

### Shop Integration

```dart
// Get shop items
final items = await ShopManager.instance.getShopItems(
  category: 'weapons',
);

// Purchase item
final purchase = await ShopManager.instance.purchaseItem(
  userId: 'user_1',
  itemId: 'shop_item_1',
  quantity: 1,
);

if (purchase.success) {
  print('Purchased: ${purchase.itemName}');
  print('Cost: ${purchase.cost}');
} else {
  print('Purchase failed: ${purchase.error}');
}
```

### Analytics Tracking

```dart
// Track custom event
await AnalyticsManager.instance.trackEvent(
  eventName: 'level_completed',
  category: EventCategory.gameplay,
  parameters: {
    'level_id': 'level_1',
    'attempts': 3,
    'time_spent': 120,
  },
);

// Track screen view
await AnalyticsManager.instance.trackScreenView(
  screenName: 'MainMenu',
  screenClass: 'MainMenuPage',
);

// Track purchase
await AnalyticsManager.instance.trackPurchase(
  itemId: 'gem_pack_1',
  itemType: 'currency',
  price: 4.99,
  currency: 'USD',
);
```

---

## Common Patterns

### Pattern 1: Reactive UI with Streams

Use streams to automatically update UI when data changes:

```dart
class UserProfileWidget extends StatefulWidget {
  @override
  _UserProfileWidgetState createState() => _UserProfileWidgetState();
}

class _UserProfileWidgetState extends State<UserProfileWidget> {
  StreamSubscription? _userSubscription;

  @override
  void initState() {
    super.initState();

    // Listen to user changes
    _userSubscription = UserManager.instance.userStream.listen((user) {
      setState(() {
        // UI will rebuild when user data changes
      });
    });
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = UserManager.instance.currentUser;

    if (user == null) {
      return CircularProgressIndicator();
    }

    return Column(
      children: [
        Text('Username: ${user.username}'),
        Text('Level: ${user.level}'),
        Text('XP: ${user.xp}'),
      ],
    );
  }
}
```

### Pattern 2: Error Handling

Handle errors gracefully:

```dart
try {
  final result = await UserManager.instance.login(
    username: username,
    password: password,
  );

  if (result != null) {
    // Success
    _navigateToHome();
  } else {
    // Failed
    _showError('Invalid credentials');
  }
} on NetworkException catch (e) {
  _showError('Network error: ${e.message}');
} on AuthException catch (e) {
  _showError('Authentication failed: ${e.message}');
} catch (e) {
  _showError('Unexpected error: ${e.toString()}');
}
```

### Pattern 3: Loading States

Show loading indicators during async operations:

```dart
class ShopWidget extends StatefulWidget {
  @override
  _ShopWidgetState createState() => _ShopWidgetState();
}

class _ShopWidgetState extends State<ShopWidget> {
  bool _isLoading = true;
  List<ShopItem>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadShopItems();
  }

  Future<void> _loadShopItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await ShopManager.instance.getShopItems();
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    if (_items == null || _items!.isEmpty) {
      return Center(child: Text('No items available'));
    }

    return ListView.builder(
      itemCount: _items!.length,
      itemBuilder: (context, index) {
        final item = _items![index];
        return ListTile(
          title: Text(item.name),
          subtitle: Text('${item.price} gold'),
          trailing: ElevatedButton(
            onPressed: () => _purchaseItem(item),
            child: Text('Buy'),
          ),
        );
      },
    );
  }

  Future<void> _purchaseItem(ShopItem item) async {
    // Purchase logic here
  }
}
```

### Pattern 4: Data Caching

Implement caching for better performance:

```dart
class CachedDataManager {
  final Duration _cacheTimeout = Duration(minutes: 5);

  Future<List<ShopItem>> getShopItems() async {
    // Try to get from cache first
    final cached = _storage.getJson('cached_shop_items');
    if (cached != null) {
      final timestamp = DateTime.fromMillisecondsSinceEpoch(cached['timestamp']);
      if (DateTime.now().isBefore(timestamp.add(_cacheTimeout))) {
        return (cached['items'] as List)
          .map((json) => ShopItem.fromJson(json))
          .toList();
      }
    }

    // Cache miss or expired, fetch from server
    final items = await ShopManager.instance.getShopItems();

    // Update cache
    await _storage.setJson('cached_shop_items', {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'items': items.map((item) => item.toJson()).toList(),
    });

    return items;
  }
}
```

---

## Best Practices

### 1. Always Initialize First

Always initialize managers before using them:

```dart
// Good
await UserManager.instance.initialize();
final user = UserManager.instance.currentUser;

// Bad - will cause errors
final user = UserManager.instance.currentUser;
await UserManager.instance.initialize();
```

### 2. Handle Null Values

Many methods return nullable values:

```dart
// Good
final user = await UserManager.instance.login(username, password);
if (user != null) {
  // Process user
} else {
  // Handle failed login
}

// Bad - will cause null pointer exception
final user = await UserManager.instance.login(username, password);
print(user.username); // This will crash if user is null
```

### 3. Dispose Resources

Always dispose stream subscriptions and managers when done:

```dart
@override
void dispose() {
  _subscription?.cancel();
  super.dispose();
}
```

### 4. Use Config Objects

Customize behavior with config objects:

```dart
await AnalyticsManager.instance.initialize(
  config: AnalyticsConfig(
    enableAutoTracking: true,
    batchSize: 50,
    uploadInterval: Duration(minutes: 5),
  ),
);
```

### 5. Handle Errors Gracefully

Never let exceptions propagate to the UI:

```dart
try {
  await someOperation();
} catch (e) {
  // Log error
  print('Error: $e');
  // Show user-friendly message
  showError('Operation failed. Please try again.');
}
```

---

## Examples

### Example 1: Complete Login Flow

```dart
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await UserManager.instance.login(
        username: _usernameController.text,
        password: _passwordController.text,
      );

      if (user != null) {
        // Track login event
        await AnalyticsManager.instance.trackEvent(
          eventName: 'login_success',
          category: EventCategory.session,
          parameters: {'userId': user.userId},
        );

        // Navigate to home
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        setState(() {
          _error = 'Invalid username or password';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Login failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Colors.red),
                ),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter username';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter password';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      child: Text('Login'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Example 2: Shop with Purchase Flow

```dart
class ShopPage extends StatefulWidget {
  @override
  _ShopPageState createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  bool _isLoading = true;
  List<ShopItem>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadShopItems();
  }

  Future<void> _loadShopItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await ShopManager.instance.getShopItems();
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _purchaseItem(ShopItem item) async {
    try {
      final result = await ShopManager.instance.purchaseItem(
        userId: UserManager.instance.currentUser!.userId,
        itemId: item.itemId,
        quantity: 1,
      );

      if (result.success) {
        // Track purchase
        await AnalyticsManager.instance.trackPurchase(
          itemId: item.itemId,
          itemType: item.category,
          price: item.price,
          currency: 'USD',
        );

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchased ${item.name}!')),
        );

        // Refresh shop items
        _loadShopItems();
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: ${result.error}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Shop')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Shop')),
        body: Center(child: Text('Error: $_error')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Shop')),
      body: ListView.builder(
        itemCount: _items!.length,
        itemBuilder: (context, index) {
          final item = _items![index];
          return Card(
            child: ListTile(
              leading: Icon(Icons.shopping_bag),
              title: Text(item.name),
              subtitle: Text(item.description),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${item.price} gold', style: TextStyle(fontWeight: FontWeight.bold)),
                  if (item.discount > 0)
                    Text('${item.discount * 100}% off', style: TextStyle(color: Colors.green)),
                ],
              ),
              onTap: () => _purchaseItem(item),
            ),
          );
        },
      ),
    );
  }
}
```

---

## Troubleshooting

### Problem: Managers return null or throw errors

**Solution**: Make sure you've initialized the manager before using it:

```dart
await UserManager.instance.initialize();
final user = UserManager.instance.currentUser;
```

### Problem: Stream subscriptions cause memory leaks

**Solution**: Always cancel subscriptions in dispose:

```dart
@override
void dispose() {
  _subscription?.cancel();
  super.dispose();
}
```

### Problem: Network requests fail

**Solution**: Check your HTTP service configuration:

```dart
await HttpService.instance.initialize(
  baseUrl: 'https://api.yourgame.com',
  enableLogging: true, // Enable logging to see request details
);
```

### Problem: Data doesn't persist

**Solution**: Make sure storage service is initialized:

```dart
await LocalStorageService.instance.initialize();
```

### Problem: Analytics events aren't sent

**Solution**: Check analytics configuration and ensure server URL is correct:

```dart
await AnalyticsManager.instance.initialize(
  config: AnalyticsConfig(
    enableReporting: true,
    serverUrl: 'https://analytics.yourgame.com',
  ),
);
```

---

## Next Steps

1. **Explore More Features**: Check out the [API Documentation](API_DOCUMENTATION.md)
2. **Understand Architecture**: Read the [Architecture Documentation](ARCHITECTURE.md)
3. **Deploy Your App**: Follow the [Deployment Guide](DEPLOYMENT.md)
4. **Build Your Game**: Start implementing your game-specific features

---

## Support

If you encounter any issues or have questions:

1. Check the [Documentation](docs/)
2. Review the [Examples](examples/)
3. Report issues on GitHub
4. Contact the development team

Happy game development!
