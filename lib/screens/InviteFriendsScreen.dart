import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

class InviteFriendsScreen extends StatelessWidget {
  final String profileLink;

  const InviteFriendsScreen({super.key, required this.profileLink});

  @override
  Widget build(BuildContext context) {
    const String appStoreLink = 'http://play.google.com/store/apps/details?id=com.quickdatesocial.android';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite Friends'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            const Icon(Icons.favorite, size: 80, color: Colors.pink),
            const SizedBox(height: 20),
            const Text(
              'Share The Love',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Share the QuickDate by inviting your friends using these',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Copy Profile Link Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.link, color: Colors.pink),
                label: const Text(
                  'Copy Profile Link',
                  style: TextStyle(color: Colors.pink, fontSize: 16),
                ),
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: appStoreLink));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile link copied to clipboard!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 15),

            // Text Invite Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.message, color: Colors.pink),
                label: const Text(
                  'Text Invite',
                  style: TextStyle(color: Colors.pink, fontSize: 16),
                ),
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: appStoreLink));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Link copied! You can now paste it in your text message.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 15),

            // Social Media Invite Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.share, color: Colors.pink),
                label: const Text(
                  'Social Media Invite',
                  style: TextStyle(color: Colors.pink, fontSize: 16),
                ),
                onPressed: () {
                  Share.share(
                    'Hey! Check out QuickDate - the amazing dating app! Download it here: $appStoreLink',
                    subject: 'Join me on QuickDate!',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
