import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../utils/user_details.dart';
import 'first_screen.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'user_profile_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    firstRunExcite();
  }

  Future<void> firstRunExcite() async {
    await Future.delayed(const Duration(seconds: 1)); // splash delay

    // Load stored user from Hive
    var box = Hive.box('loginBox');
    var savedUser = box.get('currentUser');
    if (savedUser != null) {
      UserDetails.accessToken = savedUser['accessToken'] ?? '';
      UserDetails.userId = savedUser['userId'] ?? 0;
      UserDetails.username = savedUser['username'] ?? '';
      UserDetails.fullName = savedUser['fullName'] ?? '';
      UserDetails.email = savedUser['email'] ?? '';
      UserDetails.status = savedUser['status'] ?? '';
      UserDetails.avatar = savedUser['avatar'] ?? '';
      UserDetails.cover = savedUser['cover'] ?? '';
      UserDetails.deviceId = savedUser['deviceId'] ?? '';
    }

    // Navigate based on login status
    if (UserDetails.accessToken.isNotEmpty &&
        (UserDetails.status == 'Active' || UserDetails.status == 'Pending')) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FirstScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
