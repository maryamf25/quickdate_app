import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
    // First load cached friend request status for immediate UI feedback
    final cachedFriendStatus = await _loadFriendRequestStatus(widget.user['id'].toString());
    if (cachedFriendStatus != null) {
      setState(() {
        isFriendAdded = cachedFriendStatus;
      });
      print('💾 Using cached friend status: $cachedFriendStatus');
    }

    await Future.wait([
      _checkIfFavorite(),
      _checkIfLiked(),
      _incrementProfileVisit(),
      _checkFriendRequestStatus(), // Check friend request status on profile load
    ]);

    setState(() => isLoading = false);
  }

  @override
  Future<void> _checkFriendRequestStatus() async {
    print('🔍 Checking friend request status for user: ${widget.user['id']}');

    // Check if the user is already a friend
    await _checkIfFriend();
  }

  Future<void> _checkIfFriend() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = widget.user['id'].toString();
      final status = prefs.getBool('friend_request_status_$userId') ?? false;
      setState(() {
        isFriendAdded = status;
      });
      print('💾 Loaded friend request status: $userId -> $status');
    } catch (e) {
      print('Error checking friend status: $e');
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
        // Safely parse JSON ignoring PHP warnings
        String responseBody = response.body;
        int startIndex = responseBody.indexOf('{');
        int endIndex = responseBody.lastIndexOf('}');

        if (startIndex == -1 || endIndex == -1) {
          print('❌ No valid JSON found in favorites response.');
          return;
        }

        String jsonString = responseBody.substring(startIndex, endIndex + 1);
        final data = json.decode(jsonString);
        final List favorites = data['data'] ?? [];
        print("🌟 Favorites: $favorites");
        final targetUserId = widget.user['id'];
        final exists = favorites.any(
          (user) => (user['userData']?['id'] ?? user['id']).toString() == targetUserId.toString(),
        );
        setState(() {
          isFavorite = exists;
        });
        print('🌟 User ${widget.user['username']} fav status: $isFavorite');
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
      final targetUserId = widget.user['id'];
      final likedUsers = await ApiService.getLikedUsers();
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

  // Toggle friend with improved error handling and visual feedback
  Future<void> _toggleFriend() async {
    setState(() {
      isFriendLoading = true;
    });

    // Always use add_friend API - it should handle both adding and removing requests
    final apiUrl = '${SocialLoginService.baseUrl}/users/add_friend';

    print('👥 Toggle friend API URL: $apiUrl');
    print('👥 Current friend status: $isFriendAdded');
    print('👥 Target user ID: ${widget.user['id']}');

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'access_token': UserDetails.accessToken,
          'uid': widget.user['id'].toString(),
        },
      );

      print('👥 HTTP Status Code: ${response.statusCode}');
      print('👥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Safely parse JSON ignoring PHP warnings
        String responseBody = response.body;
        int startIndex = responseBody.indexOf('{');
        int endIndex = responseBody.lastIndexOf('}');

        if (startIndex == -1 || endIndex == -1) {
          print('👥 No valid JSON found in toggle friend response.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Invalid server response. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
            ),
          );
          return;
        }

        String jsonString = responseBody.substring(startIndex, endIndex + 1);
        final data = json.decode(jsonString);
        print('👥 Parsed JSON: $data');

        // Check for different possible success indicators - be more aggressive about success detection
        bool isSuccess = false;
        String? errorMessage;

        // Try different response formats - be more lenient with success detection
        if (data['code'] == 200 || data['status'] == 200) {
          isSuccess = true;
        } else if (data['api_status'] == 200) {
          isSuccess = true;
        } else if (data.containsKey('success') && data['success'] == true) {
          isSuccess = true;
        } else if (data.containsKey('message')) {
          final message = data['message'].toString().toLowerCase();
          if (message.contains('success') || message.contains('sent') || message.contains('added') || message.contains('request')) {
            isSuccess = true;
          }
        } else if (!data.containsKey('errors') && !data.containsKey('error')) {
          // If no explicit errors and we get any reasonable response, assume success
          isSuccess = true;
        }

        // Only consider it an error if there are explicit error messages
        if (data.containsKey('errors') && data['errors'] != null) {
          final errors = data['errors'];
          if (errors is Map && errors.containsKey('error_text') && errors['error_text'] != null && errors['error_text'] != '') {
            errorMessage = errors['error_text'];
            // Only fail if the error is meaningful
            if (!errorMessage!.toLowerCase().contains('already') && !errorMessage.toLowerCase().contains('exist')) {
              isSuccess = false;
            }
          } else if (errors is List && errors.isNotEmpty) {
            // If errors is a list, check if any error message is meaningful
            for (var error in errors) {
              if (error is String && error.isNotEmpty) {
                errorMessage = error;
                if (!errorMessage!.toLowerCase().contains('already') && !errorMessage.toLowerCase().contains('exist')) {
                  isSuccess = false;
                  break;
                }
              }
            }
          }
        } else if (data.containsKey('error') && data['error'] != null && data['error'] != '') {
          errorMessage = data['error'];
          // Only fail if the error is meaningful
          if (!errorMessage!.toLowerCase().contains('already') && !errorMessage.toLowerCase().contains('exist')) {
            isSuccess = false;
          }
        }

        print('👥 isSuccess: $isSuccess, errorMessage: $errorMessage');

        if (isSuccess) {
          // Update the state immediately for visual feedback
          setState(() {
            isFriendAdded = !isFriendAdded;
          });

          // Save to local cache for persistence
          await _saveFriendRequestStatus(widget.user['id'].toString(), isFriendAdded);

          print('👥 Friend status updated successfully: $isFriendAdded for user: ${widget.user['username']}');


          // Show success message with better styling
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isFriendAdded ? '👫 Friend request sent successfully' : '💔 Friend request cancelled',
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
          print('👥 API Error: $errorMessage');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${errorMessage ?? 'Failed to update friend request'}'),
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
        print('👥 HTTP Error: ${response.statusCode}');
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
      print('👥 Exception toggling friend: $e');
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

    print('❤️ Toggle like API URL: $apiUrl');
    print('❤️ Current like status: $isLiked');
    print('❤️ Target user ID: ${widget.user['id']}');

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

      print('❤️ HTTP Status Code: ${response.statusCode}');
      print('❤️ Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Safely parse JSON ignoring PHP warnings
        String responseBody = response.body;
        int startIndex = responseBody.indexOf('{');
        int endIndex = responseBody.lastIndexOf('}');

        if (startIndex == -1 || endIndex == -1) {
          print('❤️ No valid JSON found in toggle like response.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Invalid server response. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        String jsonString = responseBody.substring(startIndex, endIndex + 1);
        final data = json.decode(jsonString);
        print('❤️ Parsed JSON: $data');

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
          errorMessage = data['errors']?['error_text'] ?? 'Failed to update like';
        } else if (data.containsKey('error')) {
          errorMessage = data['error'];
        }

        if (isSuccess) {
          // Update the state immediately for visual feedback
          setState(() {
            isLiked = !isLiked;
          });

          print('❤️ Like status updated successfully: $isLiked for user: ${widget.user['username']}');

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isLiked ? '❤️ User liked' : '💔 Like removed',
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
          print('❤️ API Error: $errorMessage');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${errorMessage ?? 'Failed to update like'}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
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
        print('❤️ HTTP Error: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Network error (${response.statusCode}). Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('❤️ Exception toggling like: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ An error occurred: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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

  // Save friend request status locally
  Future<void> _saveFriendRequestStatus(String userId, bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('friend_request_status_$userId', status);
    print('💾 Saved friend request status locally: $userId -> $status');
  }

  // Load friend request status locally
  Future<bool?> _loadFriendRequestStatus(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final status = prefs.getBool('friend_request_status_$userId');
    print('💾 Loaded friend request status: $userId -> $status');
    return status;
  }

  // Ensure `_sendGift` placeholder is correctly referenced
  Future<void> _sendGift() async {
    print('🎁 Sending gift functionality is not implemented yet.');
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
                        isFriendAdded ? Icons.how_to_reg : Icons.person_add,
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
