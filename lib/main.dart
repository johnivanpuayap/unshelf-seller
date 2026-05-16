import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    hide ChangeNotifierProvider;
import 'package:provider/provider.dart';

import 'package:unshelf_seller/core/service_locator.dart';
import 'package:unshelf_seller/utils/theme.dart';
import 'package:unshelf_seller/viewmodels/settings_viewmodel.dart';
import 'package:unshelf_seller/views/home_view.dart';
import 'package:unshelf_seller/authentication/views/login_view.dart';
import 'package:unshelf_seller/authentication/views/reset_password_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: kIsWeb
          ? dotenv.env['FIREBASE_WEB_API_KEY']!
          : dotenv.env['FIREBASE_API_KEY']!,
      appId: kIsWeb
          ? dotenv.env['FIREBASE_WEB_APP_ID']!
          : dotenv.env['FIREBASE_APP_ID']!,
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
      projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
    ),
  );
  setupLocator();
  UnshelfTheme.preloadFonts();
  runApp(
    ProviderScope(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unshelf',
      theme: UnshelfTheme.light(),
      darkTheme: UnshelfTheme.dark(),
      themeMode: ThemeMode.system,
      home: _getInitialScreen(),
    );
  }

  /// Checks URL parameters for password-reset deep links on web,
  /// otherwise falls back to normal auth routing.
  Widget _getInitialScreen() {
    if (kIsWeb) {
      final uri = Uri.base;
      final mode = uri.queryParameters['mode'];
      final oobCode = uri.queryParameters['oobCode'];
      if (mode == 'resetPassword' && oobCode != null) {
        return ResetPasswordView(oobCode: oobCode);
      }
    }
    return FirebaseAuth.instance.currentUser != null
        ? const HomeView()
        : const LoginView();
  }
}
