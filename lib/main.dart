import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'services/sync_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'utils/app_theme.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Start sync service
  await SyncService().init();
  await NotificationService().init();

  runApp(const MotoInventoryApp());
}

class MotoInventoryApp extends StatelessWidget {
  const MotoInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.notifier,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'Jajo Motorparts',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFE53935),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            textTheme:
                GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
            scaffoldBackgroundColor: const Color(0xFFF7F7F7),
            cardColor: const Color(0xFFFFFFFF),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFFFFFFF),
              elevation: 0,
              centerTitle: false,
              foregroundColor: Colors.black,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFF0F0F0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),
            navigationBarTheme: const NavigationBarThemeData(
              backgroundColor: Color(0xFFFFFFFF),
              indicatorColor: Color(0x33E53935),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFE53935),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
            scaffoldBackgroundColor: const Color(0xFF0B0B0B),
            cardColor: const Color(0xFF151515),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF151515),
              elevation: 0,
              centerTitle: false,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),
            navigationBarTheme: const NavigationBarThemeData(
              backgroundColor: Color(0xFF151515),
              indicatorColor: Color(0x33E53935),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            ),
          ),
          home: const _AuthGate(),
          routes: {
            '/dashboard': (_) => const DashboardScreen(),
            '/profile': (_) => const ProfileScreen(),
          },
        );
      },
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  final _sync = SyncService();
  bool _online = true;

  @override
  void initState() {
    super.initState();
    _online = _sync.isOnline;
    _sync.onlineStream.listen((v) {
      if (!mounted) return;
      setState(() => _online = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!_online) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.wifi_off, color: Colors.orange, size: 40),
                SizedBox(height: 12),
                Text('Connect to the internet to log in'),
              ],
            ),
          ),
        );
      }
      return const LoginScreen();
    }
    return const DashboardScreen();
  }
}
