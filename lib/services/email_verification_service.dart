import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:quickdate_app/utils/user_details.dart';
import '../screens/social_login_service.dart';

class EmailVerificationService {
  final String baseUrl = SocialLoginService.baseUrl;

  // Send verification email
  Future<bool> sendVerificationEmail(String email) async {
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

        return true;
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        String message = errorData['message'] ?? 'Failed to send email';
        if (errorData['errors'] != null &&
            errorData['errors']['error_text'] != null) {
          message = errorData['errors']['error_text'];
        }

        return false;
      }
    } catch (e) {
      print('Network error resend email: $e');
      return false;
    }
  }

  // Verify email code
  // Future<bool> verifyEmailCode(String email, String code) async {
  //   try {
  //     print('code: ${code}');
  //     final url = Uri.parse('${SocialLoginService.baseUrl}/users/two_factor');
  //     final response = await http.post(
  //       url,
  //       headers: {'Content-Type': 'application/x-www-form-urlencoded'},
  //       body: {
  //         'user_id': UserDetails.userId.toString(),
  //         'code': code.trim(),
  //       },
  //     );
  //     print('verify email code response: ${response.body}');
  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       return data['success'] ?? false;
  //     }
  //     return false;
  //   } catch (e) {
  //     print('Error verifying code: $e');
  //     return false;
  //   }
  // }
  Future<bool> verifyEmailCode(String email, String code) async {
    try {
      print('UserDetails.emailCode: ${UserDetails.emailCode}');
      print('Entered code: $code');

      // Compare directly
      if (code.trim() == UserDetails.emailCode.toString().trim()) {
        print('✅ Code matched successfully');
        return true;
      } else {
        print('❌ Invalid code entered');
        return false;
      }
    } catch (e) {
      print('Error verifying code: $e');
      return false;
    }
  }

}