import 'dart:convert';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'replace_password_screen.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  Future<void> _sendEmailCode() async {
    String email = emailController.text.trim();
    if (email.isEmpty) {
      _showDialog("Error", "Please enter your email.");
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("https://backend.staralign.me/endpoint/v1/models/users/reset_password"),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'email': email,
          'src': 'app', // optional
        },
      );

      var data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['code'] == 200) {
        // Move to ReplacePasswordScreen, user enters the code from email
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReplacePasswordScreen(email: email),
          ),
        );
      } else {
        String message = data['message'] ?? data['errors']?['error_text'] ?? "Failed to send code";
        _showDialog("Error", message);
      }
    } catch (e) {
      _showDialog("Error", "Failed to connect: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.common_ok))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.title_forgot_password)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : _sendEmailCode,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(AppLocalizations.of(context)!.send_verification_code),
            ),
          ],
        ),
      ),
    );
  }
}
