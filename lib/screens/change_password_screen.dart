import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../Utils/user_details.dart'; // adjust path if needed

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  final darkPink = Colors.pink.shade700;

  // ⚙️ Replace with your backend API URLs
  final String loginUrl = "https://backend.staralign.me/endpoint/v1/models/login";
  final String changePasswordUrl = "https://backend.staralign.me/endpoint/v1/models/change_password";

  // ✅ Step 1: Verify current password by calling the login API (same logic as login screen)
  Future<bool> _verifyCurrentPassword() async {
    try {
      var response = await http.post(
        Uri.parse(loginUrl),
        body: {
          'username': UserDetails.username,
          'password': _currentPasswordController.text.trim(),
          'mobile_device_id': UserDetails.deviceId,
        },
      );

      print("Verify password response: ${response.body}");

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['code'] == 200 || data['status'] == "200") {
          // Login successful → password is correct
          return true;
        } else {
          _showMessage("Current password is incorrect!");
          return false;
        }
      } else {
        _showMessage("Error verifying password. Try again.");
        return false;
      }
    } catch (e) {
      _showMessage("Error: $e");
      return false;
    }
  }

  // ✅ Step 2: Change password after verification
  Future<void> _changePassword() async {
    String newPassword = _newPasswordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showMessage("Please fill in all fields!");
      return;
    }

    if (newPassword != confirmPassword) {
      _showMessage("New password and confirm password do not match!");
      return;
    }

    setState(() => _isLoading = true);

    bool verified = await _verifyCurrentPassword();
    if (!verified) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      var response = await http.post(
        Uri.parse(changePasswordUrl),
        body: {
          'access_token': UserDetails.accessToken,
          'user_id': UserDetails.userId.toString(),
          'new_password': newPassword,
        },
      );

      print("Change password response: ${response.body}");

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['code'] == 200 || data['status'] == "200") {
          UserDetails.password = newPassword;
          _showMessage("Password changed successfully!", success: true);
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        } else {
          _showMessage(data['message'] ?? "Failed to change password!");
        }
      } else {
        _showMessage("Server error: ${response.statusCode}");
      }
    } catch (e) {
      _showMessage("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ SnackBar helper
  void _showMessage(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: success ? darkPink : Colors.red.shade600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Password"),
        backgroundColor: darkPink,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              "Update Your Password",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darkPink,
              ),
            ),
            const SizedBox(height: 30),

            // 🔒 Current password
            TextField(
              controller: _currentPasswordController,
              obscureText: !_showCurrent,
              decoration: InputDecoration(
                labelText: "Current Password",
                labelStyle: TextStyle(color: darkPink),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showCurrent ? Icons.visibility : Icons.visibility_off,
                    color: darkPink,
                  ),
                  onPressed: () => setState(() => _showCurrent = !_showCurrent),
                ),
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: darkPink, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 🔒 New password
            TextField(
              controller: _newPasswordController,
              obscureText: !_showNew,
              decoration: InputDecoration(
                labelText: "New Password",
                labelStyle: TextStyle(color: darkPink),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showNew ? Icons.visibility : Icons.visibility_off,
                    color: darkPink,
                  ),
                  onPressed: () => setState(() => _showNew = !_showNew),
                ),
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: darkPink, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 🔒 Confirm password
            TextField(
              controller: _confirmPasswordController,
              obscureText: !_showConfirm,
              decoration: InputDecoration(
                labelText: "Confirm Password",
                labelStyle: TextStyle(color: darkPink),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showConfirm ? Icons.visibility : Icons.visibility_off,
                    color: darkPink,
                  ),
                  onPressed: () => setState(() => _showConfirm = !_showConfirm),
                ),
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: darkPink, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: darkPink,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                "Save Password",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
