import 'package:flutter/material.dart';

class VerificationScreen extends StatefulWidget {
  final int userId; final String email;
  const VerificationScreen({super.key, required this.userId, required this.email});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final TextEditingController codeController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Two-Factor Verification")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text("Enter the verification code sent to your email/phone."),
            const SizedBox(height: 20),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: "Verification Code",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : _verifyCode,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Verify"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyCode() async {
    // TODO: Call your /verify endpoint here with userId and code
    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // placeholder
    setState(() => isLoading = false);

    // Navigate to Home on success
    Navigator.pushReplacementNamed(context, '/home');
  }
}
