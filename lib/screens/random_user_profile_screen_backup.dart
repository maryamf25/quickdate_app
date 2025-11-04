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
          (user) => (user['userData']?['id'] ?? user['id']).toString() == targetUserId.toString(),
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

  // Toggle favorite with improved error handling and visual feedback
  Future<void> _toggleFavorite() async {
    setState(() {
      isFavoriteLoading = true;
    });

    final apiUrl = isFavorite
        ? '${SocialLoginService.baseUrl}/users/delete_favorites'
        : '${SocialLoginService.baseUrl}/users/add_favorites';

    print('🌟 Toggle favorite API URL: $apiUrl');
    print('🌟 Current favorite status: $isFavorite');
    print('🌟 Target user ID: ${widget.user['id']}');

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'access_token': UserDetails.accessToken,
          'uid': widget.user['id'].toString(),
        },
      );

      print('🌟 HTTP Status Code: ${response.statusCode}');
      print('🌟 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🌟 Parsed JSON: $data');

        // Check for different possible success indicators
        bool isSuccess = false;
        String? errorMessage;

        // Try different response formats
        if (data['code'] == 200 || data['status'] == 200) {
          isSuccess = true;
        } else if (data['api_status'] == 200) {
          isSuccess = true;
        } else if (data.containsKey('success') && data['success'] == true) {
          isSuccess = true;
        } else if (!data.containsKey('errors') && !data.containsKey('error')) {
          // If no explicit errors, assume success
          isSuccess = true;
        }

        if (data.containsKey('errors')) {
          errorMessage = data['errors']?['error_text'] ?? 'Failed to update favorite';
        } else if (data.containsKey('error')) {
          errorMessage = data['error'];
        }

        if (isSuccess) {
          // Update the state immediately for visual feedback
          setState(() {
            isFavorite = !isFavorite;
          });

          print('🌟 Favorite status updated successfully: $isFavorite for user: ${widget.user['username']}');

          // Show success message with better styling
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isFavorite ? '⭐ Added to favorites' : '💔 Removed from favorites',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else {
          // API returned error
          print('🌟 API Error: $errorMessage');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${errorMessage ?? 'Failed to update favorite'}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        // HTTP error
        print('🌟 HTTP Error: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Network error (${response.statusCode}). Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('🌟 Exception toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ An error occurred: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() {
        isFavoriteLoading = false;
      });
    }
  }

  // Toggle friend with improved error handling
  Future<void> _toggleFriend() async {
    setState(() {
      isFriendLoading = true;
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

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data['message'] ?? data['errors']?['error_text'] ?? 'Unknown');

        // Only update state if API call was successful
        if (data['code'] == 200) {
          setState(() {
            isFriendAdded = !isFriendAdded;
          });
          print(
            "Friend status updated: $isFriendAdded for user: ${widget.user['username'].toString()}",
          );

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isFriendAdded ? 'Friend request sent' : 'Friend request cancelled',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          // API returned error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['errors']?['error_text'] ?? 'Failed to update friend request'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // HTTP error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Exception toggling friend: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        isFriendLoading = false;
      });
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

  // Toggle like with improved error handling
  Future<void> _toggleLike() async {
    setState(() {
      isLikeLoading = true;
    });

    final apiUrl = isLiked
        ? '${SocialLoginService.baseUrl}/users/delete_like'
        : '${SocialLoginService.baseUrl}/users/add_likes';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: isLiked
            ? {
                'access_token': UserDetails.accessToken,
                'user_likeid': widget.user['id'].toString(),
              }
            : {
                'access_token': UserDetails.accessToken,
                'likes': widget.user['id'].toString(),
              },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data['message'] ?? data['errors']?['error_text'] ?? 'Unknown');

        // Only update state if API call was successful
        if (data['code'] == 200) {
          setState(() {
            isLiked = !isLiked;
          });
          print(
            "Like status updated: $isLiked for user: ${widget.user['username'].toString()}",
          );

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isLiked ? 'User liked' : 'Like removed',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          // API returned error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['errors']?['error_text'] ?? 'Failed to update like'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // HTTP error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error toggling like: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
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
    final String avatar = widget.user['avater'] ?? widget.user['avatar'] ?? '';

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
              decoration: avatar.isNotEmpty
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
                        isFavorite ? Icons.star : Icons.star_border,
                        isFavoriteLoading ? () {} : _toggleFavorite,
                        color: isFavorite ? Colors.pink : Colors.white,
                        isLoading: isFavoriteLoading,
                      ),
                      const SizedBox(width: 20),
                      _buildActionButton(
                        Icons.card_giftcard,
                        isGiftLoading ? () {} : _sendGift,
                        color: Colors.white,
                        isLoading: isGiftLoading,
                      ),
                      const SizedBox(width: 20),
                      _buildActionButton(
                        isFriendAdded ? Icons.person_remove : Icons.person_add_alt,
                        isFriendLoading ? () {} : _toggleFriend,
                        color: isFriendAdded ? Colors.green : Colors.white,
                        isLoading: isFriendLoading,
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
                      image: avatar.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(avatar),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: avatar.isEmpty ? Colors.grey[200] : null,
                    ),
                    child: avatar.isEmpty
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
                      isLikeLoading ? () {} : _toggleLike,
                      isPink: isLiked,
                      isLoading: isLikeLoading,
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
    bool isLoading = false,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: isLoading
            ? Colors.white.withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.3),
        shape: BoxShape.circle,
        border: isLoading ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: isLoading
          ? const Padding(
              padding: EdgeInsets.all(10.0),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
              ),
            )
          : IconButton(
              icon: Icon(
                icon,
                color: color,
                size: 28,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              onPressed: onPressed,
              splashColor: Colors.white.withValues(alpha: 0.3),
              highlightColor: Colors.white.withValues(alpha: 0.1),
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
    bool isLoading = false,
  }) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: isPink ? Colors.pink : Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: isLoading
          ? Padding(
              padding: const EdgeInsets.all(15.0),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isPink ? Colors.white : Colors.black,
                ),
              ),
            )
          : IconButton(
              icon: Icon(icon, color: isPink ? Colors.white : Colors.black, size: 35),
              onPressed: onPressed,
            ),
    );
  }
}
