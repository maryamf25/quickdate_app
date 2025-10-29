import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/user_details.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  List<dynamic> _notifications = [];
  int _newNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _loading = true);
    try {
      final response = await http.post(
        Uri.parse(
            'https://backend.staralign.me/endpoint/v1/models/users/get_notifications'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'access_token': UserDetails.accessToken},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _notifications = data['data'] ?? [];
          _newNotificationCount = data['new_notification_count'] ?? 0;
        });
      } else {
        debugPrint('Failed to fetch notifications: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
    setState(() => _loading = false);
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildNotificationItem(dynamic notification) {
    final notifier = notification['notifier'] ?? {};
    final avatarUrl = notifier['avater'] ?? '';
    final fullName = notifier['full_name'] ?? notifier['username'] ?? 'User';
    final text = notification['text'] ?? '';
    final seen = notification['seen'] != 0;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
        avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
        child: avatarUrl.isEmpty ? const Icon(Icons.person) : null,
      ),
      title: Text(fullName),
      subtitle: Text(text),
      trailing: Text(
        _formatTime(notification['created_at']),
        style: TextStyle(
            color: seen ? Colors.grey : Colors.blue,
            fontWeight: seen ? FontWeight.normal : FontWeight.bold),
      ),
      tileColor: seen ? null : Colors.blue.withOpacity(0.1),
      onTap: () {
        // Optional: navigate to notification.url
        debugPrint('Tapped notification: ${notification['url']}');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications (${_newNotificationCount})',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchNotifications,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? const Center(child: Text('No notifications yet'))
          : RefreshIndicator(
        onRefresh: _fetchNotifications,
        child: ListView.builder(
          itemCount: _notifications.length,
          itemBuilder: (context, index) {
            return _buildNotificationItem(_notifications[index]);
          },
        ),
      ),
    );
  }
}
