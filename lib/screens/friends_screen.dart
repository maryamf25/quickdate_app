// lib/screens/friends_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/user_details.dart';
import 'api_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  late Future<List<User>> _friendsFuture;

  @override
  void initState() {
    super.initState();
    _friendsFuture = ApiService.fetchFriends();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        backgroundColor: Colors.green, // Distinct color
      ),
      body: FutureBuilder<List<User>>(
        future: _friendsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error loading friends: ${snapshot.error}', textAlign: TextAlign.center),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('You have no friends yet!'),
            );
          } else {
            final friends = snapshot.data!;
            return ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final user = friends[index];
                return _buildFriendTile(user);
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildFriendTile(User user) {
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
          // Navigate to the friend's profile if needed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Viewing profile for ${user.fullName}')),
          );
        },
      ),
    );
  }
}
