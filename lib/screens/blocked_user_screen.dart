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
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          "Blocked Users",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
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
            const Icon(
              Icons.person,
              size: 100,
              color: Colors.pink,
            ),
            const SizedBox(height: 20),
            const Text(
              'There are no users',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.normal,
                color: Colors.white,
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
            leading: const CircleAvatar( // Changed to a generic icon as in the image
              backgroundColor: Colors.grey, // Background for the person icon
              child: Icon(
                Icons.person,
                color: Colors.white,
              ),
            ),
            title: Text(
              user.fullname.isNotEmpty ? user.fullname : user.username,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500, // Adjusted font weight
              ),
            ),
            // Removed subtitle to match the image
            // subtitle: Column(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   children: [
            //     Text(user.country),
            //     Text(
            //       'Blocked on: ${formatBlockedDate(user.blockedOn)}',
            //       style: const TextStyle(fontSize: 12, color: Colors.grey),
            //     ),
            //   ],
            // ),
            trailing: TextButton( // Changed from IconButton to TextButton
              onPressed: () => unblockUser(user.id),
              style: TextButton.styleFrom(
                backgroundColor: Colors.pink.withOpacity(0.1), // Light pink background
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // Rounded corners
                ),
              ),
              child: const Text(
                'Unblock',
                style: TextStyle(
                  color: Colors.pink, // Pink text color
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}