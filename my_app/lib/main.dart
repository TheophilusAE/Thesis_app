import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'services/pelayan_service.dart';
import 'services/attendance_confirmation_service.dart';
import 'services/service_schedule_service.dart';
import 'services/training_schedule_service.dart';
import 'services/notification_service.dart';
import 'services/notification_scheduler.dart';
import 'services/substitution_request_service.dart';
import 'utils/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

// Global instances for service initialization
late PelayaniService _pelayaniService;
late ServiceScheduleService _serviceScheduleService;
late TrainingScheduleService _trainingScheduleService;
late NotificationService _notificationService;
late NotificationScheduler _notificationScheduler;
late SubstitutionRequestService _substitutionRequestService;
late AttendanceConfirmationService _attendanceConfirmationService;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    url: 'https://fbsjdlsrxkcucspaqgfm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZic2pkbHNyeGtjdWNzcGFxZ2ZtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk3MzE0NTEsImV4cCI6MjA5NTMwNzQ1MX0.pX9LhGIOYL1lmL3iwYC7-y4vMY9sLucXJb0Nv7W5Xi0',
  );
  
  await _initializeDatabaseFactory();
  await _initializeServices();
  runApp(const MyApp());
}

Future<void> _initializeServices() async {
  _pelayaniService = PelayaniService();
  _serviceScheduleService = ServiceScheduleService();
  _trainingScheduleService = TrainingScheduleService();
  _notificationService = NotificationService();
  _substitutionRequestService = SubstitutionRequestService();
  _attendanceConfirmationService = AttendanceConfirmationService();
  _notificationScheduler = NotificationScheduler(
    serviceScheduleService: _serviceScheduleService,
    trainingScheduleService: _trainingScheduleService,
    notificationService: _notificationService,
  );

  await _pelayaniService.init();
  await _serviceScheduleService.init();
  await _trainingScheduleService.init();
  await _notificationService.init();
  await _substitutionRequestService.init();
  await _attendanceConfirmationService.init();
  await _notificationScheduler.init();
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
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Gereja App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
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
  @override
  void initState() {
    super.initState();
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
        if (authProvider.isInitializing) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authProvider.isLoggedIn) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
