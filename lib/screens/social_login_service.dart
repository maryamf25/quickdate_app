import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;
import '../utils/user_details.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/user_details.dart';

class SocialLoginService {
  static const String baseUrl = 'https://backend.staralign.me/endpoint/v1/models';


  static final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  //================ Google Sign In =================
  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;

      final auth = await account.authentication;
      final googleToken = auth.idToken ?? auth.accessToken;
      if (googleToken == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/users/social-login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'access_token': googleToken,
          'provider': 'google',
          'device_id': UserDetails.deviceId.isNotEmpty
              ? UserDetails.deviceId
              : "device_${DateTime.now().millisecondsSinceEpoch}",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) return data['data'];
      }
      return null;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return null;
    }
  }
  static Future<Map<String, dynamic>?> addLikesDislikes({
    required String accessToken,
    required String targetUserId,
    required bool isLike,
  }) async {
    try {
      // Build the body map step by step
      final Map<String, String> body = {'access_token': accessToken};

      if (isLike) {
        body['likes'] = targetUserId;
      } else {
        body['dislikes'] = targetUserId;
      }

      // Encode the body properly for x-www-form-urlencoded
      final encodedBody = body.entries
          .map((e) =>
      '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');

      debugPrint('📦 Request Body: $encodedBody');

      final response = await http.post(
        Uri.parse('$baseUrl/users/add_likes'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: encodedBody,
      );

      debugPrint('📩 AddLikesDislikes Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Success: ${data['message']}');
        return data;
      } else {
        debugPrint('❌ Failed [${response.statusCode}]: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('⚠️ AddLikesDislikes Exception: $e');
      return null;
    }
  }


  //================ Facebook Sign In =================
  static Future<Map<String, dynamic>?> signInWithFacebook() async {
    try {
      final result = await FacebookAuth.instance.login(permissions: ['email', 'public_profile']);
      if (result.status != LoginStatus.success) return null;

      final fbToken = result.accessToken!.tokenString;

      final response = await http.post(
        Uri.parse('$baseUrl/users/social-login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'access_token': fbToken,
          'provider': 'facebook',
          'device_id': UserDetails.deviceId.isNotEmpty
              ? UserDetails.deviceId
              : "device_${DateTime.now().millisecondsSinceEpoch}",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) return data['data'];
      }
      return null;
    } catch (e) {
      debugPrint('Facebook Sign-In error: $e');
      return null;
    }
  }
}
