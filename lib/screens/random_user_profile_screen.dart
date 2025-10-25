import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/user_details.dart'; // Contains accessToken
import 'social_login_service.dart'; // Contains baseUrl

class RandomUserProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const RandomUserProfileScreen({super.key, required this.user});

  @override
  State<RandomUserProfileScreen> createState() => _RandomUserProfileScreenState();
}

class _RandomUserProfileScreenState extends State<RandomUserProfileScreen> {
  bool isFavorite = false;
  bool loadingFavorite = true;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    try {
      final url = Uri.parse('${SocialLoginService.baseUrl}/users/list_favorites');
      final response = await http.post(url,
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'access_token': UserDetails.accessToken, 'offset': '0', 'limit': '100'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List favorites = data['data'] ?? [];
        final favUserIds = favorites.map((e) => e['fav_user_id']).toList();
        setState(() {
          isFavorite = favUserIds.contains(widget.user['id']);
          loadingFavorite = false;
        });
      } else {
        setState(() {
          loadingFavorite = false;
        });
      }
    } catch (e) {
      setState(() {
        loadingFavorite = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    print("toglling favorite for user ID: ${widget.user['id']}");
    final uid = widget.user['id'];
    if (uid == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('User ID is missing!')));
      return;
    }

    // Immediately toggle state for optimistic UI update
    setState(() {
      isFavorite = !isFavorite;
    });

    final endpoint = isFavorite ? 'add_favorites' : 'remove_favorites'; // Endpoint depends on new state
    final url = Uri.parse('${SocialLoginService.baseUrl}/users/$endpoint');

    try {
      final response = await http.post(url,
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'access_token': UserDetails.accessToken, 'uid': uid.toString()});

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        if (res['success'] == 1) { // Assuming a success field in response
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(isFavorite
                  ? 'Added to favorites!'
                  : 'Removed from favorites!')));
        } else {
          // If API call failed, revert the optimistic UI update
          setState(() {
            isFavorite = !isFavorite;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(res['errors']?['error_text'] ?? 'Failed to update favorite status')));
        }
      } else {
        // If API call failed, revert the optimistic UI update
        setState(() {
          isFavorite = !isFavorite;
        });
        final res = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res['errors']?['error_text'] ?? 'Network error, please try again')));
      }
    } catch (e) {
      // If API call failed, revert the optimistic UI update
      setState(() {
        isFavorite = !isFavorite;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }


  @override
  Widget build(BuildContext context) {
    final String name = widget.user['username'] ?? 'Unknown';
    final String avatar = widget.user['avater'] ?? '';

    return Scaffold(
      extendBodyBehindAppBar: true,
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
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top avatar section
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
                      _buildActionButton(Icons.star_border, () {}, color: Colors.white),
                      const SizedBox(width: 20),
                      _buildActionButton(Icons.card_giftcard, () {}, color: Colors.white),
                      const SizedBox(width: 20),
                      _buildActionButton(Icons.person_add_alt, () {}, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: avatar.isNotEmpty
                          ? DecorationImage(image: NetworkImage(avatar), fit: BoxFit.cover)
                          : null,
                      color: avatar.isEmpty ? Colors.grey[200] : null,
                    ),
                    child: avatar.isEmpty
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
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
                    _buildBottomActionButton(Icons.chat, () {}),
                    const SizedBox(width: 30),
                    _buildBottomActionButton(Icons.close, () {}),
                    const SizedBox(width: 30),
                    loadingFavorite
                        ? const CircularProgressIndicator()
                        : _buildBottomActionButton(
                      isFavorite ? Icons.star : Icons.star_border,
                      _toggleFavorite,
                      isPink: true,
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

  Widget _buildActionButton(IconData icon, VoidCallback onPressed, {Color color = Colors.black}) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(icon: Icon(icon, color: color, size: 28), onPressed: onPressed),
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

  Widget _buildBottomActionButton(IconData icon, VoidCallback onPressed, {bool isPink = false}) {
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