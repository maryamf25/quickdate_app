import 'package:flutter/material.dart';

enum ShowAds { AllUsers, None }
enum TabTheme { Light, Dark }
enum BackgroundTheme { Image, Color }
enum UpdateGenderSystem { JustWhenRegister, Always }
enum PaymentsSystem { All, None }

class AppSettings {
  // Main Settings
  static String version = "2.9";
  static const String applicationName = "QuickDate";
  static const String databaseName = "QuickDate";

  // Colors
  static const String mainColor = "#FF007F";
  static Color titleTextColor = Colors.black;
  static Color titleTextColorDark = Colors.white;

  // Language
  static bool flowDirectionRightToLeft = true;
  static String lang = "";

  // Notifications
  static bool showNotification = true;
  static const String oneSignalAppId = "c6d8ecf6-e3b8-4c49-b208-07a23364a6ed";

  // Ads
  static ShowAds showAds = ShowAds.AllUsers;
  static int showAdInterstitialCount = 5;
  static int showAdRewardedVideoCount = 5;
  static int showAdNativeCount = 40;
  static int showAdAppOpenCount = 3;

  // Other
  static bool registerEnabled = true;
  static bool premiumSystemEnabled = true;
}
