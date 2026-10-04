import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexifold/features/auth/auth_screen.dart';
import 'package:lexifold/features/auth/signup_waiting_verify_screen.dart';
import 'package:lexifold/features/auth/reset_password_screen.dart';
import 'package:lexifold/features/common/splash_screen.dart';
import 'package:lexifold/features/main/library/screens/crud_study_set/add_or_update_set_screen.dart';
import 'package:lexifold/features/main/main_screen.dart';
import 'package:lexifold/providers/sync_manager/sync_manager.dart';
import 'package:lexifold/utils/theme_utils.dart';
import 'package:lexifold/utils/routes_name.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ProviderScope(
      child: MaterialApp(
        navigatorKey: navigatorKey,

        //routes
        routes: {
          RoutesName.verifySignUp: (context) =>
              const SignupWaitingVerifyScreen(),
          RoutesName.resetPassword: (context) =>
              const ResetPasswordScreen(),
          RoutesName.authScreen: (context) => const AuthScreen(),
          RoutesName.mainScreen: (context) => const MainScreen(),
          RoutesName.addOrUpdateSetScreen: (context) =>
              const AddOrUpdateSetScreen(),
        },

        locale: const Locale("vi"),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,

        theme: ThemeUtils.lightTheme,
        darkTheme: ThemeUtils.darkTheme,
        themeMode: ThemeMode.system,
        home: const LexiFoldApp(),
      ),
    ),
  );
}

class LexiFoldApp extends ConsumerWidget {
  const LexiFoldApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(syncManagerProvider, (previous, next) {
      next.whenData((syncState) {
        if (syncState != null && syncState.lastErr != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi đồng bộ: ${syncState.lastErr}'),
            ),
          );
        }
      });
    });

    return const SplashScreen();
  }
}
