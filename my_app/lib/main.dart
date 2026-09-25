import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' show Intl;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/auth_provider.dart';
import 'providers/bible_provider.dart';
import 'providers/quest_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/feedback_provider.dart';
import 'providers/pelayan_provider.dart';
import 'providers/service_schedule_provider.dart';
import 'providers/training_schedule_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/substitution_request_provider.dart';
import 'providers/attendance_confirmation_provider.dart';
import 'providers/event_provider.dart';
import 'providers/komsel_provider.dart';
import 'providers/prayer_request_provider.dart';
import 'providers/sermon_provider.dart';
import 'services/local_notification_service.dart';
import 'utils/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/pending_approval_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load Indonesian date symbols once, before any DateFormat(..., 'id_ID') runs.
  await initializeDateFormatting('id_ID');
  Intl.defaultLocale = 'id_ID';

  // In release builds show a friendly placeholder instead of a raw framework
  // error; debug builds keep Flutter's red screen so real bugs stay visible.
  if (kReleaseMode) {
    ErrorWidget.builder = (details) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Terjadi kesalahan saat menampilkan halaman ini. Silakan kembali dan coba lagi.',
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
            ),
          ),
        );
  }

  // Lock to portrait, make status bar transparent on both platforms
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.light, // iOS
    statusBarIconBrightness: Brightness.dark, // Android (overridden per-screen by gradient AppBars)
  ));

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://nwqgbklaxjsijyzjooaf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im53cWdia2xheGpzaWp5empvb2FmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkwMzI5NzMsImV4cCI6MjEwNDYwODk3M30.zt3r-By6ENX3nJ4PnTQy8BxybOZaMQmsLbTQqZWxMJA',
  );
  
  await _initializeDatabaseFactory();
  await LocalNotificationService().init();
  runApp(const MyApp());
}

Future<void> _initializeDatabaseFactory() async {
  if (kIsWeb) {
    return;
  }

  if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    sqflite_ffi.sqfliteFfiInit();
    sqflite.databaseFactory = sqflite_ffi.databaseFactoryFfi;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) {
          final authProvider = AuthProvider();
          authProvider.init();
          return authProvider;
        },
      ),
      ChangeNotifierProvider(create: (_) => BibleProvider()),
      ChangeNotifierProvider(create: (_) => QuestProvider()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => FeedbackProvider()),
        // Pelayan management providers - now using SupabaseService
        ChangeNotifierProvider(create: (_) => PelayaniProvider()),
        ChangeNotifierProvider(create: (_) => ServiceScheduleProvider()),
        ChangeNotifierProvider(create: (_) => TrainingScheduleProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => SubstitutionRequestProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceConfirmationProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => PrayerRequestProvider()),
        ChangeNotifierProvider(create: (_) => KomselProvider()),
        ChangeNotifierProvider(create: (_) => SermonProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Gereja App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              final baseScale = mediaQuery.textScaler.scale(1.0);
              final effectiveScale = (baseScale * themeProvider.fontSizeFactor).clamp(0.85, 2.0);
              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.linear(effectiveScale),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
            routes: {
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
            },
            home: const _AuthGate(),
          );
        },
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  // Keep the splash visible for at least this long so it never just
  // flashes by on fast devices / warm starts.
  static const _minSplashDuration = Duration(milliseconds: 1400);
  bool _minDurationElapsed = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(_minSplashDuration, () {
      if (mounted) setState(() => _minDurationElapsed = true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<AuthProvider>().checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isInitializing || !_minDurationElapsed) {
          return const SplashScreen();
        }

        if (authProvider.blockedStatus != null) {
          return const PendingApprovalScreen();
        }

        if (authProvider.isLoggedIn) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
