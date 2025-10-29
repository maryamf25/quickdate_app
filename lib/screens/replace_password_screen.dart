import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ReplacePasswordScreen extends StatefulWidget {
  final String email;

  const ReplacePasswordScreen({required this.email, super.key});

  @override
  State<ReplacePasswordScreen> createState() => _ReplacePasswordScreenState();
}

class _ReplacePasswordScreenState extends State<ReplacePasswordScreen> {
  final TextEditingController codeController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> _replacePassword() async {
    if (codeController.text.isEmpty) {
      _showDialog("Error", "Please enter the verification code.");
      return;
    }

    if (passwordController.text.isEmpty) {
      _showDialog("Error", "Please enter a new password.");
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("https://backend.staralign.me/endpoint/v1/models/users/replace_password"),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'email': widget.email,
          'email_code': codeController.text, // user-entered
          'password': passwordController.text,
        },
      );

      var data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['code'] == 200) {
        _showDialog("Success", "Password updated successfully.", onOk: () {
          Navigator.popUntil(context, (route) => route.isFirst); // back to login
        });
      } else {
        String message = data['message'] ?? data['errors']?['error_text'] ?? "Failed to update password";
        _showDialog("Error", message);
      }
    } catch (e) {
      _showDialog("Error", "Failed to connect: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showDialog(String title, String message, {VoidCallback? onOk}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (onOk != null) onOk();
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: "Verification Code",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "New Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : _replacePassword,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Update Password"),
            ),
          ],
        ),
      ),
    );
  }
}
