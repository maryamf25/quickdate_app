// api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/user_details.dart';
// Inside api_service.dart, after ApiService class

class InviteService {
  final ApiService _apiService;

  InviteService(this._apiService);

  // Expose the method from ApiService, or directly include it here
  Future<List<String>> getInvitationLinks() async {
    // You can also use the existing implementation from ApiService
    final url = Uri.parse('${ApiService.baseUrl}/invite/get_invitation_links');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'access_token': UserDetails.accessToken},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 200 && data['data'] != null) {
        // Extract only the codes
        List<String> codes =
        List<String>.from(data['data'].map((e) => e['code']));
        return codes;
      } else {
        throw Exception('No invitation codes found.');
      }
    } else {
      throw Exception('Failed to fetch invitation codes.');
    }
  }
}

// NOTE: The getInvitationLinks method in ApiService can now be removed to avoid duplication.
// If you want to keep it, you should make it static or remove the wrapping InviteService.
// I recommend removing the duplicate method from ApiService and using the one above.
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
  static Future<List<User>> fetchUsersYouDisliked() async {
    final response = await http.post(
      Uri.parse('https://backend.staralign.me/endpoint/v1/models/users/list_disliked'),
      body: {
        'access_token': UserDetails.accessToken!,
        'offset': '0',
        'limit': '12',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body)['data'] as List;
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load disliked users');
    }
  }
  static Future<List<User>> fetchFriends() async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/list_friends'),
      body: {
        'access_token': UserDetails.accessToken ?? '',
        'offset': '0',
        'limit': '12',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> usersJson = data['data'];
      return usersJson.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load friends');
    }
  }
  static Future<List<User>> fetchUsersYouLiked() async {
    final String accessToken = UserDetails.accessToken;
    if (accessToken.isEmpty) {
      throw Exception('Access token is missing.');
    }

    final body = {
      'access_token': accessToken,
      'limit': '20',
      'offset': '0',
    };

    try {
      final response = await http.post(
        // 🎯 KEY CHANGE: Use the correct endpoint for users *you* liked
        Uri.parse('$baseUrl/users/list_liked'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['status'] == 200 && data['data'] is List) {
          // The User.fromJson factory should handle this structure correctly
          return (data['data'] as List)
              .map((json) => User.fromJson(json))
              .toList();
        } else {
          final String errorText = data['errors']?['error_text'] ?? 'Unknown API error';
          throw Exception('Failed to load users you liked: $errorText');
        }
      } else {
        throw Exception('Server error: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('API Error (list_liked): $e');
      rethrow;
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

  static Future<Map<String, dynamic>> deleteLike({required int userId}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/delete_like'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'user_likeid': userId.toString(),
        'access_token': UserDetails.accessToken,
      },
    );

    return jsonDecode(response.body);
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

  /// Fetch list of users who visited the authenticated user's profile
  static Future<List<Map<String, dynamic>>> getProfileVisits({
    required String accessToken,
    int limit = 20,
    int offset = 0,
  }) async {
    final Uri url = Uri.parse('${ApiService.baseUrl}/users/list_visits');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'access_token': accessToken,
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['code'] == 200 && data['data'] != null) {
          final List<dynamic> visits = data['data'];
          return visits.map((e) => Map<String, dynamic>.from(e)).toList();
        } else {
          throw Exception('Unexpected API response: ${response.body}');
        }
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw Exception('Bad Request: ${error['errors']?['error_text'] ?? 'Unknown error'}');
      } else {
        throw Exception('Failed to fetch visits (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error fetching profile visits: $e');
    }
  }

  static Future<List<dynamic>> getLikedUsers() async {
    final url = Uri.parse('$baseUrl/users/get_liked_users');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'access_token': UserDetails.accessToken},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 200 && data['data'] != null) {
        return data['data'];
      } else {
        throw Exception('Failed to fetch liked users.');
      }
    } else {
      throw Exception('Failed to fetch liked users.');
    }
  }
}
