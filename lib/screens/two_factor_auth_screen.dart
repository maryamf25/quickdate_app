import 'dart:convert'; // For json.encode and json.decode
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import http package
import '../utils/user_details.dart'; // Your user email
import 'social_login_service.dart';
import 'dart:convert'; // for utf8.encode
import 'package:crypto/crypto.dart'; // add crypto package in pubspec.yaml

class TwoFactorAuthScreen extends StatefulWidget {
  const TwoFactorAuthScreen({super.key});

  @override
  State<TwoFactorAuthScreen> createState() => _TwoFactorAuthScreenState();
}

class _TwoFactorAuthScreenState extends State<TwoFactorAuthScreen> {
  bool _isTwoFactorEnabled = false;
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  // --- API: Resend verification email (optional for registration) ---
  Future<bool> _resendVerificationEmail(String email) async {
    final url = Uri.parse('${SocialLoginService.baseUrl}/users/resend_email');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'email': email},
      );

      print('Resend email response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
            Text(data['message'] ?? 'Confirmation email sent successfully!'),
          ),
        );
        return true;
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        String message = errorData['message'] ?? 'Failed to send email';
        if (errorData['errors'] != null &&
            errorData['errors']['error_text'] != null) {
          message = errorData['errors']['error_text'];
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $message')));
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Network error: $e')));
      print('Network error resend email: $e');
      return false;
    }
  }

  // --- API: Verify 2FA code ---
  Future<void> _verifyTwoFactorCode(String code, BuildContext dialogContext) async {
    final url = Uri.parse('${SocialLoginService.baseUrl}/two_factor');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'user_id': UserDetails.userId.toString(),
          'code': code,
        },
      );

      print('2FA verify response: ${response.body}');

      final Map<String, dynamic> data = json.decode(response.body);

      if (response.statusCode == 200 && data['code'] == 200) {
        setState(() {
          _isTwoFactorEnabled = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Two-Factor Authentication Enabled')),
        );

        Navigator.pop(dialogContext); // Close OTP dialog
        _otpController.clear();
      } else {
        String errorMessage = data['message'] ?? 'Invalid confirmation code';
        if (data['errors'] != null && data['errors']['error_text'] != null) {
          errorMessage = data['errors']['error_text'];
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: Could not verify code. $e')),
      );
      print('Error verifying 2FA: $e');
    }
  }

  // --- OTP confirmation dialog ---
  void _showOtpConfirmationDialog(BuildContext context) {
    _otpController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'A confirmation code has been sent to ${UserDetails.email}.',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter 6-digit code',
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.pink),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _otpController.clear();
                      },
                      child: const Text(
                        'CANCEL',
                        style: TextStyle(
                          color: Colors.pink,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        String enteredOtp = _otpController.text.trim();
                        if (enteredOtp.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please enter the OTP')),
                          );
                          return;
                        }
                        _verifyTwoFactorCode(enteredOtp, dialogContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'SEND',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Two-factor options dialog ---
  void _showTwoFactorOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  title: const Text(
                    'Enable',
                    style: TextStyle(fontSize: 18, color: Colors.black),
                  ),
                  onTap: () async {
                    Navigator.pop(dialogContext);

                    if (!_isTwoFactorEnabled) {
                      // Send OTP email via your API, even the first time
                      bool emailSent = await _resendVerificationEmail(UserDetails.email);

                      if (emailSent && mounted) {
                        // Show OTP dialog after email is sent
                        Future.delayed(const Duration(milliseconds: 200), () {
                          _showOtpConfirmationDialog(context);
                        });
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Two-Factor Authentication is already Enabled')),
                      );
                    }
                  },
                ),

                ListTile(
                  title: const Text(
                    'Disable',
                    style: TextStyle(fontSize: 18, color: Colors.black),
                  ),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    if (_isTwoFactorEnabled) {
                      setState(() {
                        _isTwoFactorEnabled = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                            Text('Two-Factor Authentication Disabled')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                            Text('Two-Factor Authentication is already Disabled')),
                      );
                    }
                  },
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text(
                      'CLOSE',
                      style: TextStyle(
                        color: Colors.pink,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Two-factor authentication",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Two-factor authentication",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Turn on 2-step login to level-up your account's security. Once turned on, you'll use both your password and a 6-digit security code sent to your email to log in.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: () => _showTwoFactorOptionsDialog(context),
              child: Container(
                padding:
                const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: Colors.grey,
                      size: 24,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        _isTwoFactorEnabled ? "Enabled" : "Disabled",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Settings saved. 2FA is ${_isTwoFactorEnabled ? "Enabled" : "Disabled"}'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Save",
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
    );
  }
}
