import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { english, arabic }

class LanguageChangeNotifier extends ChangeNotifier {
  LanguageChangeNotifier._();

  static final LanguageChangeNotifier instance = LanguageChangeNotifier._();

  static const String _prefsKey = 'app_language';

  Locale _locale = const Locale('en');

  Locale get appLocale => _locale;

  Future<void> loadInitialLanguage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedCode = prefs.getString(_prefsKey);
    final String code = savedCode ?? _deviceFallbackCode();
    _locale = Locale(code);
    notifyListeners();
  }

  Future<void> changeLanguage(AppLanguage language) async {
    final String code = language == AppLanguage.arabic ? 'ar' : 'en';
    if (_locale.languageCode == code) return;
    _locale = Locale(code);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, code);
    notifyListeners();
  }

  String _deviceFallbackCode() {
    final Locale deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final String lc = deviceLocale.languageCode.toLowerCase();
    switch (lc) {
      case 'ar':
        return 'ar';
      default:
        return 'en';
    }
  }
}


