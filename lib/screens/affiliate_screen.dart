// affiliate_screen.dart
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'user_model.dart';

class MyAffiliatesScreen extends StatefulWidget {
  const MyAffiliatesScreen({super.key});

  @override
  State<MyAffiliatesScreen> createState() => _MyAffiliatesScreenState();
}

class _MyAffiliatesScreenState extends State<MyAffiliatesScreen> {
  List<ReferredUser> referredUsers = [];
  bool isLoading = true;
  String errorMessage = '';
  String referralCode =
      'REF${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

  @override
  void initState() {
    super.initState();
    _loadReferredUsers();
  }

  Future<void> _loadReferredUsers() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final response = await ApiService.getAffiliateData();

    if (response['success'] == true) {
      final data = response['data'];
      List<ReferredUser> users = [];

      if (data is List) {
        for (var userData in data) {
          users.add(ReferredUser.fromJson(userData));
        }
      }

      setState(() {
        referredUsers = users;
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = response['message'] ?? 'Failed to load referred users';
        isLoading = false;
      });
    }
  }

  void _copyReferralCode() {
    // Implement copy to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Referral code copied to clipboard!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Affiliates"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          "Earn \$10 on each referral",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.purple[800],
          ),
        ),
      ),
    );
  }
}
