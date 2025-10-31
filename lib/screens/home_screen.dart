import 'dart:convert';

import 'package:http/http.dart' as http;
import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:quickdate_app/utils/lang_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';

import '../utils/user_details.dart';
import 'my_account_screen.dart';
import 'card_match_screen.dart';
import 'trending_screen.dart';
import 'notifications_screen.dart';
import 'chats_screen.dart';
import 'main_settings.dart' hide AppLanguage;
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

import 'package:quickdate_app/utils/lang_controller.dart' hide AppLanguage;
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
      const MainProfileScreen(),    // Index 4: Settings
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
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.favorite), label: AppLocalizations.of(context)!.tab_match),
          BottomNavigationBarItem(icon: const Icon(Icons.trending_up), label: AppLocalizations.of(context)!.tab_trending),
          BottomNavigationBarItem(icon: const Icon(Icons.notifications), label: AppLocalizations.of(context)!.tab_alerts),
          BottomNavigationBarItem(icon: const Icon(Icons.chat), label: AppLocalizations.of(context)!.tab_chats),
          BottomNavigationBarItem(icon: const Icon(Icons.settings), label: AppLocalizations.of(context)!.tab_settings),
        ],
      ),
    );
  }
}

// ================= SETTINGS TAB =================

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

  // Save new language choice
  Future<void> _onLanguageChanged(String? value) async {
    if (value == null) return;

    final AppLanguage newLang = value == 'ar' ? AppLanguage.arabic : AppLanguage.english;

    setState(() => _currentLanguage = value);

    await LanguageChangeNotifier.instance.changeLanguage(newLang);

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      final langName = value == 'en' ? l10n.english : l10n.arabic;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.language_changed(langName),
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
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

  /// ✅ Load selected language from the language controller
  Future<void> _initLanguage() async {
    try {
      final code = LanguageChangeNotifier.instance.appLocale.languageCode;
      setState(() => _currentLanguage = (code == 'ar') ? 'ar' : 'en');
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.failed_update_online_status),
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.failed_update_profile_visibility),
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.failed_update_match_visibility),
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
        title: Text(AppLocalizations.of(context)!.help_support),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.need_help,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 10),
              Text(AppLocalizations.of(context)!.contact_email),
              SizedBox(height: 5),
              Text(AppLocalizations.of(context)!.contact_website),
              SizedBox(height: 10),
              Text(AppLocalizations.of(context)!.check_faq),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  // ✅ ABOUT - Show app version and info
  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: AppLocalizations.of(context)!.appName,
      applicationVersion: "1.0.0",
      applicationIcon: const Icon(Icons.favorite, color: Color(0xFFBF01FD), size: 48),
      children: [
        Text(AppLocalizations.of(context)!.about_tagline),
        const SizedBox(height: 10),
        Text(AppLocalizations.of(context)!.copyright),
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
              SnackBar(
                content: Text(AppLocalizations.of(context)!.account_deleted_success),
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failed_delete_account),
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
        title: Text(AppLocalizations.of(context)!.logout),
        content: Text(AppLocalizations.of(context)!.logout_confirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
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
            child: Text(AppLocalizations.of(context)!.logout),
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
        title: Text(AppLocalizations.of(context)!.clear_cache_title),
        content: Text(AppLocalizations.of(context)!.clear_cache_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context)!.delete),
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.cache_cleared_success),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("Error clearing cache: $e");
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.cache_cleared_simulated),
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.logged_out_success),
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failed_logout),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settings_title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(height: 32),
              Text(AppLocalizations.of(context)!.general,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ListTile(
                title: Text(AppLocalizations.of(context)!.my_account),
                subtitle: Text(AppLocalizations.of(context)!.my_account_sub),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _navigateTo(const MyAccountScreen()),
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.social_links),
                subtitle: Text(AppLocalizations.of(context)!.social_links_sub),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _navigateTo(const SocialLinksScreen()),
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.blocked_users),
                subtitle: Text(AppLocalizations.of(context)!.blocked_users_sub),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _navigateTo(const BlockedUsersScreen()),
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.my_affiliates),
                subtitle: Text(AppLocalizations.of(context)!.my_affiliates_sub),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _navigateTo(const MyAffiliatesScreen()),
              ),

              const Divider(height: 32),
              Text(
                AppLocalizations.of(context)!.messenger,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SwitchListTile(
                title: Text(AppLocalizations.of(context)!.show_active),
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
              Text(
                AppLocalizations.of(context)!.privacy,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              SwitchListTile(
                title: Text(AppLocalizations.of(context)!.show_profile_search),
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
                title: Text(AppLocalizations.of(context)!.show_profile_random),
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
                title: Text(AppLocalizations.of(context)!.show_profile_match),
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
                title: Text(AppLocalizations.of(context)!.confirm_friend),
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
              Text(AppLocalizations.of(context)!.security,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ListTile(
                title: Text(AppLocalizations.of(context)!.password),
                subtitle: Text(AppLocalizations.of(context)!.password_sub),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                  );
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.two_factor),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _navigateTo(const TwoFactorAuthScreen()),
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.manage_sessions),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _navigateTo(const ManageSessionsScreen()),
              ),

              const Divider(height: 32),
              Text(AppLocalizations.of(context)!.payments,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ListTile(
                title: Text(AppLocalizations.of(context)!.withdrawals),
                subtitle:
                Text(AppLocalizations.of(context)!.withdrawals_sub),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _navigateTo(const PaymentScreen()),
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.transactions),
                subtitle: Text(AppLocalizations.of(context)!.transactions_sub),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _navigateTo(const TransactionsScreen()),
              ),

              const Divider(height: 32),
              Text(AppLocalizations.of(context)!.display,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // --- THEME SELECTION ---
              ListTile(
                title: Text(AppLocalizations.of(context)!.theme),
                subtitle: Text(
                  _currentTheme == TabTheme.light
                      ? AppLocalizations.of(context)!.theme_light
                      : _currentTheme == TabTheme.dark
                      ? AppLocalizations.of(context)!.theme_dark
                      : AppLocalizations.of(context)!.theme_system,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(AppLocalizations.of(context)!.theme_select),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RadioListTile<TabTheme>(
                              title: Text(AppLocalizations.of(context)!.theme_system),
                              value: TabTheme.system,
                              groupValue: _currentTheme,
                              onChanged: (value) {
                                _onThemeChanged(value);
                                Navigator.pop(context);
                              },
                            ),
                            RadioListTile<TabTheme>(
                              title: Text(AppLocalizations.of(context)!.theme_light),
                              value: TabTheme.light,
                              groupValue: _currentTheme,
                              onChanged: (value) {
                                _onThemeChanged(value);
                                Navigator.pop(context);
                              },
                            ),
                            RadioListTile<TabTheme>(
                              title: Text(AppLocalizations.of(context)!.theme_dark),
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
                title: Text(
                  AppLocalizations.of(context)!.language,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  _currentLanguage == 'en' ? AppLocalizations.of(context)!.english : AppLocalizations.of(context)!.arabic,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(AppLocalizations.of(context)!.language),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RadioListTile<String>(
                              title: Text(AppLocalizations.of(context)!.english),
                              value: 'en',
                              groupValue: _currentLanguage,
                              onChanged: (value) {
                                _onLanguageChanged(value);
                                Navigator.pop(context);
                              },
                            ),
                            RadioListTile<String>(
                              title: Text(AppLocalizations.of(context)!.arabic),
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
              Text(
                AppLocalizations.of(context)!.storage,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ListTile(
                leading: const Icon(Icons.storage, color: Color(0xFFBF01FD)),
                title: Text(AppLocalizations.of(context)!.clear_cache),
                subtitle: Text(AppLocalizations.of(context)!.clear_cache_sub),
                trailing: const Icon(Icons.delete_sweep, color: Colors.red),
                onTap: _showClearCacheDialog,
              ),

              // ✅ NEW SUPPORT SECTION
              const Divider(height: 32),
              Text(
                AppLocalizations.of(context)!.support,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ListTile(
                leading: const Icon(Icons.help_outline, color: Color(0xFFBF01FD)),
                title: Text(AppLocalizations.of(context)!.help),
                subtitle: Text(AppLocalizations.of(context)!.help_sub),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _showHelp,
              ),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Color(0xFFBF01FD)),
                title: Text(AppLocalizations.of(context)!.about),
                subtitle: Text(AppLocalizations.of(context)!.about_sub),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _showAbout,
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: Text(AppLocalizations.of(context)!.delete_account),
                subtitle: Text(AppLocalizations.of(context)!.delete_account_sub),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _navigateTo(const DeleteAccountScreen()),  // ✅ Navigate to screen
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.orange),
                title: Text(AppLocalizations.of(context)!.logout),
                subtitle: Text(AppLocalizations.of(context)!.logout_sub),
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