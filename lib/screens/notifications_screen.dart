import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'social_login_service.dart';
import '../utils/app_settings.dart';
import '../utils/user_details.dart';
import 'LoginActivity.dart';

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
    return t.contains('friend_request');
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

  Future<void> _handleRequestAction({required bool accept, required dynamic notification}) async {
    try {
      final String? accessToken = await SocialLoginService.getAccessToken();
      if (accessToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not authenticated')),
        );
        return;
      }
      final int notifierId = int.tryParse(notification['notifier_id'].toString()) ?? 0;
      if (notifierId <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid request user')),
        );
        return;
      }
      final resp = await http.post(
        Uri.parse('https://backend.staralign.me/endpoint/v1/models/users/messages_requests'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'access_token': accessToken,
          'user_id': notifierId.toString(),
          'type': accept ? 'accept' : 'decline',
        },
      );
      String raw = resp.body;
      if (raw.contains('<')) {
        final s = raw.indexOf('{');
        final e = raw.lastIndexOf('}');
        if (s != -1 && e != -1 && e > s) raw = raw.substring(s, e + 1);
      }
      final Map<String, dynamic> data = jsonDecode(raw);
      final ok = (resp.statusCode == 200) && ((data['status'] ?? data['code']) == 200);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? (accept ? 'Request accepted' : 'Request declined') : 'Action failed')),
      );
      if (ok) {
        // Remove this notification from current list
        setState(() {
          _allNotifications.removeWhere((n) => n['id'].toString() == notification['id'].toString());
        });
        _filterNotifications();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action error: $e')),
      );
    }
  }

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
      height: 70,
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
                Expanded(
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
                      const SizedBox(height: 4.5),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              onPressed: () => _handleRequestAction(accept: true, notification: notification),
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Upgrade to Premium',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug print every build so we can trace UI state at runtime
    if (kDebugMode) {
      print('🧭 build checked=$_checkedPremium loading=$_loading isPremium=$_isPremiumUser tab=$_currentTabIndex filtered=${_filteredNotifications.length} all=${_allNotifications.length}');
    }
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
            // Debug banner (visible only in debug builds)
            if (kDebugMode)
              Container(
                color: Colors.black12,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    Text('checked: ${_checkedPremium ? 'T' : 'F'}', style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    Text('loading: ${_loading ? 'T' : 'F'}', style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    Text('premium: ${_isPremiumUser ? 'T' : 'F'}', style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    Text('tab: $_currentTabIndex', style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    Text('all:${_allNotifications.length}', style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    Text('filtered:${_filteredNotifications.length}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
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
                   // Toolbar
                   SizedBox(
                     height: 48,
                     child: Row(
                       children: [
                         IconButton(
                           icon: const Icon(Icons.arrow_back),
                           onPressed: () => Navigator.of(context).pop(),
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

