// utils/lang_controller.dart

import 'package:flutter/material.dart';
import '../screens/main_settings.dart'; // Assuming MainSettings is here
import 'app_settings.dart'; // Assuming AppLanguage is here

class LanguageChangeNotifier extends ChangeNotifier {
  // Singleton Pattern
  static final LanguageChangeNotifier instance = LanguageChangeNotifier._();
  LanguageChangeNotifier._();

  // The state that holds the current locale
  Locale? _appLocale;

  Locale? get appLocale => _appLocale;

  // 1. Initializer: Call this once in main.dart
  Future<void> loadInitialLanguage() async {
    // Ensure MainSettings and SharedPreferences are initialized
    await MainSettings.init();

    // Get the saved language from MainSettings
    final AppLanguage savedLang = MainSettings.getLanguage();
    _appLocale = _getLocaleFromAppLanguage(savedLang);

    // Notify to set the initial locale in MaterialApp
    notifyListeners();
  }

  // 2. Changer: Call this from the SettingsTab
  Future<void> changeLanguage(AppLanguage newLang) async {
    // 1. Update global settings and save to SharedPreferences
    await MainSettings.storeLanguage(newLang);

    // 2. Update the internal locale and force MaterialApp to rebuild
    _appLocale = _getLocaleFromAppLanguage(newLang);
    notifyListeners();
  }

  // Helper to convert our custom enum to a Flutter Locale
  Locale _getLocaleFromAppLanguage(AppLanguage lang) {
    // 'en' for English (default), 'ar' for Arabic (RTL)
    return Locale(lang == AppLanguage.arabic ? 'ar' : 'en');
  }
}