import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/supabase_service.dart';
import 'router/app_router.dart';
import 'theme/chiromo_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.init();

  // TODO: PHASE 5 - FIREBASE INITIALIZATION
  // Uncomment the lines below after running `flutterfire configure`
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // await FCMService().initialize();

  runApp(const ProviderScope(child: ChiromoApp()));
}

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class ChiromoApp extends ConsumerWidget {
  const ChiromoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'Chiromo Hospital Management',
      debugShowCheckedModeBanner: false,
      theme: ChiromoTheme.lightTheme,
      darkTheme: ChiromoTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
