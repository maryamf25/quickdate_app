import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class UserProfileScreen extends StatelessWidget {
  final String username;

  const UserProfileScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.title_user_profile(username))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              child: Text(username[0].toUpperCase()),
            ),
            const SizedBox(height: 20),
            Text(
              username,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.back),
            ),
          ],
        ),
      ),
    );
  }
}
