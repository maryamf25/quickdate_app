import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/user_details.dart';
import 'social_login_service.dart';
import 'chat_conversation_screen.dart';
import 'api_service.dart';

class RandomUserProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const RandomUserProfileScreen({super.key, required this.user});

  @override
  State<RandomUserProfileScreen> createState() =>
      _RandomUserProfileScreenState();
}

class _RandomUserProfileScreenState extends State<RandomUserProfileScreen> {
  bool isFavorite = false;
  bool isFriendAdded = false;
  bool isLiked = false;
  bool isLoading = true;
  bool isFavoriteLoading = false;
  bool isFriendLoading = false;
  bool isLikeLoading = false;
  bool isGiftLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeStates();
  }

  Future<void> _initializeStates() async {
    await Future.wait([
      _checkIfFavorite(),
      _checkIfFriend(),
      _checkIfLiked(),
      _incrementProfileVisit(),
    ]);
    setState(() => isLoading = false);
  }

  Future<void> _sendGift() async {
    setState(() {
      isGiftLoading = true;
    });

    final apiUrl = '${SocialLoginService.baseUrl}/users/send_gift';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'access_token': UserDetails.accessToken,
          'to_userid': widget.user['id'].toString(),
          'gift_id': '1', // Replace with dynamic gift id if needed
        },
      );

      final data = json.decode(response.body);
      if (data['code'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Gift sent successfully!'),
            backgroundColor: Colors.black,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['errors']?['error_text'] ?? 'Could not send gift',
            ),
            backgroundColor: Colors.pink,
          ),
        );
      }
    } catch (e) {
      print('Error sending gift: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error sending gift')));
    } finally {
      setState(() {
        isGiftLoading = false;
      });
    }
  }

  // Check if user is already a favorite
  Future<void> _checkIfFavorite() async {
    final apiUrl = '${SocialLoginService.baseUrl}/users/list_favorites';
    final accessToken = UserDetails.accessToken;

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'access_token': accessToken, 'offset': '0', 'limit': '100'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List favorites = data['data'] ?? [];
        print("Favorites: $favorites");
        final targetUserId = widget.user['id'];
        final exists = favorites.any(
          (user) => user.id.toString() == targetUserId.toString(),
        );
        setState(() {
          isFavorite = exists;
        });
        print('User ${widget.user['username']} fav status: $isFavorite');
      } else {
        print('Error fetching favorites: ${response.body}');
      }
    } catch (e) {
      print('Exception fetching favorites: $e');
    }
  }

  // Check if user is liked
  // Check if user is liked
  Future<void> _checkIfLiked() async {
    try {
      final likedUsers = await ApiService.fetchUsersYouLiked();
      final targetUserId = widget.user['id'];
      print('Target User ID: $targetUserId');
      print('Liked users IDs:');

      for (var user in likedUsers) {
        print(user.id);
      }
      final exists = likedUsers.any(
        (user) => user.id.toString() == targetUserId.toString(),
      );
      setState(() {
        isLiked = exists;
      });
      print('User ${widget.user['username']} liked status: $isLiked');
    } catch (e) {
      print('Error checking likes: $e');
    }
  }

  // Check if user is already a friend
  Future<void> _checkIfFriend() async {
    final apiUrl = '${SocialLoginService.baseUrl}/users/list_friends';
    final accessToken = UserDetails.accessToken;

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'access_token': accessToken, 'offset': '0', 'limit': '100'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List friends = data['data'] ?? [];
        final currentUserId = widget.user['id'];
        final exists = friends.any((friend) => friend['id'] == currentUserId);

        setState(() {
          isFriendAdded = exists;
        });
      } else {
        print('Error fetching friends: ${response.body}');
      }
    } catch (e) {
      print('Exception fetching friends: $e');
    }
  }

  // Toggle favorite
  Future<void> _toggleFavorite() async {
    setState(() {
      isFavoriteLoading = true;
    });

    final apiUrl =
        isFavorite
            ? '${SocialLoginService.baseUrl}/users/delete_favorites'
            : '${SocialLoginService.baseUrl}/users/add_favorites';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'access_token': UserDetails.accessToken,
          'uid': widget.user['id'].toString(),
        },
      );

      final data = json.decode(response.body);
      print(data['message'] ?? data['errors']?['error_text'] ?? 'Unknown');
      setState(() {
        isFavorite = !isFavorite; // toggle state only after API success
      });
      print(
        "Favorite status: $isFavorite widget user: ${widget.user['username'].toString()}",
      );

      _checkIfFavorite();
    } catch (e) {
      print('Exception toggling favorite: $e');
    } finally {
      setState(() {
        isFavoriteLoading = false;
      });
    }
  }

  // Toggle friend
  Future<void> _toggleFriend() async {
    setState(() {
      isFriendAdded = !isFriendAdded;
    });

    final apiUrl = '${SocialLoginService.baseUrl}/users/add_friend';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'access_token': UserDetails.accessToken,
          'uid': widget.user['id'].toString(),
        },
      );

      final data = json.decode(response.body);
      print(data['message'] ?? data['errors']?['error_text'] ?? 'Unknown');
    } catch (e) {
      print('Exception toggling friend: $e');
    }
  }

  Future<void> _incrementProfileVisit() async {
    final apiUrl = '${SocialLoginService.baseUrl}/users/profile';
    final requestBody = {
      'access_token': UserDetails.accessToken, // logged-in user
      'user_id': UserDetails.userId.toString(), // visitor
      'view_user_id': widget.user['id'].toString(), // profile owner
      'fetch': 'visits',
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: requestBody,
      );

      // Safely parse JSON ignoring PHP warnings
      String body = response.body;
      print('Raw response body: $body');
      int startIndex = body.indexOf('{');
      int endIndex = body.lastIndexOf('}');
      if (startIndex == -1 || endIndex == -1) {
        print('❌ No valid JSON found in response.');
        return;
      }

      String jsonString = body.substring(startIndex, endIndex + 1);
      final data = json.decode(jsonString);

      if (data['code'] == 200) {
        print('✅ Profile visit incremented: ${data['message']}');
      } else {
        print('❌ Failed to increment visit: ${data['message'] ?? response.body}');
      }
    } catch (e) {
      print('❌ Error incrementing profile visit: $e');
    }
  }




  // Toggle like
  Future<void> _toggleLike() async {
    setState(() {
      isLikeLoading = true;
    });

    final apiUrl =
        isLiked
            ? '${SocialLoginService.baseUrl}/users/delete_like'
            : '${SocialLoginService.baseUrl}/users/add_likes';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body:
            isLiked
                ? {
                  'access_token': UserDetails.accessToken,
                  'user_likeid': widget.user['id'].toString(),
                }
                : {
                  'access_token': UserDetails.accessToken,
                  'likes': widget.user['id'].toString(),
                },
      );

      final data = json.decode(response.body);
      print(data['message'] ?? data['errors']?['error_text'] ?? 'Unknown');

      setState(() {
        isLiked = !isLiked;
      });
    } catch (e) {
      print('Error toggling like: $e');
    } finally {
      setState(() {
        isLikeLoading = false;
      });
    }
  }

  void _startConversation() {
    print('🚀 _startConversation called for user: ${widget.user['username']}');
    print('🚀 User ID: ${widget.user['id']}');

    // Create a conversation object from user data
    final conversation = {
      'user_id': widget.user['id'],
      'username': widget.user['username'] ?? 'Unknown User',
      'avatar': widget.user['avater'] ?? widget.user['avatar'] ?? '',
      'conversation_id': null, // Will be created when first message is sent
      'text': '', // No last message yet
      'time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'seen': '1', // Mark as seen since we're starting the conversation
    };

    print('🚀 Navigation conversation data: $conversation');

    // Navigate to chat conversation screen
    Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) {
              print('🚀 Building ChatConversationScreen widget...');
              return ChatConversationScreen(
                conversation: conversation,
                onMessageSent: () {
                  print('Message sent to ${widget.user['username']}');
                },
              );
            },
          ),
        )
        .then((result) {
          print('🚀 Returned from ChatConversationScreen with result: $result');
        })
        .catchError((error) {
          print('🚀 Error navigating to ChatConversationScreen: $error');
        });
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.user['username'] ?? 'Unknown';
    final String avatar = widget.user['avater'] ?? '';

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section
            Container(
              height: 250,
              decoration:
                  avatar.isNotEmpty
                      ? BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(avatar),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withValues(alpha: 0.4),
                            BlendMode.darken,
                          ),
                        ),
                      )
                      : BoxDecoration(color: Colors.grey[300]),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionButton(
                        Icons.star,
                        _toggleFavorite,
                        color: isFavorite ? Colors.pink : Colors.white,
                      ),
                      const SizedBox(width: 20),
                      _buildActionButton(
                        Icons.card_giftcard,
                        _sendGift,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 20),
                      _buildActionButton(
                        Icons.person_add_alt,
                        _toggleFriend,
                        color: isFriendAdded ? Colors.green : Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.verified, color: Colors.green, size: 20),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.black),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image:
                          avatar.isNotEmpty
                              ? DecorationImage(
                                image: NetworkImage(avatar),
                                fit: BoxFit.cover,
                              )
                              : null,
                      color: avatar.isEmpty ? Colors.grey[200] : null,
                    ),
                    child:
                        avatar.isEmpty
                            ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey,
                            )
                            : null,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'More info',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '180 Cm tall, I have Brown hair,',
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Languages',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: [_buildLanguageChip('English')],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 80),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBottomActionButton(Icons.chat, () {
                      _startConversation();
                    }, isPink: true),
                    const SizedBox(width: 30),
                    _buildBottomActionButton(Icons.close, () {
                      Navigator.pop(
                        context,
                      ); // This will close the current screen
                    }),
                    const SizedBox(width: 30),
                    _buildBottomActionButton(
                      Icons.favorite,
                      _toggleLike,
                      isPink: isLiked,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    VoidCallback onPressed, {
    Color color = Colors.black,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 28),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildLanguageChip(String language) {
    return Chip(
      label: Text(language, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.pink,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildBottomActionButton(
    IconData icon,
    VoidCallback onPressed, {
    bool isPink = false,
  }) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: isPink ? Colors.pink : Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: isPink ? Colors.white : Colors.black, size: 35),
        onPressed: onPressed,
      ),
    );
  }
}

// Simple Chat Screen Implementation
class SimpleChatScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const SimpleChatScreen({super.key, required this.user});

  @override
  State<SimpleChatScreen> createState() => _SimpleChatScreenState();
}

class _SimpleChatScreenState extends State<SimpleChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _sending) return;

    setState(() => _sending = true);

    try {
      final url = Uri.parse(
        '${SocialLoginService.baseUrl}/messages/send_message',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'access_token': UserDetails.accessToken,
          'recipient_id': widget.user['id'].toString(),
          'message': message,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 200) {
          // Add message to local list
          setState(() {
            _messages.add({
              'text': message,
              'from_id': UserDetails.userId,
              'time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            });
          });

          _messageController.clear();
          _scrollToBottom();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Message sent successfully!')),
          );
        } else {
          _showError(
            'Failed to send message: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        _showError('Failed to send message');
      }
    } catch (e) {
      _showError('Failed to send message: $e');
    } finally {
      setState(() => _sending = false);
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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.user['username'] ?? 'Unknown User';
    final avatar = widget.user['avater'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[300],
              backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
              child:
                  avatar.isEmpty
                      ? Icon(Icons.person, color: Colors.grey[600], size: 20)
                      : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                username,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice call feature coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video call feature coming soon')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _messages.isEmpty
                    ? Center(
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
                            'Start the conversation with ${username}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isMe =
                            message['from_id'].toString() ==
                            UserDetails.userId.toString();
                        final text = message['text'] ?? '';
                        final time = DateTime.fromMillisecondsSinceEpoch(
                          message['time'] * 1000,
                        );

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment:
                                isMe
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                            children: [
                              if (!isMe) ...[
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.grey[300],
                                  backgroundImage:
                                      avatar.isNotEmpty
                                          ? NetworkImage(avatar)
                                          : null,
                                  child:
                                      avatar.isEmpty
                                          ? Icon(
                                            Icons.person,
                                            size: 16,
                                            color: Colors.grey[600],
                                          )
                                          : null,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isMe
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        text,
                                        style: TextStyle(
                                          color:
                                              isMe
                                                  ? Colors.white
                                                  : Colors.black87,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          color:
                                              isMe
                                                  ? Colors.white70
                                                  : Colors.grey[600],
                                          fontSize: 12,
                                        ),
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
                                  backgroundImage:
                                      UserDetails.avatar.isNotEmpty
                                          ? NetworkImage(UserDetails.avatar)
                                          : null,
                                  child:
                                      UserDetails.avatar.isEmpty
                                          ? Icon(
                                            Icons.person,
                                            size: 16,
                                            color: Colors.grey[600],
                                          )
                                          : null,
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
          ),
          Container(
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
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon:
                          _sending
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.send, color: Colors.white),
                      onPressed: _sending ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
