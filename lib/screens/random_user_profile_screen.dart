import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/user_details.dart';
import 'social_login_service.dart';
import 'chat_screen.dart';


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
    await Future.wait([_checkIfFavorite(), _checkIfFriend()]);
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
            content: Text(data['errors']?['error_text'] ?? 'Could not send gift'),
            backgroundColor: Colors.pink,
          ),
        );
      }

    } catch (e) {
      print('Error sending gift: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error sending gift')),
      );
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
        body: {
          'access_token': accessToken,
          'offset': '0',
          'limit': '100',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List favorites = data['data'] ?? [];
        final randomUserId = widget.user['id'];
        final exists = favorites.any((f) => f['userData']['id'] == randomUserId);
        setState(() {
          isFavorite = exists;
        });
      } else {
        print('Error fetching favorites: ${response.body}');
      }
    } catch (e) {
      print('Exception fetching favorites: $e');
    }
  }

  // Check if user is liked
  Future<void> _checkIfLiked() async {
    final apiUrl = '${SocialLoginService.baseUrl}/users/list_likes'; // Assuming list_likes endpoint
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'access_token': UserDetails.accessToken,
          'offset': '0',
          'limit': '100',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List likes = data['data'] ?? [];
        final currentUserId = widget.user['id'];
        final exists = likes.any((like) => like['id'] == currentUserId);
        setState(() {
          isLiked = exists;
        });
      }
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
        body: {
          'access_token': accessToken,
          'offset': '0',
          'limit': '100',
        },
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

    final apiUrl = isFavorite
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
      print("Favorite status: $isFavorite widget user: ${widget.user['username'].toString()}");

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

// Toggle like
  Future<void> _toggleLike() async {
    setState(() {
      isLikeLoading = true;
    });

    final userId = widget.user['id'];
    // debugPrint('🔹 User ID value: $userId');
    // debugPrint('🔹 User ID type: ${userId.runtimeType}');

    if (userId == null || userId.toString().isEmpty) {
      debugPrint("❌ Invalid user ID. Cannot proceed with like toggling.");
      setState(() => isLikeLoading = false);
      return;
    }

    final apiUrl = isLiked
        ? '${SocialLoginService.baseUrl}/users/delete_like'
        : '${SocialLoginService.baseUrl}/users/add_likes';

    final body = isLiked
        ? {
      'access_token': UserDetails.accessToken,
      'user_likeid': userId, // ensure string
    }
        : {
      'access_token': UserDetails.accessToken,
      'likes': userId.toString(), // ensure string
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        debugPrint('✅ Success: ${data['message']}');
        setState(() {
          isLiked = !isLiked;
        });
      } else {
        debugPrint('❌ Failed [${response.statusCode}]: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
    } finally {
      setState(() {
        isLikeLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final String name = widget.user['username'] ?? 'Unknown';
    final String avatar = widget.user['avater'] ?? '';

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
                    Colors.black.withOpacity(0.4),
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
                      _buildActionButton(Icons.star_border, _toggleFavorite,
                          color: isFavorite ? Colors.yellow : Colors.white),
                      const SizedBox(width: 20),
                      _buildActionButton(Icons.card_giftcard, _sendGift,
                          color: Colors.white),
                      const SizedBox(width: 20),
                      _buildActionButton(Icons.person_add_alt, _toggleFriend,
                          color: isFriendAdded ? Colors.green : Colors.white),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
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
                          image: NetworkImage(avatar), fit: BoxFit.cover)
                          : null,
                      color: avatar.isEmpty ? Colors.grey[200] : null,
                    ),
                    child: avatar.isEmpty
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
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
                    _buildBottomActionButton(
                      Icons.chat,
                          () {
                        // Navigate to the ChatScreen when the button is pressed
                        Navigator.push(
                          context, // Make sure 'context' is available in this scope
                          MaterialPageRoute(builder: (context) => const ChatScreen()),
                        );
                      },
                      isPink: isFavorite,
                    ),
                    const SizedBox(width: 30),
                    _buildBottomActionButton(Icons.close, () {
                      Navigator.pop(context); // This will close the current screen
                    }),                    const SizedBox(width: 30),
                    _buildBottomActionButton(Icons.favorite, _toggleLike,
                        isPink: isLiked),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onPressed,
      {Color color = Colors.black}) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
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

  Widget _buildBottomActionButton(IconData icon, VoidCallback onPressed,
      {bool isPink = false}) {
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
