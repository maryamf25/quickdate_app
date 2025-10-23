// api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/user_details.dart';

class ApiService {
  static const String baseUrl =
      'https://backend.staralign.me/endpoint/v1/models';

  static Future<Map<String, dynamic>> _makeApiCall(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      print('API Call: $endpoint');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['code'] == 200,
          'data': data['data'] ?? [],
          'message': data['message'] ?? '',
          'code': data['code'] ?? 400,
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
          'code': response.statusCode,
        };
      }
    } catch (e) {
      print('API Error: $e');
      return {'success': false, 'message': 'Connection error: $e', 'code': 400};
    }
  }

  // Get blocked users - This endpoint doesn't exist yet, so we'll skip it
  static Future<Map<String, dynamic>> getBlockedUsers() async {
    return {
      'success': true,
      'data': [],
      'message': 'No blocked users',
      'code': 200,
    };
  }

  // Block user - This endpoint doesn't exist yet
  static Future<Map<String, dynamic>> blockUser(
    String userId,
    String userName,
    String userEmail,
  ) async {
    return {
      'success': false,
      'message': 'Block user feature not available yet',
      'code': 400,
    };
  }

  // Unblock user - This endpoint doesn't exist yet
  static Future<Map<String, dynamic>> unblockUser(String blockedUserId) async {
    return {
      'success': false,
      'message': 'Unblock user feature not available yet',
      'code': 400,
    };
  }

  // Get affiliates/referrers - USING YOUR EXISTING ENDPOINT
  static Future<Map<String, dynamic>> getAffiliateData() async {
    return await _makeApiCall('users/get_referrers', {
      'user_id': UserDetails.userId.toString(),
      'access_token': UserDetails.accessToken,
    });
  }

  // Get payment data - This endpoint doesn't exist yet
  static Future<Map<String, dynamic>> getPaymentData() async {
    return {
      'success': true,
      'data': {'balance': 0.0, 'total_earned': 0.0, 'total_withdrawn': 0.0},
      'message': 'Payment system not implemented yet',
      'code': 200,
    };
  }

  // Get transactions - This endpoint doesn't exist yet
  static Future<Map<String, dynamic>> getTransactions() async {
    return {
      'success': true,
      'data': [],
      'message': 'Transactions not available yet',
      'code': 200,
    };
  }

  // Request withdrawal - This endpoint doesn't exist yet
  static Future<Map<String, dynamic>> requestWithdrawal(
    Map<String, dynamic> withdrawalData,
  ) async {
    return {
      'success': false,
      'message': 'Withdrawal system not implemented yet',
      'code': 400,
    };
  }

  // Update user profile - USING YOUR EXISTING REGISTER ENDPOINT
  static Future<Map<String, dynamic>> updateUserProfile(
    Map<String, dynamic> userData,
  ) async {
    return await _makeApiCall('users/register', {
      'user_id': UserDetails.userId.toString(),
      'access_token': UserDetails.accessToken,
      'username': userData['username'],
      'email': userData['email'],
      'country': userData['country'],
      'phone_number': userData['phone_number'],
    });
  }
}
