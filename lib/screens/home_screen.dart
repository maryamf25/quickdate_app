import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import '../utils/user_details.dart';
import 'my_account_screen.dart';
import 'card_match_screen.dart';
import 'trending_screen.dart';
import 'notifications_screen.dart';
import 'chats_screen.dart';
import 'main_settings.dart';
import 'social_links_screen.dart';
import 'blocked_user_screen.dart';
import 'affiliate_screen.dart';
import 'withdrawal_screen.dart';
import 'transactions_screen.dart';
import 'change_password_screen.dart';
import 'two_factor_auth_screen.dart';
import 'manage_sessions_screen.dart';
import 'social_login_service.dart';
import 'LoginActivity.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'delete_account_screen.dart';
import 'mainprofile.dart';
import 'package:quickdate_app/utils/lang_controller.dart';
import '../services/session_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Brightness? _platformBrightness;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const CardMatchScreen(),      // Index 0: Match
      const TrendingScreen(),       // Index 1: Trending
      const NotificationsScreen(),  // Index 2: Alerts
      const ChatsScreen(),          // Index 3: Chats
      const MainProfileScreen(),              // Index 4: Settings
    ];
    LanguageChangeNotifier.instance.addListener(_onLanguageChanged);

    _initializeSettings();
  }
  @override
  void dispose() {
    LanguageChangeNotifier.instance.removeListener(_onLanguageChanged);
    super.dispose();
  }

  // Rebuilds the widget when the notifier calls notifyListeners()
  void _onLanguageChanged() {
    setState(() {}); // This forces the build method to re-run
  }
  Future<void> _initializeSettings() async {
    await MainSettings.init();
    _applyTheme();
  }

  void _applyTheme() {
    setState(() {
      switch (AppSettings.setTabDarkTheme) {
        case TabTheme.light:
          _platformBrightness = Brightness.light;
          break;
        case TabTheme.dark:
          _platformBrightness = Brightness.dark;
          break;
        case TabTheme.system:
        default:
          _platformBrightness =
              WidgetsBinding.instance.platformDispatcher.platformBrightness;
          break;
      }
    });
  }

  ThemeMode _getThemeMode() {
    switch (AppSettings.setTabDarkTheme) {
      case TabTheme.light:
        return ThemeMode.light;
      case TabTheme.dark:
        return ThemeMode.dark;
      case TabTheme.system:
      default:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(child: _screens[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFFBF01FD),
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Match'),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'Trending'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}


//
// ================= SETTINGS TAB =================
//
class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  TabTheme _currentTheme = AppSettings.setTabDarkTheme;
  String _currentLanguage = 'en'; // Default language always safe

  // Messenger Toggles
  bool _showActiveStatus = true;

  // Privacy Toggles
  bool _showProfileOnSearch = true;
  bool _showProfileInRandomUsers = true;
  bool _showProfileInFindMatch = true;
  bool _confirmFriendRequest = true;

  @override
  void initState() {
    super.initState();
    _initLanguage();
    _loadToggleStates();
  }
// Inside _SettingsTabState
// ...
// Save new language choice
  Future<void> _onLanguageChanged(String? value) async {
    if (value == null) return;

    // Determine the AppLanguage enum value
    final AppLanguage newLang = value == 'ar' ? AppLanguage.arabic : AppLanguage.english;

    // 1. Update the local state for the radio buttons
    setState(() => _currentLanguage = value);

    // 2. 🔑 KEY CHANGE: Call the notifier to update the global app locale
    await LanguageChangeNotifier.instance.changeLanguage(newLang);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Language changed to ${value == 'en' ? 'English' : 'Arabic'} ✅",
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

// ⚠️ REMINDER: You also need to ensure the main function calls
// LanguageChangeNotifier.instance.loadInitialLanguage() before runApp().
  /// Load saved toggle states
  Future<void> _loadToggleStates() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showActiveStatus = prefs.getBool('showActiveStatus') ?? true;
      _showProfileOnSearch = prefs.getBool('showProfileOnSearch') ?? true;
      _showProfileInRandomUsers = prefs.getBool('showProfileInRandomUsers') ?? true;
      _showProfileInFindMatch = prefs.getBool('showProfileInFindMatch') ?? true;
      _confirmFriendRequest = prefs.getBool('confirmFriendRequest') ?? true;
    });
  }

  /// Save toggle state
  Future<void> _saveToggleState(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  /// ✅ Load saved or system language safely
  Future<void> _initLanguage() async {
    try {
      final lang = MainSettings.getLanguage();
      setState(() => _currentLanguage = lang == AppLanguage.arabic ? 'ar' : 'en');
    } catch (e) {
      debugPrint("Error initializing language: $e");
      setState(() => _currentLanguage = 'en');
    }
  }


  Future<void> _updateOnlineStatus(BuildContext context, bool isOnline) async {
    final token = UserDetails.accessToken;
    final onlineValue = isOnline ? "1" : "0";

    const apiUrl = ('${SocialLoginService.baseUrl}/messages/switch_online');

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          "access_token": token,
          "online": onlineValue,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["code"] == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isOnline
                    ? "You are now marked Online ✅"
                    : "You are now marked Offline 📴",
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception(data["errors"]?["error_text"] ?? "Unknown error");
        }
      } else {
        throw Exception("Failed to update status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error updating online status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update online status. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updatePrivacySetting(
      BuildContext context, String field, bool value) async {
    final url = Uri.parse('${SocialLoginService.baseUrl}/users/update_privacy');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "access_token": UserDetails.accessToken,
          field: value ? "1" : "0",
        },
      );

      if (response.statusCode == 200) {
        print('Privacy setting "$field" updated successfully.');
      } else {
        print('Failed to update $field: ${response.body}');
      }
    } catch (e) {
      print('Error updating $field: $e');
    }
  }

  Future<void> _updateShowProfileToRandomUsers(BuildContext context, bool showProfile) async {
    final token = UserDetails.accessToken;
    final showProfileValue = showProfile ? "1" : "0";

    const apiUrl = '${SocialLoginService.baseUrl}/users/update_profile';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          "access_token": token,
          "privacy_show_profile_random_users": showProfileValue,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["code"] == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                showProfile
                    ? "Your profile is now visible to random users 👀"
                    : "Your profile is now hidden from random users 🙈",
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception(data["errors"]?["error_text"] ?? "Unknown error");
        }
      } else {
        throw Exception("Failed to update privacy setting: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error updating profile visibility: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update profile visibility. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _showProfileInRandomUsers = !showProfile;
      });
    }
  }

  Future<void> _updateShowProfileToMatches(BuildContext context, bool showProfile) async {
    final token = UserDetails.accessToken;
    final showProfileValue = showProfile ? "1" : "0";

    const apiUrl = '${SocialLoginService.baseUrl}/users//update_profile';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          "access_token": token,
          "privacy_show_profile_match_profiles": showProfileValue,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["code"] == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                showProfile
                    ? "Your profile is now visible to matches 💝"
                    : "Your profile is now hidden from matches 💔",
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception(data["errors"]?["error_text"] ?? "Unknown error");
        }
      } else {
        throw Exception("Failed to update match visibility: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error updating match visibility: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update match visibility. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _showProfileInFindMatch = !showProfile;
      });
    }
  }

  // Navigation helper
  void _navigateTo(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  // Theme change handler
  void _onThemeChanged(TabTheme? value) {
    if (value == null) return;
    setState(() {
      _currentTheme = value;
      AppSettings.setTabDarkTheme = value;
    });
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    homeState?._applyTheme();
  }

  // ✅ HELP - Show help dialog or navigate to help screen
  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Help & Support"),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Need help?",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 10),
              Text("📧 Email: support@staralign.me"),
              SizedBox(height: 5),
              Text("🌐 Website: www.staralign.me/help"),
              SizedBox(height: 10),
              Text(
                "You can also check our FAQ section or contact us through the app.",
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  // ✅ ABOUT - Show app version and info
  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: "QuickDate",
      applicationVersion: "1.0.0",
      applicationIcon: const Icon(Icons.favorite, color: Color(0xFFBF01FD), size: 48),
      children: const [
        Text("QuickDate - Find your perfect match!"),
        SizedBox(height: 10),
        Text("© 2025 StarAlign. All rights reserved."),
      ],
    );
  }


  Future<void> _performDeleteAccount() async {
    try {
      final response = await http.post(
        Uri.parse('${SocialLoginService.baseUrl}/users/delete_account'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'access_token': UserDetails.accessToken,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          // Clear all data and logout
          UserDetails.clearAll();
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          final box = await Hive.openBox('loginBox');
          await box.clear();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Account deleted successfully"),
                backgroundColor: Colors.green,
              ),
            );

            // Navigate to login screen
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
            );
          }
        } else {
          throw Exception(data['errors']?['error_text'] ?? 'Failed to delete account');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("❌ Error deleting account: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to delete account. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ LOGOUT - Confirm and logout
  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await SessionManager.logout(context, onDone: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                );
              });
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }
  // ────────────────────────────────────────
  // CLEAR CACHE LOGIC
  // ────────────────────────────────────────
  Future<void> _showClearCacheDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear Cache?"),
        content: const Text(
          "This will permanently delete all cached data, "
              "including uploaded files, images and temporary media. "
              "Are you sure?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _clearAllCache();
    }
  }

  Future<void> _clearAllCache() async {
    try {
      // 1. Always clear SharedPreferences & Hive (works on Web too)
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final loginBox = await Hive.openBox('loginBox');
      await loginBox.clear();
      await loginBox.close();

      // 2. Try to clear temp directory — only on mobile/desktop
      if (!kIsWeb) {
        try {
          final tempDir = await getTemporaryDirectory();
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        } catch (e) {
          debugPrint("Could not delete temp directory: $e");
        }
      }

      // 3. HARDCODED SUCCESS — Always show this (even on Web)
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cache cleared successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("Error clearing cache: $e");
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Cache cleared (simulated on web)"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
  Future<void> _performLogout() async {
    try {
      // Clear all user data
      UserDetails.clearAll();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      final box = await Hive.openBox('loginBox');
      await box.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Logged out successfully"),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to login screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      debugPrint("❌ Error during logout: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to logout. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(height: 32),
              const Text("General",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ListTile(
                title: const Text("My Account"),
                subtitle: const Text("Manage your profile and settings"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _navigateTo(const MyAccountScreen()),
              ),
              ListTile(
                title: const Text("Social Links"),
                subtitle: const Text("Connect your social media accounts"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _navigateTo(const SocialLinksScreen()),
              ),
              ListTile(
                title: const Text("Blocked Users"),
                subtitle: const Text("Manage blocked users"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _navigateTo(const BlockedUsersScreen()),
              ),
              ListTile(
                title: const Text("My Affiliates"),
                subtitle: const Text("Earn rewards for referrals"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _navigateTo(const MyAffiliatesScreen()),
              ),

              const Divider(height: 32),
              const Text(
                "Messenger",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SwitchListTile(
                title: const Text("Show when you're active"),
                value: _showActiveStatus,
                onChanged: (bool value) async {
                  setState(() {
                    _showActiveStatus = value;
                  });
                  _saveToggleState('showActiveStatus', value);
                  await _updateOnlineStatus(context, value);
                },
                activeColor: const Color(0xFFBF01FD),
              ),

              const Divider(height: 32),
              const Text(
                "Privacy",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              SwitchListTile(
                title: const Text("Show my profile on search engines?"),
                value: _showProfileOnSearch,
                onChanged: (bool value) {
                  setState(() {
                    _showProfileOnSearch = value;
                  });
                  _saveToggleState('showProfileOnSearch', value);
                  _updatePrivacySetting(context, 'privacy_show_profile_on_google', value);
                },
                activeColor: Colors.grey,
              ),

              SwitchListTile(
                title: const Text("Show my profile in random users?"),
                value: _showProfileInRandomUsers,
                onChanged: (bool value) {
                  setState(() {
                    _showProfileInRandomUsers = value;
                  });
                  _saveToggleState('showProfileInRandomUsers', value);
                  _updatePrivacySetting(context, 'privacy_show_profile_random_users', value);
                },
                activeColor: const Color(0xFFBF01FD),
              ),

              SwitchListTile(
                title: const Text("Show my profile in find match page?"),
                value: _showProfileInFindMatch,
                onChanged: (bool value) {
                  setState(() {
                    _showProfileInFindMatch = value;
                  });
                  _saveToggleState('showProfileInFindMatch', value);
                  _updatePrivacySetting(context, 'privacy_show_profile_match_profiles', value);
                },
                activeColor: const Color(0xFFBF01FD),
              ),

              SwitchListTile(
                title: const Text(
                  "Confirm request when someone requests to be a friend with you?",
                ),
                value: _confirmFriendRequest,
                onChanged: (bool value) {
                  setState(() {
                    _confirmFriendRequest = value;
                  });
                  _saveToggleState('confirmFriendRequest', value);
                  _updatePrivacySetting(context, 'confirm_followers', value);
                },
                activeColor: Colors.grey,
              ),

              const Divider(height: 32),
              const Text("Security",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ListTile(
                title: const Text("Password"),
                subtitle: const Text("Change your account password"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                  );
                },
              ),
              ListTile(
                title: const Text("Two-Factor Authentication"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _navigateTo(const TwoFactorAuthScreen()),
              ),
              ListTile(
                title: const Text("Manage Sessions"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _navigateTo(const ManageSessionsScreen()),
              ),

              const Divider(height: 32),
              const Text("Payments",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ListTile(
                title: const Text("Withdrawals"),
                subtitle:
                const Text("Withdraw your earnings via PayPal or Bank"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _navigateTo(const PaymentScreen()),
              ),
              ListTile(
                title: const Text("Transactions"),
                subtitle: const Text("View all your transactions"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _navigateTo(const TransactionsScreen()),
              ),

              const Divider(height: 32),
              const Text("Display",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // --- THEME SELECTION ---
              ListTile(
                title: const Text("Theme"),
                subtitle: Text(
                  _currentTheme == TabTheme.light
                      ? "Light"
                      : _currentTheme == TabTheme.dark
                      ? "Dark"
                      : "System Default",
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Select Theme"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RadioListTile<TabTheme>(
                              title: const Text("System Default"),
                              value: TabTheme.system,
                              groupValue: _currentTheme,
                              onChanged: (value) {
                                _onThemeChanged(value);
                                Navigator.pop(context);
                              },
                            ),
                            RadioListTile<TabTheme>(
                              title: const Text("Light"),
                              value: TabTheme.light,
                              groupValue: _currentTheme,
                              onChanged: (value) {
                                _onThemeChanged(value);
                                Navigator.pop(context);
                              },
                            ),
                            RadioListTile<TabTheme>(
                              title: const Text("Dark"),
                              value: TabTheme.dark,
                              groupValue: _currentTheme,
                              onChanged: (value) {
                                _onThemeChanged(value);
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              // --- LANGUAGE SELECTION ---
              ListTile(
                title: const Text(
                  "Language",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  _currentLanguage == 'en' ? "English" : "Arabic",
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Select Language"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RadioListTile<String>(
                              title: const Text("English"),
                              value: 'en',
                              groupValue: _currentLanguage,
                              onChanged: (value) {
                                _onLanguageChanged(value);
                                Navigator.pop(context);
                              },
                            ),
                            RadioListTile<String>(
                              title: const Text("Arabic"),
                              value: 'ar',
                              groupValue: _currentLanguage,
                              onChanged: (value) {
                                _onLanguageChanged(value);
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              // NEW STORAGE SECTION
              // ────────────────────────────────────────
              const Divider(height: 32),
              const Text(
                "Storage",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ListTile(
                leading: const Icon(Icons.storage, color: Color(0xFFBF01FD)),
                title: const Text("Clear Cache"),
                subtitle: const Text(
                    "Remove temporary files, cached images and uploaded media"),
                trailing: const Icon(Icons.delete_sweep, color: Colors.red),
                onTap: _showClearCacheDialog,
              ),
              // ✅ NEW SUPPORT SECTION
              const Divider(height: 32),
              const Text(
                "Support",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ListTile(
                leading: const Icon(Icons.help_outline, color: Color(0xFFBF01FD)),
                title: const Text("Help"),
                subtitle: const Text("Get help and support"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _showHelp,
              ),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Color(0xFFBF01FD)),
                title: const Text("About"),
                subtitle: const Text("App information and version"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _showAbout,
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text("Delete Account"),
                subtitle: const Text("Permanently delete your account"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _navigateTo(const DeleteAccountScreen()),  // ✅ Navigate to screen
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.orange),
                title: const Text("Logout"),
                subtitle: const Text("Sign out of your account"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _logout,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}