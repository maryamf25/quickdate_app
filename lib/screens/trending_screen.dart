import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import '../utils/user_details.dart'; // for access_token
import 'random_user_profile_screen.dart'; // new screen
import 'social_login_service.dart';
class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  late final PageController _pageController;
  List<dynamic> _friends = [];
  bool _isLoading = true;

  static const double horizontalPadding = 10;
  static const double maxCardWidth = 420;
  static const double cardAspect = 0.78;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    final url = Uri.parse('${SocialLoginService.baseUrl}/users/random_users');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'access_token': UserDetails.accessToken ?? '',
          'offset': '0',
          'limit': '12',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _friends = data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching friends: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(horizontalPadding, 10, horizontalPadding, 0),
            sliver: SliverToBoxAdapter(
              child: StoriesBar(friends: _friends),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'HOT OR NOT',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  ),
                  Text(
                    'See all',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(horizontalPadding, 10, horizontalPadding, 0),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).size.width * cardAspect,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _friends.length,
                  padEnds: true,
                  itemBuilder: (context, index) {
                    final user = _friends[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: maxCardWidth),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RandomUserProfileScreen(user: user),
                              ),
                            );
                          },
                          child: _TrendingCard(
                            name: user['username'] ?? '',
                            country: user['country_txt'] ?? '',
                            imageUrl: user['avater'] ?? '',
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          if (_friends.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 20),
              sliver: SliverToBoxAdapter(
                child: UserProfileCard(
                  nameAndAge: _friends[0]['username'] ?? 'Unknown',
                  lastSeen: 'Recently active',
                  imageUrl: _friends[0]['avater'] ?? '',
                  isOnline: true,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class StoriesBar extends StatelessWidget {
  final List<dynamic> friends;
  const StoriesBar({super.key, required this.friends});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> stories = [
      {'name': 'Your Story', 'image': ''},
      ...friends.map((f) => {
        'name': f['username'] ?? '',
        'image': f['avater'] ?? '',
      }),
    ];

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: stories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = stories[index];
          final isAdd = index == 0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: StoryItem(
              name: item['name'] ?? '',
              imageUrl: item['image'] ?? '',
              isAdd: isAdd,
              onTap: !isAdd
                  ? () {
                final user = friends[index - 1];
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RandomUserProfileScreen(user: user),
                  ),
                );
              }
                  : null,
            ),
          );
        },
      ),
    );
  }
}

class StoryItem extends StatelessWidget {
  final String name;
  final String imageUrl;
  final bool isAdd;
  final VoidCallback? onTap;

  const StoryItem({
    super.key,
    required this.name,
    required this.imageUrl,
    this.isAdd = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 64;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Stack(
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isAdd
                      ? null
                      : const LinearGradient(
                    colors: [Colors.pink, Colors.orange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(3),
                child: CircleAvatar(
                  radius: (size - 6) / 2,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                  child: imageUrl.isEmpty
                      ? Icon(Icons.person, size: 32, color: Colors.grey[600])
                      : null,
                ),
              ),
              if (isAdd)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.add, size: 14, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: size + 6,
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _TrendingCard extends StatelessWidget {
  final String name;
  final String country;
  final String imageUrl;

  const _TrendingCard({
    super.key,
    required this.name,
    required this.country,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 48, color: Colors.white70),
                  ),
                )
                    : Image.asset('assets/imageplaceholder.jpg', fit: BoxFit.cover),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Row(
                    children: [
                      _circleButton(
                        icon: Icons.close,
                        color: Theme.of(context).colorScheme.primary,
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
                      _circleButton(
                        icon: Icons.local_fire_department,
                        color: Theme.of(context).colorScheme.secondary,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(country, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      shape: const CircleBorder(),
      color: color,
      elevation: 6,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 50,
          height: 50,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class UserProfileCard extends StatelessWidget {
  final String nameAndAge;
  final String lastSeen;
  final String imageUrl;
  final bool isOnline;
  final bool showLikeAnimation;
  final VoidCallback? onLikePressed;

  const UserProfileCard({
    super.key,
    required this.nameAndAge,
    this.lastSeen = '',
    this.imageUrl = '',
    this.isOnline = false,
    this.showLikeAnimation = false,
    this.onLikePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: imageUrl.isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.cover)
                : Container(color: Colors.grey[300]),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.45),
                    Colors.black.withOpacity(0.25)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: 12,
            right: 80,
            child: Text(
              nameAndAge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Text(lastSeen, style: const TextStyle(color: Colors.white, fontSize: 11)),
          ),
          if (isOnline)
            const Positioned(right: 18, bottom: 18, child: _OnlineDot()),
          Positioned(
            right: 12,
            top: 12,
            child: GestureDetector(
              onTap: onLikePressed,
              child: const Icon(Icons.favorite_border, color: Colors.white, size: 20),
            ),
          ),
          if (showLikeAnimation)
            Positioned(
              right: 8,
              top: 6,
              width: 66,
              height: 66,
              child: IgnorePointer(
                child: Lottie.asset('assets/LikeHeart.json', fit: BoxFit.contain, repeat: false),
              ),
            ),
        ],
      ),
    );
  }
}

class _OnlineDot extends StatelessWidget {
  const _OnlineDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF30DB3C), Color(0xFF1FA12A)],
        ),
        border: Border.all(color: Colors.white70, width: 1.5),
      ),
    );
  }
}
