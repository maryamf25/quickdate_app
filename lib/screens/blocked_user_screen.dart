import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/user_details.dart';
import 'social_login_service.dart'; // your baseUrl file

// User model
class User {
  final int id;
  final String username;
  final String fullname;
  final String avatar;
  final String country;
  final String blockedOn;

  User({
    required this.id,
    required this.username,
    required this.fullname,
    this.avatar = '',
    this.country = '',
    required this.blockedOn,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.tryParse(json['id'].toString()) ?? 0,
      username: json['username'] ?? '',
      fullname: json['fullname'] ?? '',
      avatar: json['avater'] ?? '', // backend uses "avater"
      country: json['country_txt'] ?? '',
      blockedOn: json['blockedOn'] ?? '',
    );
  }
}

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<User> blockedUsers = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchBlockedUsers();
  }

  // Fetch blocked users
  Future<void> fetchBlockedUsers() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    final String accessToken = UserDetails.accessToken;
    final int userId = UserDetails.userId;
    final Uri url =
    Uri.parse('https://backend.staralign.me/endpoint/v1/models/users/profile');

    try {
      final response = await http.post(
        url,
        body: {
          'access_token': accessToken,
          'user_id': userId.toString(),
          'fetch': 'blocks',
        },
      );

      // Ignore PHP notices before JSON
      String body = response.body;
      int jsonStart = body.indexOf('{');
      if (jsonStart == -1) {
        setState(() {
          hasError = true;
          isLoading = false;
        });
        return;
      }
      body = body.substring(jsonStart);

      final data = jsonDecode(body);

      if (data['data'] != null && data['data']['blocks'] != null) {
        final List blocks = data['data']['blocks'];

        final List<User> loadedUsers = blocks.map((block) {
          final userData = block['data'] ?? {};
          userData['blockedOn'] = block['created_at'] ?? '';
          return User.fromJson(userData);
        }).toList();

        setState(() {
          blockedUsers = loadedUsers;
          isLoading = false;
        });
      } else {
        setState(() {
          blockedUsers = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
      print('Error fetching blocked users: $e');
    }
  }

  // Unblock user
  Future<void> unblockUser(int blockUserId) async {
    final String accessToken = UserDetails.accessToken;
    final Uri url = Uri.parse('https://backend.staralign.me/endpoint/v1/models/users/block');

    try {
      final response = await http.post(
        url,
        body: {
          'access_token': accessToken,
          'block_userid': blockUserId.toString(),
        },
      );

      final data = jsonDecode(response.body);

      if (data['code'] == 200) {
        // Remove user from blocked list in UI
        setState(() {
          blockedUsers.removeWhere((user) => user.id == blockUserId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'User unblocked successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['errors']?['error_text'] ?? 'Failed to unblock user.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error unblocking user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error unblocking user.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String formatBlockedDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day}-${date.month}-${date.year}";
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // The image shows a white background with black text and an arrow.
        // There's no background color for the AppBar itself, just a text.
        backgroundColor: Colors.white,
        elevation: 0, // Remove shadow
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          "Blocked Users",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold, // Adjust as per image
          ),
        ),
        centerTitle: false, // Align title to the left
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
          ? const Center(
        child: Text(
          'Failed to load blocked users.',
          style: TextStyle(color: Colors.red),
        ),
      )
          : blockedUsers.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon from the image
            const Icon(
              Icons.person, // Changed to a generic person icon as in the image
              size: 100, // Adjusted size to be larger
              color: Colors.pink, // The color from the image
            ),
            const SizedBox(height: 20),
            const Text(
              'There are no users', // Text directly from the image
              style: TextStyle(
                fontSize: 22, // Adjust font size
                fontWeight: FontWeight.normal, // Adjust font weight
                color: Colors.black, // Color from the image
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: blockedUsers.length,
        itemBuilder: (context, index) {
          final user = blockedUsers[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(
                user.avatar.isNotEmpty
                    ? user.avatar
                    : 'https://via.placeholder.com/150',
              ),
            ),
            title: Text(
                user.fullname.isNotEmpty ? user.fullname : user.username),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.country),
                Text(
                  'Blocked on: ${formatBlockedDate(user.blockedOn)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.block, color: Colors.red),
              onPressed: () => unblockUser(user.id),
            ),
          );
        },
      ),
    );
  }
}