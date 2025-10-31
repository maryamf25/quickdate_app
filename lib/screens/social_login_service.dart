import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;
import '../utils/user_details.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SocialLoginService {
  static const String baseUrl = 'https://backend.staralign.me/endpoint/v1/models';
  static String? accessToken;

  // Use the correct Web Client ID you provided — this is required on the web to obtain an idToken
  static const String? googleWebClientId =
      '716215768781-1riglii0rihhc9gmp53qad69tt8o2e03.apps.googleusercontent.com';


  static Future<String?> getAccessToken() async {
    try {
      // Try to get from Hive storage (support both box name variants)
      final boxNames = ['loginbox', 'loginBox'];
      for (final name in boxNames) {
        try {
          final box = await Hive.openBox(name);
          final token = box.get('access_token') ?? box.get('accessToken') ?? box.get('access_token'.toString());
          if (token != null) {
            accessToken = token.toString();
            debugPrint('🔑 Retrieved access token from box "${name}": ${accessToken!.length} chars');
            return accessToken;
          }
        } catch (e) {
          // ignore this box and try the next
        }
      }
    } catch (e) {
      debugPrint('❌ Error retrieving access token: $e');
    }
    return null;
  }

  static Future<void> saveAccessToken(String token) async {
    try {
      // Save to the canonical box name 'loginbox'
      final box = await Hive.openBox('loginbox');
      await box.put('access_token', token);
      // also keep legacy key and box for compatibility
      await box.put('accessToken', token);
      accessToken = token;
      debugPrint('✅ Access token saved successfully (loginbox)');
    } catch (e) {
      debugPrint('❌ Error saving access token: $e');
    }
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final box = await Hive.openBox('loginbox');
      // Store under 'user_data' and 'currentUser' for compatibility with existing code
      await box.put('user_data', userData);
      await box.put('currentUser', userData);
      debugPrint('✅ User data saved successfully');
    } catch (e) {
      debugPrint('❌ Error saving user data: $e');
    }
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final box = await Hive.openBox('loginbox');
      final userData = box.get('user_data');
      if (userData != null) {
        return Map<String, dynamic>.from(userData);
      }
    } catch (e) {
      debugPrint('❌ Error retrieving user data: $e');
    }
    return null;
  }

  // Lazily construct GoogleSignIn - on web we must supply clientId.
  static GoogleSignIn _createGoogleSignIn() {
    if (kIsWeb) {
      if (googleWebClientId == null || googleWebClientId!.isEmpty) {
        // If client id is not configured, throw a friendly error that is caught by caller.
        throw Exception(
            'Google Web clientId not set. Add a <meta name="google-signin-client_id" ...> to web/index.html or set SocialLoginService.googleWebClientId in code.');
      }
      // Provide clientId explicitly for web so the plugin can return an idToken
      return GoogleSignIn(clientId: googleWebClientId, scopes: ['email', 'profile']);
    } else {
      return GoogleSignIn(scopes: ['email', 'profile']);
    }
  }

  //================ Google Sign In =================
  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    GoogleSignIn? googleSignIn;

    try {
      googleSignIn = _createGoogleSignIn();

      // First try silent sign in (recommended on web/mobile)
      debugPrint('🔍 Trying silent Google sign-in...');
      final silentUser = await googleSignIn.signInSilently();
      if (silentUser != null) {
        debugPrint('✅ Silent sign-in successful: ${silentUser.email}');
        final auth = await silentUser.authentication;
        return _handleGoogleAuthentication(silentUser, auth);
      }

      debugPrint('🔐 Interactive Google sign-in...');
      final account = await googleSignIn.signIn();
      if (account == null) {
        debugPrint('❌ User canceled sign in');
        return null;
      }

      final auth = await account.authentication;
      return _handleGoogleAuthentication(account, auth);

    } catch (e, st) {
      debugPrint('❌ Google Sign-In error: $e');
      debugPrint(st.toString());
      // Try to handle specific errors
      if (e.toString().contains('PERMISSION_DENIED')) {
        debugPrint('⚠️ People API needs to be enabled in Google Cloud Console');
      }
      return null;
    } finally {
      // Clean up on error
      if (googleSignIn != null) {
        try {
          final currentUser = await googleSignIn.signInSilently();
          if (currentUser != null) {
            await googleSignIn.disconnect();
          }
        } catch (e) {
          // Ignore cleanup errors
        }
      }
    }
  }

  static Future<Map<String, dynamic>?> _handleGoogleAuthentication(
    GoogleSignInAccount account,
    GoogleSignInAuthentication auth,
  ) async {
    try {
      // Prefer idToken (signed JWT). If not present, fallback to accessToken.
      final googleToken = auth.idToken ?? auth.accessToken;
      if (googleToken == null) {
        debugPrint('❌ No valid token received from Google');
        return null;
      }

      // Debug: print token preview
      debugPrint('🔐 Google token received (${googleToken.length} chars)');

      // Backend expects the Google ID token in the field 'access_token' and provider 'google'
      final response = await http.post(
        Uri.parse('$baseUrl/users/social-login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'access_token': googleToken,
          'provider': 'google',
          'mobile_device_id': UserDetails.deviceId.isNotEmpty
              ? UserDetails.deviceId
              : "device_\u007f${DateTime.now().millisecondsSinceEpoch}",
          // Additional non-required fields (backend will primarily validate access_token & provider)
          'email': account.email,
          'first_name': (() {
            final displayName = account.displayName ?? '';
            final parts = displayName.split(' ');
            return parts.isNotEmpty ? parts.first : '';
          })(),
          'last_name': (() {
            final displayName = account.displayName ?? '';
            final parts = displayName.split(' ');
            return parts.length > 1 ? parts.sublist(1).join(' ') : '';
          })(),
          'avatar': account.photoUrl ?? '',
        },
      );

      debugPrint('📤 Social login response: ${response.statusCode}');
      debugPrint('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          // Store the access token returned by backend (session token)
          if (data['data']['access_token'] != null) {
            await saveAccessToken(data['data']['access_token'].toString());
          }
          // Store the user data
          await saveUserData(Map<String, dynamic>.from(data['data']));
          return Map<String, dynamic>.from(data['data']);
        }
      }
      return null;
    } catch (e, st) {
      debugPrint('❌ API error: $e');
      debugPrint(st.toString());
      return null;
    }
  }

  //================ Facebook Sign In =================
  static Future<Map<String, dynamic>?> signInWithFacebook() async {
    try {
      debugPrint('🔐 Starting Facebook sign-in...');

      if (kIsWeb) {
        return await _facebookWebLogin();
      } else {
        return await _facebookMobileLogin();
      }
    } catch (e, st) {
      debugPrint('❌ Facebook Sign-In error: $e');
      debugPrint('📋 Stack trace: $st');
      return null;
    }
  }

  // ---- Facebook Web Login (using JavaScript SDK) ----
  static Future<Map<String, dynamic>?> _facebookWebLogin() async {
    try {
      debugPrint('🌐 Starting web Facebook login via JS SDK...');

      // Check if FB SDK is ready
      final fbReady = _isFBSDKReady();
      if (!fbReady) {
        debugPrint('⏳ FB SDK not ready, waiting...');
        await Future.delayed(const Duration(seconds: 2));
      }

      // Use FB.login() via JavaScript
      final result = await _callFBLogin();

      if (result != null && result['access_token'] != null) {
        debugPrint('✅ FB login successful, token received');

        // Get user data
        final userData = await _getFBUserData(result['access_token']);
        if (userData != null) {
          debugPrint('👤 FB user data received: ${userData['name']}');
          return await _handleFacebookAuthentication(
            result['access_token'],
            userData,
          );
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Web Facebook login error: $e');
      return null;
    }
  }

  // ---- Facebook Mobile Login ----
  static Future<Map<String, dynamic>?> _facebookMobileLogin() async {
    try {
      debugPrint('📱 Starting mobile Facebook login...');

      // Initialize Facebook Auth for mobile
      debugPrint('🔄 Initializing Facebook SDK...');

      debugPrint('📱 Attempting Facebook login...');

      // Request Facebook login with email and public profile permissions
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      debugPrint('📝 Facebook login result status: ${result.status}');

      if (result.status == LoginStatus.success) {
        debugPrint('✅ Facebook login successful');

        // Get the access token
        final AccessToken accessToken = result.accessToken!;
        debugPrint('🔐 Facebook token received (${accessToken.token.length} chars)');

        // Get user data from Facebook
        final userData = await FacebookAuth.instance.getUserData(
          fields: "id,name,email,picture.width(200).height(200)",
        );

        debugPrint('👤 Facebook user data: ${userData.toString()}');

        return _handleFacebookAuthentication(accessToken.token, userData);

      } else if (result.status == LoginStatus.cancelled) {
        debugPrint('❌ Facebook login cancelled by user');
        return null;
      } else if (result.status == LoginStatus.failed) {
        debugPrint('❌ Facebook login failed: ${result.message}');
        debugPrint('💡 Troubleshooting:');
        debugPrint('   ✓ Check Facebook app configuration');
        debugPrint('   ✓ Verify Android signing key hash');
        debugPrint('   ✓ Check iOS app bundle ID');
        debugPrint('   ✓ Add test user in Facebook app settings');
        return null;
      }

      return null;
    } catch (e, st) {
      debugPrint('❌ Mobile Facebook login error: $e');
      debugPrint('📋 Stack trace: $st');

      String errorMessage = e.toString();
      if (errorMessage.contains('MissingPluginException')) {
        debugPrint('💡 Plugin not properly initialized. Run: flutter pub get');
      } else if (errorMessage.contains('PlatformException')) {
        debugPrint('💡 Platform-specific error - check native configuration');
      }

      return null;
    }
  }

  // ---- Helper: Check FB SDK ready ----
  static bool _isFBSDKReady() {
    try {
      if (kIsWeb) {
        // Try to access FB global via JavaScript interop
        return true; // Simplified check - assumes SDK loaded
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ---- Helper: Call FB.login() via JavaScript ----
  static Future<Map<String, dynamic>?> _callFBLogin() async {
    try {
      // This is a workaround using HTTP calls instead of native JS
      // For proper web implementation, you'd use dart:html and js interop

      debugPrint('📡 FB.login() via platform bridge...');

      // For web, we'll need to use a popup-based approach
      // The flutter_facebook_auth package should handle this on web
      final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        return {
          'access_token': result.accessToken?.token,
          'token_type': 'bearer',
        };
      }

      return null;
    } catch (e) {
      debugPrint('❌ FB.login() call failed: $e');
      return null;
    }
  }

  // ---- Helper: Get FB User Data ----
  static Future<Map<String, dynamic>?> _getFBUserData(
    String accessToken,
  ) async {
    try {
      final userData = await FacebookAuth.instance.getUserData(
        fields: "id,name,email,picture.width(200).height(200)",
      );
      return userData;
    } catch (e) {
      debugPrint('❌ Error fetching FB user data: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _handleFacebookAuthentication(
    dynamic accessTokenOrString,
    Map<String, dynamic> userData,
  ) async {
    try {
      // Handle both AccessToken object and string token
      String tokenString;
      if (accessTokenOrString is AccessToken) {
        tokenString = accessTokenOrString.token;
      } else {
        tokenString = accessTokenOrString.toString();
      }

      // Extract user information
      final String email = userData['email'] ?? '';
      final String name = userData['name'] ?? '';
      final String id = userData['id'] ?? '';
      final String avatarUrl = userData['picture']?['data']?['url'] ?? '';

      // Split name into first and last
      final nameParts = name.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      debugPrint('📤 Sending Facebook data to backend...');

      // Send to backend API
      final response = await http.post(
        Uri.parse('$baseUrl/users/social-login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'access_token': tokenString,
          'provider': 'facebook',
          'mobile_device_id': UserDetails.deviceId.isNotEmpty
              ? UserDetails.deviceId
              : "device_\u007f${DateTime.now().millisecondsSinceEpoch}",
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'avatar': avatarUrl,
          'facebook_id': id,
        },
      );

      debugPrint('📤 Facebook social login response: ${response.statusCode}');
      debugPrint('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          // Store the access token returned by backend (session token)
          if (data['data']['access_token'] != null) {
            await saveAccessToken(data['data']['access_token'].toString());
          }
          // Store the user data
          await saveUserData(Map<String, dynamic>.from(data['data']));
          return Map<String, dynamic>.from(data['data']);
        }
      }
      return null;
    } catch (e, st) {
      debugPrint('❌ Facebook API error: $e');
      debugPrint(st.toString());
      return null;
    }
  }

  //================ Sign Out =================
  static Future<void> signOut() async {
    try {
      // Sign out from Google
      final googleSignIn = _createGoogleSignIn();
      await googleSignIn.signOut();

      // Sign out from Facebook
      await FacebookAuth.instance.logOut();

      // Clear local storage
      final box = await Hive.openBox('loginbox');
      await box.clear();
      accessToken = null;

      debugPrint('✅ Successfully signed out from all providers');
    } catch (e) {
      debugPrint('❌ Error during sign out: $e');
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



  // ---------------- Transactions helper ----------------
  static Future<Map<String, dynamic>?> getTransactions({required int limit, required int offset}) async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        debugPrint('❌ No access token available for transactions');
        return null;
      }

      // Get current user ID
      final userBox = await Hive.openBox('loginbox');
      final userData = userBox.get('user_data');
      String userId = '0';
      if (userData != null && userData['id'] != null) {
        userId = userData['id'].toString();
      }

      final response = await http.post(
        Uri.parse('$baseUrl/users/profile'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'access_token': token,
          'user_id': userId,
          'fetch': 'payments',
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );

      if (response.statusCode == 200) {
        String responseBody = response.body;
        if (responseBody.contains('<')) {
          int jsonStart = responseBody.indexOf('{');
          if (jsonStart != -1) {
            responseBody = responseBody.substring(jsonStart);
            int jsonEnd = responseBody.lastIndexOf('}');
            if (jsonEnd != -1) responseBody = responseBody.substring(0, jsonEnd + 1);
          }
        }

        final data = jsonDecode(responseBody);
        if (data['code'] == 200 && data['data'] != null && data['data']['payments'] != null) {
          return {'code': 200, 'data': data['data']['payments'], 'message': 'Transactions fetched successfully'};
        } else {
          return {'code': 200, 'data': [], 'message': 'No transactions found'};
        }
      }

      debugPrint('❌ Transactions request failed with status: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching transactions: $e');
      return null;
    }
  }

  /// Refresh user's profile from server, save it locally if available.
  /// Returns true if profile was refreshed and saved, false otherwise.
  static Future<bool> refreshProfileIfAvailable() async {
    try {
      final token = await getAccessToken();
      if (token == null) return false;

      final userData = await getUserData();
      String userId = '0';
      if (userData != null && userData['id'] != null) {
        userId = userData['id'].toString();
      }

      if (userId == '0') return false;

      final response = await http.post(
        Uri.parse('$baseUrl/users/profile'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'access_token': token,
          'user_id': userId,
        },
      );

      if (response.statusCode != 200) return false;

      String responseBody = response.body;
      if (responseBody.contains('<')) {
        final int s = responseBody.indexOf('{');
        final int e = responseBody.lastIndexOf('}');
        if (s != -1 && e != -1 && e > s) responseBody = responseBody.substring(s, e + 1);
      }

      final data = jsonDecode(responseBody);
      // profile may be nested inside data or data.user_data
      dynamic profile = data['data'];
      if (profile is Map && profile.containsKey('user_data')) profile = profile['user_data'];

      if (profile is Map) {
        try {
          await saveUserData(Map<String, dynamic>.from(profile));
        } catch (_) {}

        // update UserDetails.isPro if provided
        try {
          final dynamic serverPro = profile['is_pro'] ?? profile['isPro'] ?? profile['pro'] ?? profile['pro_time'];
          if (serverPro != null) {
            if (serverPro is String) {
              UserDetails.isPro = (serverPro == '1' || serverPro.toLowerCase() == 'true') ? '1' : '0';
            } else if (serverPro is int) {
              UserDetails.isPro = serverPro == 1 ? '1' : '0';
            } else if (serverPro is bool) {
              UserDetails.isPro = serverPro ? '1' : '0';
            }
          }
        } catch (_) {}

        return true;
      }

      return false;
    } catch (e, st) {
      debugPrint('❌ refreshProfileIfAvailable error: $e');
      debugPrint(st.toString());
      return false;
    }
  }

}
