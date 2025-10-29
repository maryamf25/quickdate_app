// lib/screens/users_you_liked_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'api_service.dart';
import '../utils/user_details.dart';

class UsersYouLikedScreen extends StatefulWidget {
  const UsersYouLikedScreen({super.key});

  @override
  State<UsersYouLikedScreen> createState() => _UsersYouLikedScreenState();
}

class _UsersYouLikedScreenState extends State<UsersYouLikedScreen> {
  late Future<List<User>> _likedUsersFuture;

  @override
  void initState() {
    super.initState();
    // 🎯 KEY CHANGE: Call the new API function
    _likedUsersFuture = ApiService.fetchUsersYouLiked();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users You Liked'),
        backgroundColor: Colors.pink, // Different color for distinction
      ),
      body: FutureBuilder<List<User>>(
        future: _likedUsersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error loading likes: ${snapshot.error}', textAlign: TextAlign.center),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('You haven\'t liked any users yet!'),
            );
          } else {
            final likedUsers = snapshot.data!;
            return ListView.builder(
              itemCount: likedUsers.length,
              itemBuilder: (context, index) {
                final user = likedUsers[index];
                return _buildLikedUserTile(context, user);
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildLikedUserTile(BuildContext context, User user) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: CachedNetworkImageProvider(user.avatar),
        ),
        title: Text(
          user.fullName.trim().isNotEmpty ? user.fullName : user.username,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          user.country.isNotEmpty ? user.country : 'Location Hidden',
          style: const TextStyle(color: Colors.grey),
        ),
        onTap: () {
          // TODO: Navigate to this user's full profile
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Viewing profile for ${user.fullName}')),
          );
        },
      ),
    );
  }
}