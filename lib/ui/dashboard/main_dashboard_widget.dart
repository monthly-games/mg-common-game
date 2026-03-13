import 'package:flutter/material.dart';
import 'inventory_widget.dart';
import 'shop_widget.dart';
import 'quest_widget.dart';
import 'achievement_widget.dart';
import 'package:mg_common_game/ui/social/friend_list_widget.dart';
import 'package:mg_common_game/ui/social/mail_widget.dart';
import 'package:mg_common_game/ui/profile/profile_widget.dart';
import 'package:mg_common_game/ui/profile/stats_widget.dart';
import 'package:mg_common_game/ui/profile/leaderboard_widget.dart';

class MainDashboardWidget extends StatefulWidget {
  final String userId;

  const MainDashboardWidget({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<MainDashboardWidget> createState() => _MainDashboardWidgetState();
}

class _MainDashboardWidgetState extends State<MainDashboardWidget> {
  int _currentIndex = 0;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _initializeScreens();
  }

  void _initializeScreens() {
    _screens.addAll([
      const _HomeScreen(),
      ProfileWidget(userId: widget.userId),
      StatsWidget(userId: widget.userId),
      LeaderboardWidget(leaderboardId: 'global_level'),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Ranks',
          ),
        ],
      ),
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.2,
        children: [
          _buildDashboardCard(
            context,
            'Inventory',
            Icons.inventory_2,
            Colors.blue,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const InventoryWidget(userId: 'demo_user'),
              ),
            ),
          ),
          _buildDashboardCard(
            context,
            'Shop',
            Icons.shopping_cart,
            Colors.green,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ShopWidget(userId: 'demo_user'),
              ),
            ),
          ),
          _buildDashboardCard(
            context,
            'Quests',
            Icons.task_alt,
            Colors.orange,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const QuestWidget(userId: 'demo_user'),
              ),
            ),
          ),
          _buildDashboardCard(
            context,
            'Achievements',
            Icons.emoji_events,
            Colors.purple,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AchievementWidget(userId: 'demo_user'),
              ),
            ),
          ),
          _buildDashboardCard(
            context,
            'Friends',
            Icons.people,
            Colors.teal,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FriendListWidget(userId: 'demo_user'),
              ),
            ),
          ),
          _buildDashboardCard(
            context,
            'Mail',
            Icons.mail,
            Colors.red,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MailWidget(userId: 'demo_user'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.8),
                color.withOpacity(0.6),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
