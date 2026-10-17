import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/providers/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/home_shell.dart';
import 'features/notifications/fcm_setup_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase config (google-services.json / GoogleService-Info.plist) isn't
  // wired up on every build — e.g. a fresh CI/test build before `flutterfire
  // configure` has been run. Push notifications just won't work until then;
  // that shouldn't take the whole app down.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase.initializeApp() failed — push notifications disabled: $e');
  }

  runApp(const ProviderScope(child: MokaApp()));
}

class MokaApp extends ConsumerWidget {
  const MokaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Register the FCM token once we have an authenticated session, not before —
    // the backend endpoint requires a bearer token.
    ref.listen(authProvider, (previous, next) {
      if (previous?.isAuthenticated != true && next.isAuthenticated) {
        FcmSetupService.initialize().catchError((e) {
          debugPrint('FCM setup skipped: $e');
        });
      }
    });

    return MaterialApp(
      title: 'Moka',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: authState.loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : (authState.isAuthenticated ? const HomeShell() : const LoginScreen()),
    );
  }
}
