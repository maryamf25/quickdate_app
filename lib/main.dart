import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/session_manager.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'utils/lang_controller.dart';
import 'screens/main_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Hive once
  await Hive.initFlutter();

  // ✅ Open the Hive box before using it anywhere
  await Hive.openBox('loginBox');

  // ✅ Initialize app settings
  await MainSettings.init();

  // ✅ Load saved language before app starts
  await LanguageChangeNotifier.instance.loadInitialLanguage();

  // ✅ Determine initial login state before runApp
  bool isLoggedIn = await SessionManager.isLoggedIn();

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, this.isLoggedIn = false});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageChangeNotifier.instance,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: LanguageChangeNotifier.instance.appLocale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // Directionality and formatting handled by localization delegates
          // ✅ Decide initial screen based on session
          home: isLoggedIn ? const HomeScreen() : const SplashScreen(),
        );
      },
    );
  }
}
