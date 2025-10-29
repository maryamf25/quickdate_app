import 'package:flutter/material.dart';
import '../utils/user_details.dart';
import 'profile_screen.dart';
import 'users_you_liked_screen.dart'; // New import
import 'users_you_disliked_screen.dart';
import 'friends_screen.dart';
import 'FavoritesScreen.dart';
import 'blogs_screen.dart';
import 'InviteFriendsScreen.dart';
class MainProfileScreen extends StatelessWidget {
  const MainProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String name = "${UserDetails.firstName} ${UserDetails.lastName}".trim();
    final String profilePic = UserDetails.avatar ?? '';
    final String city = UserDetails.city ?? '';
    final String country = UserDetails.country_txt ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile photo
            CircleAvatar(
              radius: 60,
              backgroundImage: profilePic.isNotEmpty
                  ? NetworkImage(profilePic)
                  : const AssetImage('assets/images/default_avatar.png')
              as ImageProvider,
            ),
            const SizedBox(height: 16),

            // Name
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

            // Edit Profile Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
            ),

            const SizedBox(height: 30),
            const Divider(thickness: 1),

            // Action Buttons
            const SizedBox(height: 10),
            _buildProfileActionButton(
              context,
              Icons.favorite,
              'Liked Users',
              Colors.redAccent,
              onPressedOverride: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UsersYouLikedScreen()),
                );
              },
            ),
            _buildProfileActionButton(
              context,
              Icons.people,
              'Friends',
              Colors.green,onPressedOverride: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FriendsScreen()),
                );},

            ),

            _buildProfileActionButton(
              context,
              Icons.thumb_down_alt_rounded,
              'Disliked Users',
              Colors.blueGrey,
              // Replace route with MaterialPageRoute
              onPressedOverride: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UsersYouDislikedScreen()),
                );
              },
            ),
            _buildProfileActionButton(
              context,
              Icons.person_add,
              'Invite Friends',
              Colors.purple,
              onPressedOverride: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InviteFriendsScreen(
                      profileLink: 'https://yourapp.com/profile/${UserDetails.userId}',
                    ),
                  ),
                );
              },
            ),

            _buildProfileActionButton(
              context,
              Icons.article,
              'Blogs',
              Colors.purple,
              onPressedOverride: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlogsScreen(accessToken: UserDetails.accessToken),
                  ),
                );
              },
            ),

            _buildProfileActionButton(
              context,
              Icons.star,
              'Favorites',
              Colors.orange,
    onPressedOverride: () {
    Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => FavoritesGridScreen(accessToken: UserDetails.accessToken,)),
    );},
            ),
            _buildProfileActionButton(
              context,
              Icons.history,
              'Match History',
              Colors.green,
              routeName: '/matchHistory', // keep for now
            ),
          ],
        ),
      ),
    );
  }

  // Updated to support optional override
  Widget _buildProfileActionButton(
      BuildContext context,
      IconData icon,
      String title,
      Color color, {
        String? routeName,
        VoidCallback? onPressedOverride,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: color.withOpacity(0.4)),
        ),
        onPressed: onPressedOverride ??
                () {
              if (routeName != null) {
                Navigator.pushNamed(context, routeName);
              }
            },
        icon: Icon(icon),
        label: Text(title, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
