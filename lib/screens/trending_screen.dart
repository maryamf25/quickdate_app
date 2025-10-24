import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  late final PageController _pageController;
  final List<int> items = List<int>.generate(6, (i) => i);

  static const double horizontalPadding = 10;
  static const double maxCardWidth = 420;
  static const double cardAspect = 0.78;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
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
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(horizontalPadding, 10, horizontalPadding, 0),
            sliver: const SliverToBoxAdapter(child: StoriesBar()),
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
                  Text('See all', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 14)),
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
                  itemCount: items.length,
                  padEnds: true,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: maxCardWidth),
                        child: const _TrendingCard(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 20),
            sliver: const SliverToBoxAdapter(
              child: UserProfileCard(
                nameAndAge: 'Begovsky, 22',
                lastSeen: '2 hours ago',
                imageUrl: '',
                isOnline: true,
                showLikeAnimation: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StoriesBar extends StatelessWidget {
  final List<Map<String, String>> stories;
  const StoriesBar({
    super.key,
    this.stories = const [
      {'name': 'Your Story', 'image': ''},
      {'name': 'waelanjo', 'image': 'https://picsum.photos/200?1'},
      {'name': 'alex', 'image': 'https://picsum.photos/200?2'},
      {'name': 'sara', 'image': 'https://picsum.photos/200?3'},
      {'name': 'mike', 'image': 'https://picsum.photos/200?4'},
    ],
  });

  @override
  Widget build(BuildContext context) {
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
  const _TrendingCard({super.key});

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
                Image.asset(
                  'assets/imageplaceholder.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 48, color: Colors.white70),
                  ),
                ),
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
              children: const [
                Text(
                  'waelanjo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text('Los Angeles', style: TextStyle(fontSize: 14)),
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
                ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(color: Colors.grey[300]),
            )
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
            child: Text(
              lastSeen,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
          if (isOnline)
            const Positioned(
              right: 18,
              bottom: 18,
              child: _OnlineDot(),
            ),
          Positioned(
            right: 12,
            top: 12,
            child: GestureDetector(
              onTap: onLikePressed,
              child: const Icon(
                Icons.favorite_border,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          if (showLikeAnimation)
            Positioned(
              right: 8,
              top: 6,
              width: 66,
              height: 66,
              child: IgnorePointer(
                child: Lottie.asset(
                  'assets/LikeHeart.json',
                  fit: BoxFit.contain,
                  repeat: false,
                ),
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
