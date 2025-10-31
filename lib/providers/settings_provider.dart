// import 'package:flutter/cupertino.dart';
//
// import '../models/settings.dart';
//
// class SettingsProvider extends ChangeNotifier {
//   Settings? _settings;
//   bool get isEmailVerificationEnabled =>
//       _settings?.verificationOnSignup == "1" &&
//           _settings?.emailValidation == "1";
//
//   Future<void> loadSettings() async {
//     // Load settings from SQLite database
//     try {
//       final db = await DatabaseHelper.instance.database;
//       final List<Map<String, dynamic>> settings =
//       await db.query('SettingsTb');
//
//       if (settings.isNotEmpty) {
//         _settings = Settings.fromJson(settings.first);
//         notifyListeners();
//       }
//     } catch (e) {
//       print('Error loading settings: $e');
//     }
//   }
// }