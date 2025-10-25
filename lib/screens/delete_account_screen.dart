import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/user_details.dart';
import 'social_login_service.dart';
import 'LoginActivity.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool passwordVisible = false;
  bool isChecked = false;
  bool isLoading = false;

  final Color darkPink = const Color(0xFFE91E63);
  final Color purpleAccent = const Color(0xFFBF01FD);

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Delete Account"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.red,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning Icon
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      size: 60,
                      color: Colors.red,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Warning Title
                const Text(
                  "Delete Your Account",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),

                const SizedBox(height: 15),

                // Warning Message
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "⚠️ Warning",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Once you delete your account, there is no going back. This action cannot be undone and you will lose:",
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      Text("• All your profile information"),
                      Text("• All your matches and connections"),
                      Text("• All your messages and conversations"),
                      Text("• All your photos and media"),
                      Text("• Your premium membership (if any)"),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Password Field
                const Text(
                  "Enter Your Password",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: passwordController,
                  obscureText: !passwordVisible,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.trim() != UserDetails.password) {
                      return 'Incorrect password';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: "Enter your password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        passwordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => passwordVisible = !passwordVisible),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: darkPink, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Confirmation Checkbox
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isChecked ? purpleAccent : Colors.grey.withOpacity(0.3),
                      width: isChecked ? 2 : 1,
                    ),
                  ),
                  child: CheckboxListTile(
                    value: isChecked,
                    onChanged: (value) {
                      setState(() => isChecked = value ?? false);
                    },
                    activeColor: purpleAccent,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        children: [
                          const TextSpan(text: "Yes, I want to delete "),
                          TextSpan(
                            text: UserDetails.username,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFBF01FD),
                            ),
                          ),
                          const TextSpan(text: " permanently from QuickDate Account"),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Delete Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    onPressed: (isLoading || !isChecked) ? null : _deleteAccount,
                    child: isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text(
                      "Delete My Account",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if checkbox is checked
    if (!isChecked) {
      _showSnack("Please confirm that you want to delete your account", Colors.red);
      return;
    }

    // Show final confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Final Confirmation"),
        content: const Text(
          "This is your last chance! Are you absolutely sure you want to delete your account? This action is permanent and cannot be reversed.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Yes, Delete It"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${SocialLoginService.baseUrl}/users/delete_account'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'access_token': UserDetails.accessToken,
          'password': passwordController.text.trim(),
        },
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          // Clear all data
          UserDetails.clearAll();
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          final box = await Hive.openBox('loginBox');
          await box.clear();

          if (mounted) {
            _showSnack("Account deleted successfully", Colors.green);

            // Wait for snackbar to show
            await Future.delayed(const Duration(seconds: 2));

            // Navigate to login screen
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
              );
            }
          }
        } else {
          String message = data['message'] ??
              data['errors']?['error_text'] ??
              'Failed to delete account';
          _showSnack(message, Colors.red);
        }
      } else {
        _showSnack('Server error: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      print('❌ Exception: $e');
      _showSnack("Failed to connect to server. Please try again.", Colors.red);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showSnack(String message, Color backgroundColor) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}