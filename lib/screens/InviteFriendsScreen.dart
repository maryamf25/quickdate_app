import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class InviteFriendsScreen extends StatelessWidget {
  final String profileLink;

  const InviteFriendsScreen({super.key, required this.profileLink});

  // Opens a URL scheme (WhatsApp, Facebook, Instagram)
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.title_invite_friends)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.person_add, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Invite your friends to join!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Profile link display
            Text(
              profileLink,
              style: const TextStyle(color: Colors.blue, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Copy button
            ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: Text(AppLocalizations.of(context)!.copy_profile_link),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: profileLink));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.link_copied)),
                );
              },
            ),
            const SizedBox(height: 10),

            // Native share sheet
            ElevatedButton.icon(
              icon: const Icon(Icons.share),
              label: Text(AppLocalizations.of(context)!.share_link),
              onPressed: () {
                Share.share('Check out my profile: $profileLink');
              },
            ),

            const SizedBox(height: 20),
            const Text(
              'Share via social media',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 10),

            // Social media buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // WhatsApp
                IconButton(
                  icon: Image.asset('assets/images/whatsapp.png', width: 40),
                  onPressed: () {
                    final url =
                        'https://wa.me/?text=${Uri.encodeComponent("Check out my profile: $profileLink")}';
                    _launchUrl(url);
                  },
                ),
                // Facebook
                IconButton(
                  icon: Image.asset('assets/images/facebook.png', width: 40),
                  onPressed: () {
                    final url =
                        'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(profileLink)}';
                    _launchUrl(url);
                  },
                ),
                // Instagram (open app, copy link)
                IconButton(
                  icon: Image.asset('assets/images/instagram.png', width: 40),
                  onPressed: () {
                    // Instagram does not allow text sharing, so we copy link
                    Clipboard.setData(ClipboardData(text: profileLink));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Profile link copied! Paste it in Instagram.')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
