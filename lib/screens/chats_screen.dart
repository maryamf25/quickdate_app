import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/user_details.dart';
import 'social_login_service.dart';
import 'chat_conversation_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  List<dynamic> _conversations = [];
  List<dynamic> _requests = [];
  bool _loading = true;
  int _requestsCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    print('📱 Fetching conversation list...');
    setState(() => _loading = true);

    try {
      final url = Uri.parse('${SocialLoginService.baseUrl}/messages/get_conversation_list');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'access_token': UserDetails.accessToken,
          'limit': '50',
          'offset': '0',
        },
      );

      print('📱 Conversations response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📱 Conversations data structure: ${data.keys.toList()}');

        if (data['code'] == 200) {
          setState(() {
            _conversations = List<dynamic>.from(data['data'] ?? []);
            _requests = List<dynamic>.from(data['requests'] ?? []);
            _requestsCount = data['requests_count'] ?? 0;
            _loading = false;
          });
          print('📱 Loaded ${_conversations.length} conversations and ${_requests.length} requests');
        } else {
          print('❌ Conversations API error: ${data['message'] ?? 'Unknown error'}');
          setState(() {
            _conversations = [];
            _requests = [];
            _loading = false;
          });
        }
      } else {
        print('❌ Conversations API failed with status: ${response.statusCode}');
        setState(() => _loading = false);
      }
    } catch (e) {
      print('💥 Error fetching conversations: $e');
      setState(() => _loading = false);
    }
  }

  void _openConversation(dynamic conversation) {
    print('📱 Opening conversation with: ${conversation['username']}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatConversationScreen(
          conversation: conversation,
          onMessageSent: () {
            // Refresh conversations when a message is sent
            _fetchConversations();
          },
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      if (timestamp == null) return '';

      DateTime dateTime;
      if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else if (timestamp is int) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(
          timestamp.toString().length <= 10 ? timestamp * 1000 : timestamp,
        );
      } else {
        return '';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.person_add),
                if (_requestsCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_requestsCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              // TODO: Navigate to chat requests screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$_requestsCount chat requests'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchConversations,
          ),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _conversations.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _fetchConversations,
              child: ListView.separated(
                itemCount: _conversations.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final conversation = _conversations[index];
                  return _buildConversationTile(conversation);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start chatting with people you match with',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Navigate to trending/discover page
              // This assumes the parent widget can handle navigation
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            child: const Text('Discover People'),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(dynamic conversation) {
    final username = conversation['username']?.toString() ?? 'Unknown User';
    final avatar = conversation['avatar']?.toString() ?? conversation['avater']?.toString() ?? '';
    final lastMessage = conversation['text']?.toString() ?? 'No messages yet';
    final timestamp = conversation['time'];
    final isOnline = conversation['online'] == 1 || conversation['online'] == '1';
    final unreadCount = conversation['unread_count'] ?? 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey[300],
            backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
            child: avatar.isEmpty
              ? Icon(Icons.person, color: Colors.grey[600], size: 28)
              : null,
          ),
          if (isOnline)
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              username,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            lastMessage,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _formatTimestamp(timestamp),
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
      onTap: () => _openConversation(conversation),
      trailing: PopupMenuButton(
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: Colors.red),
                SizedBox(width: 8),
                Text('Delete Chat'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'block',
            child: Row(
              children: [
                Icon(Icons.block, color: Colors.red),
                SizedBox(width: 8),
                Text('Block User'),
              ],
            ),
          ),
        ],
        onSelected: (value) {
          if (value == 'delete') {
            _deleteConversation(conversation);
          } else if (value == 'block') {
            _blockUser(conversation);
          }
        },
      ),
    );
  }

  Future<void> _deleteConversation(dynamic conversation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text('Are you sure you want to delete this conversation with ${conversation['username']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final url = Uri.parse('${SocialLoginService.baseUrl}/messages/delete_messages');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'access_token': UserDetails.accessToken,
            'to_userid': conversation['user_id'].toString(),
          },
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Conversation deleted')),
          );
          _fetchConversations(); // Refresh the list
        }
      } catch (e) {
        print('Error deleting conversation: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete conversation')),
        );
      }
    }
  }

  Future<void> _blockUser(dynamic conversation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text('Are you sure you want to block ${conversation['username']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final url = Uri.parse('${SocialLoginService.baseUrl}/users/block');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'access_token': UserDetails.accessToken,
            'user_id': conversation['user_id'].toString(),
          },
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${conversation['username']} has been blocked')),
          );
          _fetchConversations(); // Refresh the list
        }
      } catch (e) {
        print('Error blocking user: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to block user')),
        );
      }
    }
  }
}

