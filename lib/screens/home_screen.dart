
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'replace_password_screen.dart';
import 'two_factor_auth_screen.dart';
import 'manage_sessions_screen.dart';
import 'social_login_service.dart';

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
      const CardMatchScreen(),
      const TrendingScreen(),
      const NotificationsScreen(),
      const ChatsScreen(),
      _SettingsTab(),
    ];
    _initializeSettings();
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
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _getThemeMode(),
      home: Scaffold(
        body: SafeArea(child: _screens[_currentIndex]),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          selectedItemColor: const Color(0xFFBF01FD),
          unselectedItemColor: Colors.grey,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Match'),
            BottomNavigationBarItem(
                icon: Icon(Icons.trending_up), label: 'Trending'),
            BottomNavigationBarItem(
                icon: Icon(Icons.notifications), label: 'Alerts'),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}

//
// ================= SETTINGS TAB =================
//
class _SettingsTab extends StatefulWidget {
  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
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

  /// ✅ Save new language choice
  Future<void> _onLanguageChanged(String? value) async {
    if (value == null) return;
    setState(() => _currentLanguage = value);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', value);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Language changed to ${value == 'en' ? 'English' : 'Arabic'}",
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error saving language: $e");
    }
  }
  Future<void> _updateOnlineStatus(BuildContext context, bool isOnline) async {
    final token = UserDetails.accessToken; // ✅ replace with your stored token
    final onlineValue = isOnline ? "1" : "0";

    const apiUrl = ('${SocialLoginService.baseUrl}/messages/switch_online'); // ✅ your API URL

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
    final url = Uri.parse('${SocialLoginService.baseUrl}/users/update_privacy'); // Replace with your actual endpoint

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
      // Revert the toggle if API call fails
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
      // Revert the toggle if API call fails
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
                  await _updateOnlineStatus(context, value); // ✅ Updated version
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
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _navigateTo(
                    ReplacePasswordScreen(email: UserDetails.email)),
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
            ],
          ),
        ),
      ),
    );
  }
}