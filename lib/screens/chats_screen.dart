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

  /// Attempts to extract the first JSON object or array from `raw`
  /// Strips leading HTML/PHP warnings that often start with "<"
  String? _extractJsonString(String raw) {
    raw = raw.trim();

    // Quick sanity: if it already starts with { or [, return full trimmed body
    if (raw.startsWith('{') || raw.startsWith('[')) {
      // But still try to cut off any trailing HTML after the JSON (rare)
      final match = RegExp(r'(\{[\s\S]*\}|\[[\s\S]*\])').firstMatch(raw);
      return match?.group(0) ?? raw;
    }

    // Find first '{' or '[' in the string
    final startIndex = raw.indexOf(RegExp(r'[\{\[]'));
    if (startIndex == -1) return null;

    // Take substring from the first bracket onwards
    String possible = raw.substring(startIndex);

    // Attempt to find the matching last bracket using regex match (robust)
    final match = RegExp(r'(\{[\s\S]*\}|\[[\s\S]*\])').firstMatch(possible);
    if (match != null) {
      return match.group(0);
    }

    // Fallback: try to locate last '}' or ']' and cut there
    final lastCurly = possible.lastIndexOf('}');
    final lastSquare = possible.lastIndexOf(']');
    final lastIndex = (lastCurly > lastSquare) ? lastCurly : lastSquare;
    if (lastIndex != -1) {
      return possible.substring(0, lastIndex + 1);
    }

    return null;
  }

  Future<void> _fetchConversations() async {
    print('📱 Fetching conversation list...');
    setState(() => _loading = true);

    try {
      final url = Uri.parse('${SocialLoginService.baseUrl}/messages/get_conversation_list');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        // NOTE: send form-encoded body as Map<String, String>
        body: {'access_token': UserDetails.accessToken ?? ''},
      );

      print('📱 Conversations response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        print('❌ HTTP error ${response.statusCode}');
        setState(() => _loading = false);
        return;
      }

      final rawBody = response.body ?? '';
      // Try quick parse first (good case)
      dynamic parsed;
      try {
        parsed = json.decode(rawBody);
      } catch (_) {
        // If that fails, try to extract JSON substring that ignores warnings/html
        final extracted = _extractJsonString(rawBody);
        if (extracted == null) {
          // No JSON found — log preview and bail out
          final preview = rawBody.length > 500 ? rawBody.substring(0, 500) + '...' : rawBody;
          print('💥 Failed to find JSON in response. Preview:\n$preview');
          setState(() => _loading = false);
          return;
        }

        try {
          parsed = json.decode(extracted);
        } catch (e) {
          // Still failing — log both the extracted snippet and error
          final snippet = extracted.length > 1000 ? extracted.substring(0, 1000) + '...' : extracted;
          print('💥 JSON parse failed on extracted snippet: $e\nSNIPPET:\n$snippet');
          setState(() => _loading = false);
          return;
        }
      }

      // At this point parsing succeeded
      print('📱 Parsed data keys: ${parsed is Map ? (parsed as Map).keys.toList() : 'non-map'}');

      if (parsed is Map && (parsed['code'] == 200 || parsed['code'] == '200')) {
        final List<dynamic> conversations = List<dynamic>.from(parsed['data'] ?? []);
        final List<dynamic> requests = List<dynamic>.from(parsed['requests'] ?? []);
        final int requestsCount = parsed['requests_count'] ?? 0;

        setState(() {
          _conversations = conversations;
          _requests = requests;
          _requestsCount = requestsCount;
          _loading = false;
        });

        print('✅ Loaded ${_conversations.length} conversations and ${_requests.length} requests');
      } else {
        // unexpected response shape
        print('❌ API returned unexpected payload: ${parsed}');
        setState(() {
          _conversations = [];
          _requests = [];
          _requestsCount = 0;
          _loading = false;
        });
      }
    } catch (e, st) {
      print('💥 Error fetching conversations: $e\n$st');
      setState(() => _loading = false);
    }
  }

  void _openConversation(Map<String, dynamic> rawConversation) {
    final userData = rawConversation['user'] ?? rawConversation['userData'] ?? {};

    final conversation = {
      'user_id': userData['id'] ?? rawConversation['user_id'],
      'username': userData['username'] ?? 'Unknown User',
      'avatar': userData['avater'] ?? userData['avatar'] ?? '',
      'conversation_id': rawConversation['conversation_id'] ?? rawConversation['id'],
      'text': rawConversation['text'] ?? '',
      'time': rawConversation['time'] ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'seen': rawConversation['seen']?.toString() ?? '1',
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatConversationScreen(conversation: conversation),
      ),
    );
  }


  String _formatTimestamp(dynamic timestamp) {
    try {
      if (timestamp == null) return '';
      // If server already returns human text like "about an hour ago" just return it.
      if (timestamp is String && (timestamp.contains('ago') || timestamp.contains('just'))) return timestamp;

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

      if (difference.inDays > 0) return '${difference.inDays}d ago';
      if (difference.inHours > 0) return '${difference.inHours}h ago';
      if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
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
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text('$_requestsCount', style: const TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.center),
                    ),
                  ),
              ],
            ),
            onPressed: () => _showRequestsDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchConversations,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty && _requests.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _fetchConversations,
        child: ListView(
          children: [
            if (_requests.isNotEmpty) ...[
              _buildSectionHeader('Chat Requests (${_requests.length})'),
              ..._requests.map((r) => _buildRequestTile(r)).toList(),
              const Divider(),
            ],
            if (_conversations.isNotEmpty) ...[
              _buildSectionHeader('Conversations'),
              ..._conversations.map((c) => _buildConversationTile(c)).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
        const SizedBox(height: 16),
        const Text('No conversations yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
        const SizedBox(height: 8),
        Text('Start chatting with people you match with', style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
          child: const Text('Discover People'),
        ),
      ]),
    );
  }

  Widget _buildConversationTile(dynamic conversation) {
    final user = conversation['user'] ?? conversation; // sometimes top-level has user fields
    final username = user['username'] ?? user['first_name'] ?? 'Unknown';
    final avatar = user['avater'] ?? user['avatar'] ?? '';
    final lastMessage = conversation['text'] ?? conversation['last_message'] ?? 'No messages yet';
    final timestamp = conversation['time'] ?? conversation['created_at'];
    final unreadCount = conversation['new_messages'] ?? conversation['unread_count'] ?? 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 26,
        backgroundImage: avatar != null && avatar.toString().isNotEmpty ? NetworkImage(avatar) : null,
        child: (avatar == null || avatar.toString().isEmpty) ? const Icon(Icons.person, size: 28) : null,
      ),
      title: Row(children: [
        Expanded(child: Text(username, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16), overflow: TextOverflow.ellipsis)),
        if (unreadCount != null && unreadCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(10)),
            child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
      ]),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 4),
        Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[700])),
        const SizedBox(height: 4),
        Text(_formatTimestamp(timestamp), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ]),
      onTap: () => _openConversation(conversation),
      trailing: PopupMenuButton(
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Delete Chat')])),
          const PopupMenuItem(value: 'block', child: Row(children: [Icon(Icons.block, color: Colors.red), SizedBox(width: 8), Text('Block User')])),
        ],
        onSelected: (value) {
          if (value == 'delete') _deleteConversation(conversation);
          if (value == 'block') _blockUser(conversation);
        },
      ),
    );
  }

  Widget _buildRequestTile(dynamic request) {
    final user = request['user'] ?? request;
    final username = user['username'] ?? user['first_name'] ?? 'Unknown';
    final avatar = user['avater'] ?? user['avatar'] ?? '';
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: avatar != null && avatar.toString().isNotEmpty ? NetworkImage(avatar) : null,
        child: (avatar == null || avatar.toString().isEmpty) ? const Icon(Icons.person) : null,
      ),
      title: Text(username),
      trailing: ElevatedButton(
        onPressed: () {
          // implement accept request API call here
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Accepted $username')));
        },
        child: const Text('Accept'),
      ),
      onTap: () => _openConversation(request),
    );
  }

  void _showRequestsDialog() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          children: [
            const Padding(padding: EdgeInsets.all(16.0), child: Text('Chat Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            if (_requests.isEmpty) const Padding(padding: EdgeInsets.all(16.0), child: Text('No new requests')),
            ..._requests.map((r) => _buildRequestTile(r)).toList(),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteConversation(dynamic conversation) async {
    try {
      final toUserId = (conversation['user']?['id'] ?? conversation['user_id'] ?? conversation['to_id'])?.toString();
      if (toUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to determine user id to delete')));
        return;
      }

      final url = Uri.parse('${SocialLoginService.baseUrl}/messages/delete_messages');
      final response = await http.post(url, headers: {'Content-Type': 'application/x-www-form-urlencoded'}, body: {
        'access_token': UserDetails.accessToken ?? '',
        'to_userid': toUserId,
      });

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conversation deleted')));
        _fetchConversations();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete conversation')));
      }
    } catch (e) {
      print('Error deleting conversation: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete conversation')));
    }
  }

  Future<void> _blockUser(dynamic conversation) async {
    try {
      final userId = (conversation['user']?['id'] ?? conversation['user_id'] ?? conversation['to_id'])?.toString();
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to determine user id to block')));
        return;
      }

      final url = Uri.parse('${SocialLoginService.baseUrl}/users/block');
      final response = await http.post(url, headers: {'Content-Type': 'application/x-www-form-urlencoded'}, body: {
        'access_token': UserDetails.accessToken ?? '',
        'user_id': userId,
      });

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User blocked')));
        _fetchConversations();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to block user')));
      }
    } catch (e) {
      print('Error blocking user: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to block user')));
    }
  }
}
