import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TabTheme { light, dark, system }

class AppSettings {
  static TabTheme setTabDarkTheme = TabTheme.system;
  static bool showWalkThroughPage = true;

  // Toolbar & Flow
  static bool flowDirectionRightToLeft = false;

  // Banner Ad
  static bool showFbBannerAds = false;

  // Title Colors
  static Color titleTextColor = Colors.black;
  static Color titleTextColorDark = Colors.white;
}

// Swipe count details
class SwipeLimitDetails {
  int swapCount;
  DateTime lastSwapDate;

  SwipeLimitDetails({required this.swapCount, required this.lastSwapDate});

  bool canSwipe(int maxSwapLimit) {
    if (DateTime.now().difference(lastSwapDate).inDays > 0) {
      swapCount = 0;
    }
    return swapCount < maxSwapLimit;
  }

  int getSwipeCount() => swapCount;

  Map<String, dynamic> toJson() => {
    'swapCount': swapCount,
    'lastSwapDate': lastSwapDate.toIso8601String(),
  };

  factory SwipeLimitDetails.fromJson(Map<String, dynamic> json) =>
      SwipeLimitDetails(
        swapCount: json['swapCount'],
        lastSwapDate: DateTime.parse(json['lastSwapDate']),
      );
}

// Main Settings class
class MainSettings {
  static const String _lightMode = "light";
  static const String _darkMode = "dark";
  static const String _defaultMode = "default";

  static const String _showTutorialDialogKey = "SHOW_TUTORIAL_DIALOG_KEY";
  static const String _showWalkThroughPageKey = "SHOW_WALK_THROUGH_PAGE_KEY";
  static const String _swipeCountDetailsKey = "SWIPE_COUNT_DETAILS_KEY";
  static const String _nightModeKey = "Night_Mode_Key";
  static const String _flowDirectionKey = "FLOW_DIRECTION_KEY";
  static const String _showFbBannerAdsKey = "SHOW_FB_BANNER_ADS_KEY";

  static late SharedPreferences _prefs;

  // Initialize settings
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Walkthrough
    AppSettings.showWalkThroughPage = getShowWalkThroughPageValue();

    // Theme
    String? themePref = _prefs.getString(_nightModeKey) ?? _defaultMode;
    applyTheme(themePref);

    // Flow direction
    AppSettings.flowDirectionRightToLeft =
        _prefs.getBool(_flowDirectionKey) ?? false;

    // Banner ad preference
    AppSettings.showFbBannerAds = _prefs.getBool(_showFbBannerAdsKey) ?? false;
  }

  // Apply Theme
  static void applyTheme(String themePref) {
    if (themePref == _lightMode) {
      AppSettings.setTabDarkTheme = TabTheme.light;
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.light;
    } else if (themePref == _darkMode) {
      AppSettings.setTabDarkTheme = TabTheme.dark;
    } else {
      AppSettings.setTabDarkTheme = TabTheme.system;
    }
  }

  // Tutorial Dialog
  static Future<void> storeShowTutorialDialogValue(bool show) async {
    await _prefs.setBool(_showTutorialDialogKey, show);
  }

  static bool getShowTutorialDialogValue() {
    return _prefs.getBool(_showTutorialDialogKey) ?? true;
  }

  // Walkthrough Page
  static Future<void> storeShowWalkThroughPageValue(bool show) async {
    await _prefs.setBool(_showWalkThroughPageKey, show);
    AppSettings.showWalkThroughPage = show;
  }

  static bool getShowWalkThroughPageValue() {
    return _prefs.getBool(_showWalkThroughPageKey) ?? true;
  }

  // Swipe count
  static Future<void> storeSwipeCountValue(int swipeCount) async {
    final swipeDetail = SwipeLimitDetails(
      swapCount: swipeCount,
      lastSwapDate: DateTime.now(),
    );
    await _prefs.setString(
      _swipeCountDetailsKey,
      jsonEncode(swipeDetail.toJson()),
    );
  }

  static bool canSwipeMore(int maxSwapLimit) {
    final swipeJson = _prefs.getString(_swipeCountDetailsKey);
    if (swipeJson == null) return true;

    final swipeDetail = SwipeLimitDetails.fromJson(jsonDecode(swipeJson));
    return swipeDetail.canSwipe(maxSwapLimit);
  }

  static int getSwipeCountValue() {
    final swipeJson = _prefs.getString(_swipeCountDetailsKey);
    if (swipeJson == null) return 0;

    final swipeDetail = SwipeLimitDetails.fromJson(jsonDecode(swipeJson));
    return swipeDetail.getSwipeCount();
  }

  // Flow Direction
  static Future<void> storeFlowDirection(bool rtl) async {
    await _prefs.setBool(_flowDirectionKey, rtl);
    AppSettings.flowDirectionRightToLeft = rtl;
  }

  static bool getFlowDirection() => AppSettings.flowDirectionRightToLeft;

  // Banner Ads Preference
  static Future<void> storeShowFbBannerAds(bool show) async {
    await _prefs.setBool(_showFbBannerAdsKey, show);
    AppSettings.showFbBannerAds = show;
  }

  static bool getShowFbBannerAds() => AppSettings.showFbBannerAds;
}
