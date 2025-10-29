import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/user_details.dart';
import 'api_service.dart';

class UsersYouDislikedScreen extends StatefulWidget {
  const UsersYouDislikedScreen({super.key});

  @override
  State<UsersYouDislikedScreen> createState() => _UsersYouDislikedScreenState();
}

class _UsersYouDislikedScreenState extends State<UsersYouDislikedScreen> {
  late Future<List<User>> _dislikedUsersFuture;

  @override
  void initState() {
    super.initState();
    _dislikedUsersFuture = ApiService.fetchUsersYouDisliked();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users You Disliked'),
        backgroundColor: Colors.blueGrey, // Distinct color
      ),
      body: FutureBuilder<List<User>>(
        future: _dislikedUsersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error loading dislikes: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('You haven\'t disliked any users yet!'),
            );
          } else {
            final dislikedUsers = snapshot.data!;
            return ListView.builder(
              itemCount: dislikedUsers.length,
              itemBuilder: (context, index) {
                final user = dislikedUsers[index];
                return _buildDislikedUserTile(user);
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildDislikedUserTile(User user) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: CachedNetworkImageProvider(user.avatar),
        ),
        title: Text(
          user.fullName.isNotEmpty ? user.fullName : user.username,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          user.country.isNotEmpty ? user.country : 'Location Hidden',
          style: const TextStyle(color: Colors.grey),
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Viewing profile for ${user.fullName}')),
          );
        },
      ),
    );
  }
}
