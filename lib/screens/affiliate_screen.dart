import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/user_details.dart'; // Make sure UserDetails.username is available

class MyAffiliatesScreen extends StatelessWidget {
  const MyAffiliatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Generate referral link using current username
    String referralLink =
        'https://quickdatescript.com/register?ref=${UserDetails.username}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Affiliates'),
        backgroundColor: const Color(0xFFBF01FD),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Text(
              'Earn up to \$ for each user you refer to us!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      referralLink,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Color(0xFFBF01FD)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: referralLink));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Referral link copied to clipboard!'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Share this link with your friends and earn rewards!',
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
