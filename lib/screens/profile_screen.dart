import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../utils/user_details.dart';
import 'first_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadFromHive();
  }

  void _loadFromHive() {
    try {
      final box = Hive.box('loginBox');
      final user = box.get('currentUser');
      if (user != null && user is Map) {
        setState(() => _currentUser = Map<String, dynamic>.from(user));
        return;
      }
    } catch (_) {
      // ignore
    }

    setState(() {
      _currentUser = {
        'first_name': UserDetails.fullName,
        'email': UserDetails.email,
        'avatar': UserDetails.avatar,
        'user_id': UserDetails.userId,
        'username': UserDetails.username,
      };
    });
  }

  Future<void> _logout() async {
    final box = Hive.box('loginBox');
    await box.delete('currentUser');
    UserDetails.clearAll();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const FirstScreen()), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final name = _currentUser?['first_name'] ?? _currentUser?['name'] ?? 'Guest';
    final email = _currentUser?['email'] ?? '';
    final avatar = _currentUser?['avatar'] ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), actions: [
        IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
      ]),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(radius: 54, backgroundImage: avatar != null && (avatar as String).isNotEmpty ? NetworkImage(avatar) : null, child: (avatar == null || (avatar as String).isEmpty) ? const Icon(Icons.person, size: 48) : null),
            const SizedBox(height: 12),
            Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(email, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 18),
            ElevatedButton(onPressed: () {/* go to edit profile */}, child: const Text('Edit Profile')),
          ],
        ),
      ),
    );
  }
}
