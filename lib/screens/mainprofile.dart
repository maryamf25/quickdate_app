// main_profile_screen.dart (only relevant changes for context)
import 'package:flutter/material.dart';
import '../utils/user_details.dart';
import 'profile_screen.dart';
import 'users_you_liked_screen.dart';
import 'users_you_disliked_screen.dart';
import 'friends_screen.dart';
import 'FavoritesScreen.dart';
import 'blogs_screen.dart';
import 'InviteFriendsScreen.dart';
import 'home_screen.dart';
import 'upgrade_to_premium_screen.dart';
import '../services/razorpay_payment_service.dart';
import 'buy_credits.dart';
import 'profile_visits_screen.dart';

class MainProfileScreen extends StatefulWidget {
  const MainProfileScreen({super.key});

  @override
  State<MainProfileScreen> createState() => _MainProfileScreenState();
}

class _MainProfileScreenState extends State<MainProfileScreen> {
  late final RazorpayPaymentService _razorpayService;

  @override
  void initState() {
    super.initState();
    print('MainProfileScreen: Initializing RazorpayPaymentService.');
    _razorpayService = RazorpayPaymentService();
  }

  @override
  void dispose() {
    print('MainProfileScreen: Disposing RazorpayPaymentService.');
    _razorpayService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String name = "${UserDetails.firstName} ${UserDetails.lastName}".trim();
    final String profilePic = UserDetails.avatar ?? '';
    final String city = UserDetails.city ?? '';
    final String country = UserDetails.country_txt ?? '';

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            print('MainProfileScreen: Navigating to Credits Page.');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreditsApp(),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.yellow.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, color: Colors.orange, size: 14),
                  const SizedBox(height: 1),
                  Text(
                    UserDetails.balance.length > 4 ? '${UserDetails.balance.substring(0, 4)}+' : UserDetails.balance,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        title: const Text('My Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.diamond, color: Colors.blue),
            onPressed: () {
              print('MainProfileScreen: Navigating to PremiumUpgradePage.');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PremiumUpgradePage(
                    razorpayService: _razorpayService,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: profilePic.isNotEmpty
                  ? NetworkImage(profilePic)
                  : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
            ),
            const SizedBox(height: 16),
            Text(
              name.isNotEmpty ? name : 'Your Name',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              [city, country].where((e) => e.isNotEmpty).join(', '),
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: 150, // Adjust width as needed
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade50, // lighter pink background
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0, // optional, remove shadow
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    );
                  },
                  icon: const Icon(Icons.edit, color: Colors.pink), // pink icon
                  label: const Text(
                    'Edit Profile',
                    style: TextStyle(color: Colors.pink), // pink text
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
            // Likes / Visits / Share row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PremiumUpgradeApp()),
                    );
                  },
                  child: Row(
                    children: const [
                      Icon(Icons.favorite_border, color: Colors.black, size: 20),
                      SizedBox(width: 4),
                      Text(
                        'Likes', // replace with dynamic count
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileVisitsPage(accessToken: UserDetails.accessToken),
                      ),
                    );
                  },
                  child: Row(
                    children: const [
                      Icon(Icons.visibility, color: Colors.black, size: 20),
                      SizedBox(width: 4),
                      Text(
                        'Visits', // replace with dynamic count
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Implement share functionality
                  },
                  child: Row(
                    children: const [
                      Icon(Icons.share, color: Colors.black, size: 20),
                      SizedBox(width: 4),
                      Text(
                        'Share',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Horizontal row buttons (3 per row)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildProfileActionButtonRow(
                  context,
                  Icons.favorite,
                  'People I Liked',
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UsersYouLikedScreen()),
                    );
                  },
                ),
                _buildProfileActionButtonRow(
                  context,
                  Icons.people,
                  'Friends',
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FriendsScreen()),
                    );
                  },
                ),
                _buildProfileActionButtonRow(
                  context,
                  Icons.thumb_down_alt_rounded,
                  'Disliked Users',
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UsersYouDislikedScreen()),
                    );
                  },
                ),
                _buildProfileActionButtonRow(
                  context,
                  Icons.person_add,
                  'Invite Friends',
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InviteFriendsScreen(
                          profileLink: 'http://play.google.com/store/apps/details?id=com.quickdatesocial.android',
                        ),
                      ),
                    );
                  },
                ),
                _buildProfileActionButtonRow(
                  context,
                  Icons.article,
                  'Blogs',
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlogsScreen(accessToken: UserDetails.accessToken),
                      ),
                    );
                  },
                ),
                _buildProfileActionButtonRow(
                  context,
                  Icons.star,
                  'Favorites',
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FavoritesGridScreen(accessToken: UserDetails.accessToken),
                      ),
                    );
                  },
                ),
                _buildProfileActionButtonRow(
                  context,
                  Icons.settings,
                  'Settings',
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsTab()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

// New builder for horizontal button with pink rounded bg & white outline icon
  Widget _buildProfileActionButtonRow(
      BuildContext context,
      IconData icon,
      String title,
      VoidCallback onPressed,
      ) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 60) / 3, // 3 buttons per row with spacing
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink.shade50, // light pink background for the whole button
          padding: const EdgeInsets.symmetric(vertical: 30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: BorderSide.none, // no outline for the button itself
          ),
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.pink, // pink circle behind icon
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: Colors.white, // icon white inside circle
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }



}