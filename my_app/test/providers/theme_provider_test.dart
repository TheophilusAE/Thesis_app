import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/providers/auth_provider.dart';
import 'package:my_app/providers/checkin_provider.dart';
import 'package:my_app/providers/theme_provider.dart';
import 'package:my_app/screens/qr_shortcut_screen.dart';
import 'package:my_app/services/supabase_service.dart';
import 'package:my_app/utils/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class _MockService extends Mock implements SupabaseService {}

/// A const widget reading AppTheme tokens: const subtrees are skipped by a
/// normal rebuild, so this proves the theme switch reaches them too.
class _Probe extends StatelessWidget {
  const _Probe();

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('probe'),
        color: AppTheme.surface,
        child: Text('x', style: TextStyle(color: AppTheme.darkCharcoal)),
      );
}

Widget _app(ThemeProvider theme, Widget home) => ChangeNotifierProvider.value(
      value: theme,
      child: Consumer<ThemeProvider>(
        builder: (_, tp, _) => MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: tp.themeMode,
          home: home,
        ),
      ),
    );

Color? _probeColor(WidgetTester tester) =>
    (tester.widget<Container>(find.byKey(const ValueKey('probe'))).color);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => AppTheme.setDark(false));

  test('tokens resolve to the light or dark palette', () {
    AppTheme.setDark(false);
    expect(AppTheme.surface, Colors.white);
    expect(AppTheme.background, const Color(0xFFFFFDF8));
    expect(AppTheme.primary, const Color(0xFFA62639));

    AppTheme.setDark(true);
    expect(AppTheme.surface, const Color(0xFF1E1C1F));
    expect(AppTheme.background, const Color(0xFF141214));
    expect(AppTheme.darkCharcoal, const Color(0xFFF5F3F6));
    expect(AppTheme.primary, isNot(const Color(0xFFA62639)));
    // Brand fills used under white text keep their fixed tone.
    expect(AppTheme.primaryDark, const Color(0xFF7D1D2B));
  });

  testWidgets('switching to dark repaints const subtrees and is remembered', (tester) async {
    final theme = ThemeProvider();
    await tester.pumpWidget(_app(theme, const Scaffold(body: _Probe())));
    await tester.pumpAndSettle();
    expect(_probeColor(tester), Colors.white);

    await theme.setThemeMode(ThemeMode.dark);
    await tester.pumpAndSettle();
    expect(AppTheme.isDark, isTrue);
    expect(_probeColor(tester), const Color(0xFF1E1C1F));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_theme_mode'), ThemeMode.dark.toString());

    theme.toggleTheme();
    await tester.pumpAndSettle();
    expect(AppTheme.isDark, isFalse);
    expect(_probeColor(tester), Colors.white);
  });

  testWidgets('the saved dark choice is applied on start', (tester) async {
    SharedPreferences.setMockInitialValues({'app_theme_mode': ThemeMode.dark.toString()});
    final theme = ThemeProvider();
    await tester.pumpWidget(_app(theme, const Scaffold(body: _Probe())));
    await tester.pumpAndSettle();
    expect(theme.themeMode, ThemeMode.dark);
    expect(_probeColor(tester), const Color(0xFF1E1C1F));
  });

  testWidgets('the QR stays dark-on-white in dark mode', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final service = _MockService();
    when(() => service.getCurrentUser()).thenReturn(const sb.User(
      id: 'u1',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: '2026-01-01T00:00:00Z',
    ));
    when(() => service.getUserProfile('u1')).thenAnswer((_) async => {
          'id': 'u1',
          'nama': 'Rina',
          'email': 'rina@example.com',
          'phone': '0813',
          'roles': ['jemaat'],
          'membership_status': 'active',
        });
    when(() => service.getMyAdminPermissions('u1')).thenAnswer((_) async => []);
    when(() => service.getMyMemberQrSecret()).thenAnswer((_) async => 'sec');
    final auth = AuthProvider(service: service);
    await auth.checkAuthStatus();

    SharedPreferences.setMockInitialValues({'app_theme_mode': ThemeMode.dark.toString()});
    final theme = ThemeProvider();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => CheckinProvider(service: service)),
      ],
      child: _app(
        theme,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(onPressed: () => showQrAccessSheet(context), child: const Text('qr')),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(AppTheme.isDark, isTrue);
    await tester.tap(find.text('qr'));
    await tester.pumpAndSettle();

    expect(find.text('QR Saya'), findsOneWidget);
    final whiteBoxes = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) => c.decoration is BoxDecoration && (c.decoration as BoxDecoration).color == Colors.white);
    expect(whiteBoxes, isNotEmpty, reason: 'QR frame must keep its white background');
  });
}
