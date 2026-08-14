import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/supabase_service.dart';
import 'router/app_router.dart';
import 'theme/chiromo_theme.dart';
import 'features/auth/presentation/providers/security_provider.dart';

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

class ChiromoApp extends ConsumerStatefulWidget {
  const ChiromoApp({super.key});

  @override
  ConsumerState<ChiromoApp> createState() => _ChiromoAppState();
}

class _ChiromoAppState extends ConsumerState<ChiromoApp> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onStateChange: _onStateChanged,
    );
  }

  void _onStateChanged(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      ref.read(securityNotifierProvider.notifier).lockApp();
    }
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
