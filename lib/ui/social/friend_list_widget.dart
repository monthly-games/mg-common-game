import 'package:flutter/material.dart';
import 'package:mg_common_game/social/friend_manager.dart';

class FriendListWidget extends StatefulWidget {
  final String userId;

  const FriendListWidget({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<FriendListWidget> createState() => _FriendListWidgetState();
}

class _FriendListWidgetState extends State<FriendListWidget> {
  final FriendManager _friendManager = FriendManager.instance;
  List<Friend> _friends = [];
  List<FriendRequest> _requests = [];
  List<FriendSuggestion> _suggestions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _friendManager.initialize();
    setState(() => _isLoading = true);
    _friends = _friendManager.getFriends(widget.userId);
    _requests = await _friendManager.getPendingRequests(widget.userId);
    _suggestions = _friendManager.getFriendSuggestions(userId: widget.userId);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Friends'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: _showAddFriendDialog,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Friends'),
              Tab(text: 'Requests'),
              Tab(text: 'Suggestions'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildFriendsList(),
                  _buildRequestsList(),
                  _buildSuggestionsList(),
                ],
              ),
      ),
    );
  }

  Widget _buildFriendsList() {
    if (_friends.isEmpty) {
      return const Center(child: Text('No friends yet'));
    }

    final onlineFriends = _friends.where((f) => f.isOnline).toList();
    final offlineFriends = _friends.where((f) => !f.isOnline).toList();

    return ListView(
      children: [
        if (onlineFriends.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Online (${onlineFriends.length})',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ),
          ...onlineFriends.map((friend) => _buildFriendTile(friend)),
          const Divider(),
        ],
        if (offlineFriends.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Offline (${offlineFriends.length})',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          ...offlineFriends.map((friend) => _buildFriendTile(friend)),
        ],
      ],
    );
  }

  Widget _buildFriendTile(Friend friend) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            child: Text(friend.username[0].toUpperCase()),
          ),
          if (friend.isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      title: Text(friend.username),
      subtitle: Text(friend.isOnline ? 'Online' : 'Offline'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () => _startChat(friend),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleFriendAction(value, friend),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('View Profile'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'remove',
                child: ListTile(
                  leading: Icon(Icons.person_remove, color: Colors.red),
                  title: Text('Remove Friend', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    if (_requests.isEmpty) {
      return const Center(child: Text('No pending requests'));
    }

    return ListView.builder(
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final request = _requests[index];
        return _buildRequestTile(request);
      },
    );
  }

  Widget _buildRequestTile(FriendRequest request) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(request.fromUsername[0].toUpperCase()),
      ),
      title: Text(request.fromUsername),
      subtitle: Text('Sent ${_getTimeAgo(request.sentAt)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () => _acceptRequest(request),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => _declineRequest(request),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    if (_suggestions.isEmpty) {
      return const Center(child: Text('No suggestions available'));
    }

    return ListView.builder(
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return _buildSuggestionTile(suggestion);
      },
    );
  }

  Widget _buildSuggestionTile(FriendSuggestion suggestion) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(suggestion.username[0].toUpperCase()),
      ),
      title: Text(suggestion.username),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Level ${suggestion.level}'),
          if (suggestion.mutualFriends > 0)
            Text(
              '${suggestion.mutualFriends} mutual friends',
              style: const TextStyle(fontSize: 12, color: Colors.blue),
            ),
          if (suggestion.reasons.isNotEmpty)
            Wrap(
              spacing: 4,
              children: suggestion.reasons.take(2).map((reason) =>
                Chip(
                  label: Text(reason, style: const TextStyle(fontSize: 10)),
                  padding: EdgeInsets.zero,
                ),
              ).toList(),
            ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.person_add),
        onPressed: () => _sendRequest(suggestion.userId),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showAddFriendDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Friend'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Username or ID',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _sendRequest(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendRequest(String userId) async {
    final success = await _friendManager.sendFriendRequest(
      fromUserId: widget.userId,
      toUserId: userId,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request sent!')),
      );
    }
  }

  Future<void> _acceptRequest(FriendRequest request) async {
    final success = await _friendManager.respondToRequest(
      requestId: request.requestId,
      response: FriendRequestResponse.accepted,
    );

    if (success && mounted) {
      setState(() => _requests.remove(request));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${request.fromUsername} is now your friend!')),
      );
      _loadData();
    }
  }

  Future<void> _declineRequest(FriendRequest request) async {
    final success = await _friendManager.respondToRequest(
      requestId: request.requestId,
      response: FriendRequestResponse.declined,
    );

    if (success && mounted) {
      setState(() => _requests.remove(request));
      _loadData();
    }
  }

  Future<void> _removeFriend(Friend friend) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text('Are you sure you want to remove ${friend.username}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _friendManager.removeFriend(
        userId: widget.userId,
        friendId: friend.friendId,
      );
      _loadData();
    }
  }

  void _startChat(Friend friend) {
  }

  void _handleFriendAction(String action, Friend friend) {
    switch (action) {
      case 'profile':
      case 'remove':
        _removeFriend(friend);
    }
  }
}
