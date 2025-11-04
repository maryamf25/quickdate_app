import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'social_login_service.dart';
import '../utils/app_settings.dart';
import '../utils/user_details.dart';
import 'home_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  List<dynamic> _allNotifications = [];
  List<dynamic> _filteredNotifications = [];
  int _newNotificationCount = 0;
  late TabController _tabController;
  int _currentTabIndex = 0;
  final List<String> _tabs = ['Matches', 'Visits', 'Likes', 'Requests'];
  // pagination basics (server expects offset as last seen id, "id > offset")
  final int _limit = 30;
  int _offset = 0; // last id fetched; for initial request keep 0

  // Premium gating
  bool _isPremiumUser = false;
  bool _checkedPremium = false; // whether we've checked premium status
  // Track request IDs currently being processed to prevent duplicate accepts
  final Set<String> _processingRequests = <String>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      // Update current index whenever the controller's index differs from
      // our tracked index. Using indexIsChanging alone can miss some
      // changes on certain platforms (web), so compare directly.
      if (_tabController.index != _currentTabIndex) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
        _filterNotifications();
      }
    });
    _checkPremiumAndInit();
  }

  Future<void> _checkPremiumAndInit() async {
    // If the app does not require premium for notifications, allow access
    if (!AppSettings.premiumSystemEnabled) {
      setState(() {
        _isPremiumUser = true;
        _checkedPremium = true;
      });
      await _fetchNotifications();
      return;
    }

    try {
      // Try to read saved user data first (from Hive via SocialLoginService helper)
      final userData = await SocialLoginService.getUserData();
      bool isPro = false;

      if (userData != null) {
        final dynamic raw = userData['is_pro'] ?? userData['isPro'] ?? userData['pro'] ?? userData['pro_time'];
        if (raw != null) {
          // Accept multiple possible representations
          if (raw is String) {
            isPro = raw == '1' || raw.toLowerCase() == 'true';
          } else if (raw is int) {
            isPro = raw == 1;
          } else if (raw is bool) {
            isPro = raw;
          }
        }
      }

      // Fallback: also check UserDetails static if available
      if (!isPro && UserDetails.isPro.isNotEmpty) {
        final u = UserDetails.isPro;
        isPro = (u == '1' || u.toLowerCase() == 'true');
      }

      // Attempt server-side refresh to verify premium status (more authoritative)
      try {
        final String? token = await SocialLoginService.getAccessToken();
        String? userId;
        if (userData != null && userData['id'] != null) {
          userId = userData['id'].toString();
        }

        if (token != null && userId != null) {
          final resp = await http.post(
            Uri.parse('${SocialLoginService.baseUrl}/users/profile'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'access_token': token,
              'user_id': userId,
            },
          );

          if (resp.statusCode == 200) {
            String raw = resp.body;
            if (raw.contains('<')) {
              final s = raw.indexOf('{');
              final e = raw.lastIndexOf('}');
              if (s != -1 && e != -1 && e > s) raw = raw.substring(s, e + 1);
            }

            final Map<String, dynamic> json = jsonDecode(raw);
            // profile endpoint may wrap user inside data or data.user_data
            dynamic profile = json['data'];
            if (profile is Map && profile.containsKey('user_data')) {
              profile = profile['user_data'];
            }

            if (profile is Map) {
              // Update local storage with fresh user data if it looks valid
              try {
                await SocialLoginService.saveUserData(Map<String, dynamic>.from(profile));
              } catch (_) {}

              // Look for pro flag in server response
              final dynamic serverPro = profile['is_pro'] ?? profile['isPro'] ?? profile['pro'] ?? profile['pro_time'];
              if (serverPro != null) {
                if (serverPro is String) {
                  isPro = serverPro == '1' || serverPro.toLowerCase() == 'true';
                } else if (serverPro is int) {
                  isPro = serverPro == 1;
                } else if (serverPro is bool) {
                  isPro = serverPro;
                }

                // Also keep UserDetails in sync where possible
                try {
                  UserDetails.isPro = isPro ? '1' : '0';
                } catch (_) {}
              }
            }
          }
        }
      } catch (e) {
        // Silently ignore server refresh failures; we'll rely on local info
      }

      setState(() {
        _isPremiumUser = isPro;
        _checkedPremium = true;
      });

      // Fetch notifications for all users (premium and non-premium).
      // Non-premium users are allowed to see Matches/Visits/Requests; only
      // the Likes tab is locked UI-wise. Previously we only fetched for
      // premium users which left non-premium users in a permanent loading
      // state (_loading stayed true). Always fetch so lists populate.
      await _fetchNotifications();
    } catch (e) {
      // If anything goes wrong, treat as non-premium but mark checked
      setState(() {
        _isPremiumUser = false;
        _checkedPremium = true;
      });

      // Still attempt to fetch notifications so the UI doesn't remain
      // stuck on the loading spinner when the premium check fails.
      try {
        await _fetchNotifications();
      } catch (_) {
        // ignore fetch failure here — _fetchNotifications already logs errors
      }
    }
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _loading = true;
    });
    print('🔄 [_fetchNotifications] started, _loading set to true');
    try {
      final String? accessToken = await SocialLoginService.getAccessToken();
      if (accessToken == null) {
        print('❌ No access token found');
        setState(() => _loading = false);
        print('🔄 [_fetchNotifications] ended early (no token), _loading set to false');
        return;
      }
      print('🔑 Retrieved access token: ${accessToken.length} chars');

      final response = await http.post(
        Uri.parse(
            'https://backend.staralign.me/endpoint/v1/models/notifications/get_notifications'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'access_token': accessToken,
          'limit': _limit.toString(),
          'offset': _offset.toString(),
        },
      );

      print('📱 Notifications response status: ${response.statusCode}');
      print('📄 Notifications response body: ${response.body}');

      if (response.statusCode == 200) {
        // Handle mixed response (HTML + JSON)
        String body = response.body;
        if (body.contains('<')) {
          // Extract JSON from mixed response
          int jsonStart = body.indexOf('{');
          if (jsonStart != -1) {
            body = body.substring(jsonStart);
            int jsonEnd = body.lastIndexOf('}');
            if (jsonEnd != -1) {
              body = body.substring(0, jsonEnd + 1);
            }
          }
        }

        final data = jsonDecode(body);
        if (data['code'] == 200 && data['data'] != null) {
          final List<dynamic> list = List<dynamic>.from(data['data'] ?? []);
          // update last id (max) to support incremental fetch if needed
          if (list.isNotEmpty) {
            try {
              final ids = list.map((e) => int.tryParse(e['id'].toString()) ?? 0).toList();
              final maxId = ids.fold<int>(0, (p, c) => c > p ? c : p);
              if (maxId > _offset) _offset = maxId;
            } catch (_) {}
          }
          setState(() {
            _allNotifications = list;
            _newNotificationCount = data['new_notification_count'] ?? 0;
          });
          _filterNotifications();
          print('ℹ️ [_fetchNotifications] data loaded: ${list.length} items; filtered: ${_filteredNotifications.length}');
        } else {
          print('❌ Error in response: ${data['errors']}');
          setState(() {
            _allNotifications = [];
            _filteredNotifications = [];
          });
        }
      } else {
        print('❌ Failed to fetch notifications: ${response.statusCode}');
        setState(() {
          _allNotifications = [];
          _filteredNotifications = [];
        });
      }
    } catch (e) {
      print('❌ Exception fetching notifications: $e');
      setState(() {
        _allNotifications = [];
        _filteredNotifications = [];
      });
    }
    setState(() {
      _loading = false;
    });
    print('🔄 [_fetchNotifications] finished, _loading set to false');
  }

  bool _isMatchType(String type) {
    final t = type.toLowerCase();
    return t == 'got_new_match' || t.contains('match');
  }

  bool _isVisitType(String type) {
    final t = type.toLowerCase();
    return t == 'visit' || t.contains('visit');
  }

  bool _isLikeType(String type) {
    final t = type.toLowerCase();
    return t == 'like' || t.contains('like');
  }

  bool _isRequestType(String type) {
    final t = type.toLowerCase();
    // Consider it a request only when it's an actual pending friend request.
    // Exclude types that indicate the request was already accepted/handled
    // (for example: 'friend_request_accepted', 'friend_request_accepted_by').
    if (!t.contains('friend_request')) return false;
    if (t.contains('accept') || t.contains('accepted') || t.contains('declin') || t.contains('handled')) {
      return false;
    }
    // common names that indicate pending request
    return t == 'friend_request' || t.endsWith('_request') || t.contains('friend_request_');
  }

  void _filterNotifications() {
    setState(() {
      switch (_currentTabIndex) {
        case 0: // Matches
          _filteredNotifications = _allNotifications
              .where((n) => _isMatchType((n['type'] ?? '').toString()))
              .toList();
          break;
        case 1: // Visits
          _filteredNotifications = _allNotifications
              .where((n) => _isVisitType((n['type'] ?? '').toString()))
              .toList();
          break;
        case 2: // Likes
          _filteredNotifications = _allNotifications
              .where((n) => _isLikeType((n['type'] ?? '').toString()))
              .toList();
          break;
        case 3: // Requests
          _filteredNotifications = _allNotifications
              .where((n) => _isRequestType((n['type'] ?? '').toString()))
              .toList();
          break;
        default:
          _filteredNotifications = _allNotifications;
      }
    });
    print('🔍 [_filterNotifications] tab=$_currentTabIndex filtered=${_filteredNotifications.length} all=${_allNotifications.length} isPremium=$_isPremiumUser');
  }
  Future<void> _handleRequestAction({
    required bool accept,
    required dynamic notification,
  }) async {
    try {
      final String idStr = notification['id']?.toString() ?? '';
      if (idStr.isNotEmpty && _processingRequests.contains(idStr)) {
        print('Already processing request $idStr, ignoring duplicate tap.');
        return;
      }
      if (idStr.isNotEmpty) {
        setState(() => _processingRequests.add(idStr));
      }
      print('🔹 _handleRequestAction called | accept=$accept');
      print('🔸 Notification object: $notification');

      final String? accessToken = await SocialLoginService.getAccessToken();
      print('🔑 Access Token: $accessToken');

      if (accessToken == null) {
        print('❌ No access token found.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not authenticated')),
        );
        if (idStr.isNotEmpty) setState(() => _processingRequests.remove(idStr));
        return;
      }

      final int notifierId =
          int.tryParse(notification['notifier_id'].toString()) ?? 0;
      print('👤 Notifier ID: $notifierId');

      if (notifierId <= 0) {
        print('⚠️ Invalid notifier ID.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid request user')),
        );
        if (idStr.isNotEmpty) setState(() => _processingRequests.remove(idStr));
        return;
      }

      // If declined → skip API call, just remove locally.
      if (!accept) {
        print('🟠 Decline selected → removing notification locally.');
        setState(() {
          _allNotifications
              .removeWhere((n) => n['id'].toString() == notification['id'].toString());
        });
        _filterNotifications();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request declined')),
        );
        // Attempt to remove the notification server-side as well
        try {
          final id = notification['id']?.toString() ?? '';
          if (id.isNotEmpty) {
            final removed = await _removeNotificationOnServer(id);
            if (!removed) {
              debugPrint('⚠️ Could not remove notification $id from server after decline');
            }
          }
        } catch (e) {
          debugPrint('Error removing notification on server after decline: $e');
        }
        if (idStr.isNotEmpty) setState(() => _processingRequests.remove(idStr));
        return;
      }

      // ✅ API call for accepting friend request
      final url = Uri.parse('${SocialLoginService.baseUrl}/users/approve_friend_request');
      print('🌐 Sending POST → $url');
      print('📦 Request Body: { access_token: $accessToken, uid: $notifierId }');

      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'access_token': accessToken,
          'uid': notifierId.toString(),
        },
      );

      print('📡 Response Status Code: ${resp.statusCode}');
      print('🧾 Raw Response Body: ${resp.body}');

      String raw = resp.body;
      if (raw.contains('<')) {
        print('⚙️ Stripping HTML junk from response...');
        final s = raw.indexOf('{');
        final e = raw.lastIndexOf('}');
        if (s != -1 && e != -1 && e > s) raw = raw.substring(s, e + 1);
      }

      final Map<String, dynamic> data = jsonDecode(raw);
      print('📦 Decoded Response JSON: $data');

      final int status = data['status'] ?? data['code'] ?? 0;
      print('✅ Parsed Status Code: $status');

      // If server reports success, remove locally. Also handle "already accepted" gracefully.
      final String message = (data['message'] ?? data['msg'] ?? '').toString();
      if (resp.statusCode == 200 && status == 200) {
        print('🎉 Friend request accepted successfully!');

        setState(() {
          _allNotifications
              .removeWhere((n) => n['id'].toString() == notification['id'].toString());
        });
        _filterNotifications();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request accepted')),
        );
        // Ensure backend notification is removed
        try {
          final id = notification['id']?.toString() ?? '';
          if (id.isNotEmpty) {
            final removed = await _removeNotificationOnServer(id);
            if (!removed) {
              debugPrint('⚠️ Could not remove notification $id from server after accept');
            }
          }
        } catch (e) {
          debugPrint('Error removing notification on server after accept: $e');
        }
      } else if (message.toLowerCase().contains('already') || message.toLowerCase().contains('accepted')) {
        // Backend says it's already accepted — remove locally to avoid duplicate actions.
        print('ℹ️ Server indicates request already accepted: $message');
        setState(() {
          _allNotifications
              .removeWhere((n) => n['id'].toString() == notification['id'].toString());
        });
        _filterNotifications();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message.isNotEmpty ? message : 'Already accepted')),
        );
        // Try to clean up the notification on server when it's already accepted
        try {
          final id = notification['id']?.toString() ?? '';
          if (id.isNotEmpty) {
            final removed = await _removeNotificationOnServer(id);
            if (!removed) debugPrint('⚠️ Could not remove notification $id from server (already accepted)');
          }
        } catch (e) {
          debugPrint('Error removing notification on server (already accepted): $e');
        }
      } else {
        // Also handle common server responses where the request is no longer present
        // (for example: 400 with error_text "No friend requests found") — treat as already-processed.
        final String errorText = (data['errors']?['error_text'] ?? '').toString().toLowerCase();
        final String errorId = (data['errors']?['error_id'] ?? '').toString();
        if (errorText.contains('no friend request') || errorText.contains('no friend requests') || errorId == '25') {
          print('ℹ️ Server indicates no friend request exists (treated as already processed): $errorText');
          setState(() {
            _allNotifications
                .removeWhere((n) => n['id'].toString() == notification['id'].toString());
          });
          _filterNotifications();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorText.isNotEmpty ? errorText : 'Request already handled')),
          );
        } else {
          final errorMsg = data['errors']?['error_text']?.toString() ??
              data['message']?.toString() ??
              'Action failed';
          print('⚠️ API returned failure: $errorMsg');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $errorMsg')),
          );
        }
      }
    } catch (e, stack) {
      print('💥 Exception: $e');
      print('🧩 Stack trace: $stack');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action error: $e')),
      );
    } finally {
      // Ensure processing flag is cleared so user can interact again
      final String idStr = notification['id']?.toString() ?? '';
      if (idStr.isNotEmpty) {
        setState(() => _processingRequests.remove(idStr));
      }
    }
  }

  // Attempts to remove/mark a notification on the server. Many backends
  // expose different endpoints or parameter names, so try a few reasonable
  // candidates. Returns true if any attempt reported success (code == 200).
  Future<bool> _removeNotificationOnServer(String notificationId) async {
    try {
      final String? token = await SocialLoginService.getAccessToken();
      if (token == null) return false;

      final base = SocialLoginService.baseUrl; // already contains /endpoint/v1/models
      final candidates = <String>[
        '/notifications/delete',
        '/notifications/delete_notification',
        '/notifications/remove_notification',
        '/notifications/remove',
        '/notifications/mark_as_read',
        '/notifications/mark_as_seen',
        '/notifications/seen',
      ];

      for (final path in candidates) {
        try {
          final uri = Uri.parse('$base$path');
          // Try two common parameter names: 'id' and 'notification_id'
          final resp1 = await http.post(uri,
              headers: {'Content-Type': 'application/x-www-form-urlencoded'},
              body: {
                'access_token': token,
                'id': notificationId,
              });
          if (resp1.statusCode == 200) {
            try {
              final data = jsonDecode(resp1.body);
              if ((data['code'] ?? data['status']) == 200) return true;
            } catch (_) {
              // If not JSON, treat HTTP 200 as success
              return true;
            }
          }

          final resp2 = await http.post(uri,
              headers: {'Content-Type': 'application/x-www-form-urlencoded'},
              body: {
                'access_token': token,
                'notification_id': notificationId,
              });
          if (resp2.statusCode == 200) {
            try {
              final data = jsonDecode(resp2.body);
              if ((data['code'] ?? data['status']) == 200) return true;
            } catch (_) {
              return true;
            }
          }
        } catch (e) {
          debugPrint('Attempt to $path failed: $e');
          // try next
        }
      }
    } catch (e) {
      debugPrint('Error in _removeNotificationOnServer: $e');
    }
    return false;
  }

  // Future<void> _handleRequestAction({required bool accept, required dynamic notification}) async {
  //   try {
  //     final String? accessToken = await SocialLoginService.getAccessToken();
  //     if (accessToken == null) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Not authenticated')),
  //       );
  //       return;
  //     }
  //     final int notifierId = int.tryParse(notification['notifier_id'].toString()) ?? 0;
  //     if (notifierId <= 0) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Invalid request user')),
  //       );
  //       return;
  //     }
  //     final resp = await http.post(
  //       Uri.parse('https://backend.staralign.me/endpoint/v1/models/users/messages_requests'),
  //       headers: {'Content-Type': 'application/x-www-form-urlencoded'},
  //       body: {
  //         'access_token': accessToken,
  //         'user_id': notifierId.toString(),
  //         'type': accept ? 'accept' : 'decline',
  //       },
  //     );
  //     String raw = resp.body;
  //     if (raw.contains('<')) {
  //       final s = raw.indexOf('{');
  //       final e = raw.lastIndexOf('}');
  //       if (s != -1 && e != -1 && e > s) raw = raw.substring(s, e + 1);
  //     }
  //     final Map<String, dynamic> data = jsonDecode(raw);
  //     final ok = (resp.statusCode == 200) && ((data['status'] ?? data['code']) == 200);
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text(ok ? (accept ? 'Request accepted' : 'Request declined') : 'Action failed')),
  //     );
  //     if (ok) {
  //       // Remove this notification from current list
  //       setState(() {
  //         _allNotifications.removeWhere((n) => n['id'].toString() == notification['id'].toString());
  //       });
  //       _filterNotifications();
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Action error: $e')),
  //     );
  //   }
  // }

  String _formatTime(dynamic timestamp) {
    try {
      int time;
      if (timestamp is String) {
        time = int.tryParse(timestamp) ?? 0;
      } else if (timestamp is int) {
        time = timestamp;
      } else {
        return '';
      }

      final date = DateTime.fromMillisecondsSinceEpoch(time * 1000);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h';
      } else {
        return '${difference.inDays}d';
      }
    } catch (e) {
      return '';
    }
  }

  Widget _buildNotificationItem(dynamic notification) {
    final notifier = notification['notifier'] ?? {};
    final avatarUrl = notifier['avater'] ?? notifier['avatar'] ?? '';
    final fullName = notifier['full_name'] ?? notifier['username'] ?? 'User';
    final text = notification['text'] ?? '';
    final seen = notification['seen'] != 0;
    final type = (notification['type'] ?? '').toString();
    final timestamp = notification['created_at'];

    // Determine icon color based on notification type
    Color iconColor = Colors.blue;
    IconData iconData = Icons.notifications;

    if (_isMatchType(type)) {
      iconColor = Colors.pink;
      iconData = Icons.favorite;
    } else if (_isVisitType(type)) {
      iconColor = Colors.green;
      iconData = Icons.visibility;
    } else if (_isLikeType(type)) {
      iconColor = Colors.red;
      iconData = Icons.thumb_up;
    } else if (_isRequestType(type)) {
      iconColor = Colors.orange;
      iconData = Icons.person_add;
    }

    final isRequest = _isRequestType(type);

    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: seen ? Colors.transparent : Colors.blue.withValues(alpha: 0.05),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Handle notification tap
            print('Tapped notification: ${notification['url']}');
          },
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                // Profile Picture with Icon Overlay
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: avatarUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(avatarUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: avatarUrl.isEmpty ? Colors.grey[300] : null,
                      ),
                      child: avatarUrl.isEmpty
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      top: 0,
                      right: -5,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: iconColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: Icon(
                          iconData,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Content
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Name
                      Text(
                        fullName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: seen ? FontWeight.normal : FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2.0),
                      // Notification text
                      Text(
                        text,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w300,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Time and Action Buttons
                Flexible(
                  flex: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Time (hide when it's a request, to match the native app behavior)
                      if (!isRequest)
                        Text(
                          _formatTime(timestamp),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      // Action Buttons (for requests)
                      if (isRequest)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Accept Button
                            Container(
                              width: 35,
                              height: 35,
                              margin: const EdgeInsets.only(right: 7),
                              decoration: const BoxDecoration(
                                color: Colors.purple,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                onPressed: _processingRequests.contains(notification['id']?.toString() ?? '')
                                    ? null
                                    : () => _handleRequestAction(accept: true, notification: notification),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            // Decline Button
                            Container(
                              width: 35,
                              height: 35,
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                onPressed: () => _handleRequestAction(accept: false, notification: notification),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      )
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (_currentTabIndex) {
      case 0:
        message = 'No matches yet';
        icon = Icons.favorite_border;
        break;
      case 1:
        message = 'No visits yet';
        icon = Icons.visibility_off;
        break;
      case 2:
        message = 'No likes yet';
        icon = Icons.thumb_up_off_alt;
        break;
      case 3:
        message = 'No requests yet';
        icon = Icons.person_add_disabled;
        break;
      default:
        message = 'No notifications yet';
        icon = Icons.notifications_off;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When you get ${_tabs[_currentTabIndex].toLowerCase()}, they\\\'ll appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Locked view shown only for Likes tab when the user is not premium
  Widget _buildLockedLikesView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Get premium to view who liked you!',
              style: TextStyle(
                fontSize: 18,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Upgrade to premium to see who liked you and unlock other premium features.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Public method to allow parent to trigger a manual refresh
  Future<void> refreshNotifications() async {
    await _fetchNotifications();
  }

  // Remove all pending request notifications locally and attempt to remove them on the server.
  Future<void> _clearAllRequests() async {
    if (_allNotifications.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No notifications to clear')));
      return;
    }

    final pending = _allNotifications.where((n) => _isRequestType((n['type'] ?? '').toString())).toList();
    if (pending.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No pending requests to clear')));
      return;
    }

    int removedLocal = 0;
    int removedServer = 0;

    // Remove locally first for immediate UX
    setState(() {
      for (final n in pending) {
        _allNotifications.removeWhere((x) => x['id'].toString() == n['id'].toString());
        removedLocal++;
      }
      _filterNotifications();
    });

    // Try removing on server in background
    for (final n in pending) {
      final id = n['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      try {
        final ok = await _removeNotificationOnServer(id);
        if (ok) removedServer++;
      } catch (e) {
        debugPrint('Error removing notification $id on server: $e');
      }
    }

    if (!mounted) return;
    final msg = 'Cleared $removedLocal local requests, $removedServer removed from server';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    // Gate build method while we determine premium status
    if (!_checkedPremium) {
      return Scaffold(
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // NOTE: Previously the UI was fully gated to premium users. We now allow
    // all users to view Matches/Visits/Requests. The Likes tab (index 2)
    // shows a locked view for non-premium users when `AppSettings.premiumSystemEnabled`.

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
             // Custom AppBar with gradient background
             Container(
               padding: EdgeInsets.only(
                 top: MediaQuery.of(context).padding.top + 13,
                 left: 16,
                 right: 16,
                 bottom: 0,
               ),
               decoration: BoxDecoration(
                 gradient: LinearGradient(
                   begin: Alignment.topCenter,
                   end: Alignment.bottomCenter,
                   colors: [
                     Colors.purple.withValues(alpha: 0.3),
                     Colors.transparent,
                   ],
                 ),
               ),
               child: Column(
                 children: [
                   // Toolbar (use padding instead of fixed height to avoid overflow
                   // when available vertical space is constrained)
                   Padding(
                     padding: const EdgeInsets.symmetric(vertical: 8.0),
                     child: Row(
                       crossAxisAlignment: CrossAxisAlignment.center,
                       children: [
                         IconButton(
                           icon: const Icon(Icons.arrow_back),
                           onPressed: () {
                             // Ensure we return to the app's HomeScreen instead of
                             // potentially navigating back to the Login screen.
                             Navigator.of(context).pushReplacement(
                               MaterialPageRoute(builder: (_) => const HomeScreen()),
                             );
                           },
                           color: Colors.black87,
                         ),
                         const SizedBox(width: 6),
                         Expanded(
                           child: Text(
                             'Notifications',
                             style: const TextStyle(
                               fontSize: 20,
                               fontWeight: FontWeight.bold,
                               color: Colors.black87,
                             ),
                           ),
                         ),
                         if (_newNotificationCount > 0)
                           Container(
                             padding: const EdgeInsets.symmetric(
                                 horizontal: 8, vertical: 4),
                             decoration: BoxDecoration(
                               color: Colors.red,
                               borderRadius: BorderRadius.circular(12),
                             ),
                             child: Text(
                               _newNotificationCount.toString(),
                               style: const TextStyle(
                                 color: Colors.white,
                                 fontSize: 12,
                                 fontWeight: FontWeight.bold,
                               ),
                             ),
                           ),
                        // Clear Requests button for debugging/cleanup
                        IconButton(
                          tooltip: 'Clear requests',
                          icon: const Icon(Icons.delete_sweep, color: Colors.black54),
                          onPressed: () async {
                            await _clearAllRequests();
                          },
                        ),
                       ],
                     ),
                   ),
                   // Tab Bar
                   TabBar(
                     controller: _tabController,
                     isScrollable: true,
                     tabAlignment: TabAlignment.center,
                     indicatorColor: Colors.purple,
                     indicatorWeight: 2.0,
                     indicatorSize: TabBarIndicatorSize.label,
                     labelColor: Colors.purple,
                     unselectedLabelColor: Colors.grey,
                     labelStyle: const TextStyle(
                       fontWeight: FontWeight.bold,
                       fontSize: 14,
                     ),
                     unselectedLabelStyle: const TextStyle(
                       fontWeight: FontWeight.normal,
                       fontSize: 14,
                     ),
                     tabs: _tabs
                         .map((tab) => Tab(
                               child: Container(
                                 padding: const EdgeInsets.symmetric(
                                     horizontal: 16, vertical: 8),
                                 decoration: _currentTabIndex == _tabs.indexOf(tab)
                                     ? BoxDecoration(
                                         color: Colors.purple.withValues(alpha: 0.1),
                                         borderRadius: BorderRadius.circular(20),
                                       )
                                     : null,
                                 child: Text(tab),
                               ),
                             ))
                         .toList(),
                   ),
                 ],
               ),
             ),
             // Content Area
             Expanded(
               child: RefreshIndicator(
                 onRefresh: _fetchNotifications,
                 color: Colors.purple,
                 child: Stack(
                  children: [
                    // Core content: locked likes / empty state / list — shown
                    // once we have checked premium status regardless of _loading.
                    (AppSettings.premiumSystemEnabled && !_isPremiumUser && _currentTabIndex == 2)
                        ? _buildLockedLikesView()
                        : (_filteredNotifications.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.only(
                                  top: 2,
                                  bottom: 70,
                                ),
                                itemCount: _filteredNotifications.length,
                                itemBuilder: (context, index) {
                                  return _buildNotificationItem(
                                      _filteredNotifications[index]);
                                },
                              )),

                    // Small inline loading indicator (non-blocking) when background loading
                    if (_loading)
                      const Positioned(
                        right: 16,
                        top: 12,
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.purple,
                          ),
                        ),
                      ),
                  ],
                ),
               ),
             ),
           ],
         ),
       ),
    );
   }
 }
