import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/user_details.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool currentVisible = false;
  bool newVisible = false;
  bool confirmVisible = false;
  bool isLoading = false;

  final Color darkPink = const Color(0xFFE91E63);

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Password"),
        backgroundColor: Colors.white,
        foregroundColor: darkPink,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildPasswordField(
                controller: currentPasswordController,
                label: "Current Password",
                visible: currentVisible,
                onToggle: () => setState(() => currentVisible = !currentVisible),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildPasswordField(
                controller: newPasswordController,
                label: "New Password",
                visible: newVisible,
                onToggle: () => setState(() => newVisible = !newVisible),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.trim().length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildPasswordField(
                controller: confirmPasswordController,
                label: "Confirm Password",
                visible: confirmVisible,
                onToggle: () => setState(() => confirmVisible = !confirmVisible),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value.trim() != newPasswordController.text.trim()) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkPink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: isLoading ? null : _changePassword,
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
                    "Change Password",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool visible,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: darkPink),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: darkPink),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: darkPink, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            visible ? Icons.visibility : Icons.visibility_off,
            color: darkPink,
          ),
          onPressed: onToggle,
        ),
      ),
      style: TextStyle(color: darkPink),
    );
  }

  // ✅ FIXED: access_token IN POST BODY, NOT URL
  Future<void> _changePassword() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final current = currentPasswordController.text.trim();
    final newPass = newPasswordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

    // Check if new passwords match
    if (newPass != confirm) {
      _showSnack("New passwords do not match");
      return;
    }

    // Check if current password is correct
    if (current != UserDetails.password) {
      _showSnack("Current password is incorrect");
      return;
    }

    // Check if new password is different from current
    if (newPass == current) {
      _showSnack("New password must be different from current password");
      return;
    }

    setState(() => isLoading = true);

    try {
      // ✅ NO access_token IN URL - IT GOES IN THE BODY!
      final url = Uri.parse(
          'https://backend.staralign.me/endpoint/v1/models/users/change_password'
      );

      // ✅ access_token MUST BE IN THE POST BODY
      Map<String, String> body = {
        'access_token': UserDetails.accessToken,  // ✅ IN BODY!
        'c_pass': current,
        'n_pass': newPass,
        'cn_pass': confirm,
      };

      print('🔐 Changing password...');
      print('📦 Body: $body');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      var data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['code'] == 200) {
        // ✅ SUCCESS - UPDATE LOCAL PASSWORD
        UserDetails.password = newPass;

        _showSnack("Password changed successfully");

        // Clear password fields
        currentPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();

        // Wait a bit for user to see the success message, then go back
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        // Handle error
        String message = "Failed to change password";

        if (data['message'] != null && data['message'].toString().isNotEmpty) {
          message = data['message'];
        } else if (data['errors'] != null) {
          if (data['errors'] is Map) {
            message = data['errors']['error_text'] ?? data['errors'].toString();
          } else if (data['errors'] is String) {
            message = data['errors'];
          }
        } else if (data['error'] != null) {
          message = data['error'];
        }

        _showSnack(message);
      }
    } catch (e) {
      print('❌ Exception: $e');
      _showSnack("Failed to connect to server. Please check your internet connection.");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // ✅ SNACKBAR WITH DYNAMIC COLOR
  void _showSnack(String message) {
    if (!mounted) return;

    final backgroundColor = message.toLowerCase().contains("success")
        ? Colors.green
        : darkPink;

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