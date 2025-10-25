import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/user_details.dart';
import 'social_login_service.dart';

class ChatConversationScreen extends StatefulWidget {
  final dynamic conversation;
  final VoidCallback? onMessageSent;

  const ChatConversationScreen({
    super.key,
    required this.conversation,
    this.onMessageSent,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _messages = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();

    print('🟢 ===== ChatConversationScreen INITIALIZED =====');
    print('💬 Conversation data: ${widget.conversation}');
    print('💬 User ID: ${widget.conversation['user_id']}');
    print('💬 Username: ${widget.conversation['username']}');
    print('💬 Current user ID: ${UserDetails.userId}');
    print('💬 Access token length: ${UserDetails.accessToken.length}');
    print('🟢 ===== STARTING INITIALIZATION PROCESS =====');

    _testConnectivity();
    _fetchMessages();
    _markMessagesAsRead();
  }

  Future<void> _fetchMessages() async {
    print('💬 Fetching messages for conversation: ${widget.conversation['user_id']}');
    setState(() => _loading = true);

    try {
      // Use the correct endpoint from PHP backend: get_chat_conversations
      final url = Uri.parse('${SocialLoginService.baseUrl}/messages/get_chat_conversations');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'access_token': UserDetails.accessToken,
          'to_userid': widget.conversation['user_id'].toString(), // PHP expects 'to_userid'
          'limit': '50',
          'offset': '0',
        },
      );

      print('💬 Fetch messages response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('💬 Messages data: $data');

        if (data['code'] == 200 && data['data'] != null) {
          final List<dynamic> messagesList = List<dynamic>.from(data['data']);
          print('💬 Found ${messagesList.length} messages');

          setState(() {
            _messages = messagesList;
            _loading = false;
          });
          _scrollToBottom();
        } else {
          print('💬 No messages or error in response');
          setState(() {
            _messages = [];
            _loading = false;
          });
        }
      } else {
        print('❌ Failed to fetch messages: ${response.statusCode}');
        setState(() => _loading = false);
      }
    } catch (e) {
      print('💥 Error fetching messages: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _sendMessage() async {
    print('🚨 EMERGENCY LOG: _sendMessage called');

    final message = _messageController.text.trim();
    print('🚨 EMERGENCY LOG: Message text: "$message"');
    print('🚨 EMERGENCY LOG: Message empty: ${message.isEmpty}');
    print('🚨 EMERGENCY LOG: Already sending: $_sending');

    if (message.isEmpty || _sending) {
      print('🚨 EMERGENCY LOG: Exiting early - message empty or already sending');
      return;
    }

    print('📤 Starting to send message: "$message"');
    print('📤 Recipient ID: ${widget.conversation['user_id']}');
    print('📤 Access Token: ${UserDetails.accessToken.isNotEmpty ? "Available" : "Missing"}');
    print('📤 Access Token (first 10 chars): ${UserDetails.accessToken.substring(0, 10)}...');

    setState(() => _sending = true);

    try {
      // Use the correct endpoint from PHP backend: send_text_message
      final url = Uri.parse('${SocialLoginService.baseUrl}/messages/send_text_message');
      print('📤 Sending to URL: $url');

      // Use correct parameters matching PHP backend
      final requestBody = {
        'access_token': UserDetails.accessToken,
        'to_userid': widget.conversation['user_id'].toString(), // PHP expects 'to_userid'
        'message': message,
      };

      print('📤 Request body keys: ${requestBody.keys.toList()}');
      print('📤 Request body values: ${requestBody.values.map((v) => v.length > 20 ? '${v.substring(0, 20)}...' : v).toList()}');

      print('🚨 EMERGENCY LOG: About to make HTTP request');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: requestBody,
      );

      print('🚨 EMERGENCY LOG: HTTP request completed');
      print('📤 Response status: ${response.statusCode}');
      print('📤 Response body (first 200 chars): ${response.body.length > 200 ? response.body.substring(0, 200) + '...' : response.body}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          print('📤 Parsed response successfully');
          print('📤 Response structure: ${data.keys.toList()}');

          // Check for success based on PHP backend response structure
          bool isSuccess = data['status'] == 200;

          print('📤 Is success: $isSuccess');
          print('📤 Status field: ${data['status']}');

          if (isSuccess) {
            print('✅ Message sent successfully!');
            _messageController.clear();

            // Add message locally using the structure returned by PHP backend
            if (data['data'] != null) {
              print('✅ Adding message from server response');
              setState(() {
                _messages.add({
                  'id': data['data']['id'],
                  'from': data['data']['from'],
                  'to': data['data']['to'],
                  'text': data['data']['text'],
                  'media': data['data']['media'] ?? '',
                  'sticker': data['data']['sticker'] ?? '',
                  'seen': data['data']['seen'],
                  'created_at': data['data']['created_at'],
                  'message_type': data['data']['message_type'],
                  'type': 'sent', // This message is sent by current user
                });
              });
            } else {
              print('✅ Adding message manually (no server data)');
              // Fallback: create message object manually
              setState(() {
                _messages.add({
                  'from': int.parse(UserDetails.userId.toString()),
                  'to': widget.conversation['user_id'],
                  'text': message,
                  'media': '',
                  'sticker': '',
                  'seen': 0,
                  'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
                  'message_type': 'text',
                  'type': 'sent',
                });
              });
            }

            _scrollToBottom();

            // Refresh from server after a short delay
            Future.delayed(const Duration(milliseconds: 500), () {
              print('📤 Refreshing messages from server...');
              _fetchMessages();
            });

            if (widget.onMessageSent != null) {
              widget.onMessageSent!();
            }

            // Show success feedback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Message sent successfully!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 1),
              ),
            );
          } else {
            String errorMsg = data['message']?.toString() ??
                             data['errors']?['error_text']?.toString() ??
                             'Failed to send message';
            print('❌ Server error: $errorMsg');
            print('❌ Full error data: $data');

            // Check for specific error conditions from PHP backend
            if (data['blacklist'] == true) {
              _showError('Cannot send message: User has blocked you');
            } else if (data['mode'] == 'credits') {
              _showError('Please recharge your credits to send messages');
            } else {
              _showError(errorMsg);
            }
          }
        } catch (jsonError) {
          print('❌ JSON parsing error: $jsonError');
          print('❌ Raw response: ${response.body}');
          _showError('Invalid server response format');
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
        _showError('Server error ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Network error: $e');
      print('💥 Error type: ${e.runtimeType}');
      _showError('Network error: Check your connection');
    } finally {
      setState(() => _sending = false);
      print('📤 Send message operation completed');
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      // Based on PHP backend, the get_chat_conversations endpoint automatically marks messages as read
      // So we don't need a separate call, but we can add a dedicated one if needed
      final url = Uri.parse('${SocialLoginService.baseUrl}/messages/mark_all_messages_as_read');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'access_token': UserDetails.accessToken,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          print('💬 Messages marked as read successfully');
        }
      }
    } catch (e) {
      print('Error marking messages as read: $e');
      // Silently handle error - not critical for UX
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            if (_messageController.text.trim().isNotEmpty) {
              _sendMessage();
            }
          },
        ),
      ),
    );
  }

  Future<void> _testConnectivity() async {
    // Removed excessive logging - just test silently
    try {
      final url = Uri.parse('${SocialLoginService.baseUrl}/users/profile');
      await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'access_token': UserDetails.accessToken},
      );
    } catch (e) {
      // Silently handle connectivity issues
    }
  }

  // Simple direct API test
  Future<void> _testDirectAPI() async {
    print('🧪 Testing direct API call...');
    try {
      final url = Uri.parse('${SocialLoginService.baseUrl}/messages/send_text_message');
      print('🧪 URL: $url');
      print('🧪 Access Token: ${UserDetails.accessToken}');
      print('🧪 User ID: ${UserDetails.userId}');
      print('🧪 Recipient ID: ${widget.conversation['user_id']}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'access_token': UserDetails.accessToken,
          'to_userid': widget.conversation['user_id'].toString(),
          'message': 'Test direct API call',
        },
      );

      print('🧪 Direct API Response Status: ${response.statusCode}');
      print('🧪 Direct API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Direct API test: ${data['status'] == 200 ? 'SUCCESS' : 'FAILED'} - ${data['message'] ?? 'Check console'}'),
              backgroundColor: data['status'] == 200 ? Colors.green : Colors.orange,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Direct API test completed. Check console for details.'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
    } catch (e) {
      print('🧪 Direct API Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Direct API test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.conversation['username'] ?? 'Unknown User';
    final avatar = widget.conversation['avatar'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[300],
              backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
              child: avatar.isEmpty
                ? Icon(Icons.person, color: Colors.grey[600], size: 20)
                : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Online', // You can add online status logic here
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _testDirectAPI,
            tooltip: 'Test API',
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              // TODO: Implement video call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video call feature coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              // TODO: Implement voice call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice call feature coming soon')),
              );
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('View Profile'),
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
              if (value == 'profile') {
                // TODO: Navigate to user profile
              } else if (value == 'block') {
                _blockUser();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
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
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation by sending a message',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),

          // Test buttons for debugging
          Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  print('🧪 EMERGENCY TEST: Test message button pressed');
                  _messageController.text = 'Hello! This is a test message.';
                  _sendMessage();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Send Test Message'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  print('🧪 EMERGENCY TEST: Direct API test pressed');
                  _testDirectAPI();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Test API Connection'),
              ),
              const SizedBox(height: 8),
              Text(
                'User ID: ${widget.conversation['user_id']}\nAccess Token: ${UserDetails.accessToken.length} chars',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(dynamic message) {
    // Add null safety checks to prevent errors
    if (message == null) return const SizedBox.shrink();

    // Handle PHP backend message structure
    final currentUserId = int.parse(UserDetails.userId.toString());
    final messageFromId = message['from'] is int ? message['from'] : int.parse(message['from']?.toString() ?? '0');
    final isMe = messageFromId == currentUserId;

    final text = message['text']?.toString() ?? '';
    final media = message['media']?.toString() ?? '';
    final sticker = message['sticker']?.toString() ?? '';
    final messageType = message['message_type']?.toString() ?? 'text';
    final timestamp = _formatTimestamp(message['created_at']);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              backgroundImage: (widget.conversation['avatar']?.toString().isNotEmpty == true)
                ? NetworkImage(widget.conversation['avatar'])
                : null,
              child: (widget.conversation['avatar']?.toString().isEmpty != false)
                ? Icon(Icons.person, size: 16, color: Colors.grey[600])
                : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe
                  ? Theme.of(context).primaryColor
                  : Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display text message
                  if (messageType == 'text' && text.isNotEmpty)
                    Text(
                      text,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                    ),

                  // Display media message
                  if (messageType == 'media' && media.isNotEmpty)
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            media,
                            width: 200,
                            height: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 200,
                                height: 150,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image, size: 50),
                              );
                            },
                          ),
                        ),
                        if (text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            text,
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ],
                    ),

                  // Display sticker message
                  if (messageType == 'sticker' && sticker.isNotEmpty)
                    Image.network(
                      sticker,
                      width: 100,
                      height: 100,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[300],
                          child: const Icon(Icons.emoji_emotions, size: 50),
                        );
                      },
                    ),

                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timestamp,
                        style: TextStyle(
                          color: isMe ? Colors.white70 : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message['seen'] != null && message['seen'] != 0
                            ? Icons.done_all
                            : Icons.done,
                          size: 16,
                          color: message['seen'] != null && message['seen'] != 0
                            ? Colors.blue
                            : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              backgroundImage: UserDetails.avatar.isNotEmpty
                ? NetworkImage(UserDetails.avatar)
                : null,
              child: UserDetails.avatar.isEmpty
                ? Icon(Icons.person, size: 16, color: Colors.grey[600])
                : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: () {
                // TODO: Implement file attachment
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File attachment coming soon')),
                );
              },
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (text) {
                  print('🔘 TextField onSubmitted! Text: "$text"');
                  _sendMessage();
                },
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
                onPressed: _sending ? null : () {
                  print('🔘 Send button pressed! Message: "${_messageController.text}"');
                  _sendMessage();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _blockUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text('Are you sure you want to block ${widget.conversation['username']}?'),
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
            'user_id': widget.conversation['user_id'].toString(),
          },
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${widget.conversation['username']} has been blocked')),
          );
          Navigator.pop(context); // Go back to previous screen
        }
      } catch (e) {
        print('Error blocking user: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to block user')),
        );
      }
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      if (timestamp == null) return 'Unknown';

      DateTime dateTime;

      // Handle different timestamp formats from PHP backend
      if (timestamp is String) {
        // Try to parse as datetime string first (YYYY-MM-DD HH:MM:SS)
        try {
          dateTime = DateTime.parse(timestamp);
        } catch (e) {
          // If that fails, try to parse as timestamp string
          int time = int.parse(timestamp);
          if (time <= 0) return 'Unknown';
          // Check if it's in seconds or milliseconds
          if (time.toString().length <= 10) {
            // Seconds timestamp
            dateTime = DateTime.fromMillisecondsSinceEpoch(time * 1000);
          } else {
            // Milliseconds timestamp
            dateTime = DateTime.fromMillisecondsSinceEpoch(time);
          }
        }
      } else if (timestamp is int) {
        // Check if it's in seconds or milliseconds
        if (timestamp.toString().length <= 10) {
          // Seconds timestamp
          dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        } else {
          // Milliseconds timestamp
          dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        }
      } else {
        return 'Unknown';
      }

      // Format as HH:MM
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      print('Error formatting timestamp: $e for value: $timestamp');
      return 'Unknown';
    }
  }
}
