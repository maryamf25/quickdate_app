import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/splash_screen.dart';
import 'utils/lang_controller.dart'; // Assuming this holds LanguageChangeNotifier
import 'screens/main_settings.dart';
// You will need to install flutter_localizations package for these
// import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('loginBox');
  await MainSettings.init();

  // Initialize and load the initial language setting
  await LanguageChangeNotifier.instance.loadInitialLanguage();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔑 THE FIX: Use ListenableBuilder to rebuild the MaterialApp
    // whenever LanguageChangeNotifier calls notifyListeners()
    return ListenableBuilder(
      // Listen to the singleton instance of the LanguageChangeNotifier
      listenable: LanguageChangeNotifier.instance,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          // ⚠️ IMPORTANT: Add Localization Delegates
          // If you use standard Flutter localization (intl package),
          // you must include these delegates for the UI to be translated.
          // Example (uncomment after adding dependency):
          /*
          localizationsDelegates: const [
            // GlobalMaterialLocalizations.delegate,
            // GlobalWidgetsLocalizations.delegate,
            // GlobalCupertinoLocalizations.delegate,
            // Add your generated AppLocalizations.delegate here
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('ar'), // Arabic
          ],
          */

          // 🔑 THE FIX: The locale property now changes dynamically
          locale: LanguageChangeNotifier.instance.appLocale,

          home: const SplashScreen(),
        );
      },
    );
  }
}
