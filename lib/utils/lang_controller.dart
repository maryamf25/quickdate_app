import 'dart:ui';
import 'package:flutter/material.dart';
import 'user_details.dart';
import 'app_settings.dart';

class LangController {
  static Future<void> setApplicationLang(BuildContext context, String language) async {
    try {
      Locale locale = Locale(language);
      AppSettings.lang = language;
      AppSettings.flowDirectionRightToLeft = language.contains('ar');

      // Save user language globally
      UserDetails.langName = language;

      // Set text direction for MaterialApp dynamically
      // (You can also use a state management solution to trigger rebuild)
    } catch (e) {
      debugPrint("LangController error: $e");
    }
  }
}
