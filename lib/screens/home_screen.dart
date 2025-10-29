import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'my_account_screen.dart';
import 'card_match_screen.dart';
import 'trending_screen.dart';
import 'notifications_screen.dart';
import 'chats_screen.dart';
import 'main_settings.dart'; // your settings file
import 'social_links_screen.dart';
import 'blocked_user_screen.dart';
import 'affiliate_screen.dart';
import 'withdrawal_screen.dart';
import 'transactions_screen.dart';
import 'mainprofile.dart';

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
      CardMatchScreen(),
      TrendingScreen(),
      NotificationsScreen(),
      ChatsScreen(),
      _SettingsTab(), // inline settings widget
    ];

    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    await MainSettings.init(); // Load saved settings
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
              icon: Icon(Icons.trending_up),
              label: 'Trending',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Alerts',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline Settings Tab Widget
class _SettingsTab extends StatefulWidget {
  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  TabTheme _currentTheme = AppSettings.setTabDarkTheme;
  void _navigateToProfileScreen() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) =>  MainProfileScreen(),
    ));
  }

  void _navigateToSocialLinksScreen() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SocialLinksScreen()));
  }

  void _navigateToMyAccountScreen() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const MyAccountScreen()));
  }

  // In _SettingsTabState class
  void _navigateToBlockedUsersScreen() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const BlockedUsersScreen()));
  }

  void _navigateToAffiliatesScreen() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const MyAffiliatesScreen()));
  }

  void _navigateToWithdrawalScreen() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const PaymentScreen()));
  }

  void _navigateToTransactionsScreen() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const TransactionsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 32),
                const Text(
                  "General",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ListTile(
                  title: const Text("My Account"),
                  subtitle: const Text("Manage your profile and settings"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _navigateToMyAccountScreen,
                ),
                ListTile(
                  title: const Text("Social Links"),
                  subtitle: const Text("Connect your social media accounts"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _navigateToSocialLinksScreen,
                ),
                ListTile(
                  title: const Text("Blocked Users"),
                  subtitle: const Text("Manage blocked users"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _navigateToBlockedUsersScreen,
                ),
                ListTile(
                  title: const Text("My Affiliates"),
                  subtitle: const Text(
                    "Earn up to \$X for each user you refer",
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _navigateToAffiliatesScreen,
                ),
                const Divider(height: 32),
                const Text(
                  "Payments",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ListTile(
                  title: const Text("Profile"),
                  subtitle: const Text("View your public profile"),
                  trailing: const Icon(Icons.person),
                  onTap: _navigateToProfileScreen,
                ),

                ListTile(
                  title: const Text("Withdrawals"),
                  subtitle: const Text(
                    "Withdraw your earnings via PayPal or Bank",
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _navigateToWithdrawalScreen,
                ),
                ListTile(
                  title: const Text("Transactions"),
                  subtitle: const Text("View all your transactions"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _navigateToTransactionsScreen,
                ),
                const Divider(height: 32),
                const Text(
                  "Theme Mode",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ListTile(
                  title: const Text("Light"),
                  leading: Radio<TabTheme>(
                    value: TabTheme.light,
                    groupValue: _currentTheme,
                    onChanged: _onThemeChanged,
                  ),
                ),
                ListTile(
                  title: const Text("Dark"),
                  leading: Radio<TabTheme>(
                    value: TabTheme.dark,
                    groupValue: _currentTheme,
                    onChanged: _onThemeChanged,
                  ),
                ),
                ListTile(
                  title: const Text("System Default"),
                  leading: Radio<TabTheme>(
                    value: TabTheme.system,
                    groupValue: _currentTheme,
                    onChanged: _onThemeChanged,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onThemeChanged(TabTheme? value) {
    if (value == null) return;
    setState(() {
      _currentTheme = value;
      AppSettings.setTabDarkTheme = value;
    });
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    homeState?._applyTheme();
  }
}

// New Screens for the added features
