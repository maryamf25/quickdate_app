import 'package:flutter/material.dart';

class ManageSessionsScreen extends StatelessWidget {
  const ManageSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Sessions")),
      body: const Center(
        child: Text(
            "View and terminate active sessions on other devices here."),
      ),
    );
  }
}
