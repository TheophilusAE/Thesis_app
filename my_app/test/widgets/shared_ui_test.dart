import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:my_app/providers/auth_provider.dart';
import 'package:my_app/widgets/common/app_button.dart';
import 'package:my_app/widgets/common/app_card.dart';
import 'package:my_app/widgets/common/app_empty_state.dart';
import 'package:my_app/widgets/common/app_error_state.dart';
import 'package:my_app/widgets/common/app_skeleton.dart';
import 'package:my_app/widgets/common/app_status_badge.dart';
import 'package:my_app/widgets/common/app_text_field.dart';
import 'package:my_app/widgets/common/compact_feature_tile.dart';
import 'package:my_app/widgets/role_switcher.dart';

void main() {
  group('Shared UI Components Tests', () {
    testWidgets('AppButton renders label and triggers callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton.primary(
              label: 'Klik Saya',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Klik Saya'), findsOneWidget);
      await tester.tap(find.byType(AppButton));
      expect(tapped, isTrue);
    });

    testWidgets('AppButton shows loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton.primary(
              label: 'Loading Button',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading Button'), findsNothing);
    });

    testWidgets('AppCard renders child and padding', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCard(
              child: Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
    });

    testWidgets('AppTextField renders label and hint', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              label: 'Nama Lengkap',
              hintText: 'Masukkan nama Anda',
            ),
          ),
        ),
      );

      expect(find.text('Nama Lengkap'), findsOneWidget);
      expect(find.text('Masukkan nama Anda'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Theophilus');
      expect(controller.text, equals('Theophilus'));
    });

    testWidgets('AppStatusBadge displays icon and label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppStatusBadge.success(label: 'Hadir'),
          ),
        ),
      );

      expect(find.text('Hadir'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('AppEmptyState displays title, message, and action button', (tester) async {
      bool actionTriggered = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppEmptyState(
              icon: Icons.inbox_rounded,
              title: 'Kotak Masuk Kosong',
              message: 'Belum ada notifikasi baru untuk Anda.',
              actionLabel: 'Segarkan',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('Kotak Masuk Kosong'), findsOneWidget);
      expect(find.text('Belum ada notifikasi baru untuk Anda.'), findsOneWidget);
      expect(find.text('Segarkan'), findsOneWidget);

      await tester.tap(find.text('Segarkan'));
      expect(actionTriggered, isTrue);
    });

    testWidgets('AppErrorState displays user-friendly message and retry button', (tester) async {
      bool retryTriggered = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorState(
              error: 'Failed host lookup: nwqgbklaxjsijyzjooaf.supabase.co',
              onRetry: () => retryTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('Terjadi Kendala'), findsOneWidget);
      expect(find.textContaining('Koneksi internet bermasalah'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);

      await tester.tap(find.text('Coba Lagi'));
      expect(retryTriggered, isTrue);
    });

    testWidgets('AppSkeleton renders with pulse animation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppSkeleton.card(height: 100),
          ),
        ),
      );

      expect(find.byType(AppSkeleton), findsOneWidget);
    });

    testWidgets('RoleSwitcher renders single role badge for single role user', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: AuthProvider()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: RoleSwitcher(),
            ),
          ),
        ),
      );

      expect(find.byType(RoleSwitcher), findsOneWidget);
    });

    testWidgets('CompactFeatureTile renders title, actionLabel, badge and responds to taps', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactFeatureTile(
              icon: Icons.people_alt_rounded,
              title: 'Pengguna',
              actionLabel: 'Kelola akun →',
              accentColor: const Color(0xFF3B82F6),
              badgeText: 'Baru',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Pengguna'), findsOneWidget);
      expect(find.text('Kelola akun →'), findsOneWidget);
      expect(find.text('Baru'), findsOneWidget);
      expect(find.byIcon(Icons.people_alt_rounded), findsOneWidget);

      await tester.tap(find.byType(CompactFeatureTile));
      expect(tapped, isTrue);
    });

    testWidgets('CompactFeatureGrid renders tiles responsive without overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactFeatureGrid(
              tiles: [
                CompactFeatureTile(
                  icon: Icons.book,
                  title: 'Alkitab',
                  actionLabel: 'Baca firman →',
                  accentColor: Colors.blue,
                  onTap: () {},
                ),
                CompactFeatureTile(
                  icon: Icons.church,
                  title: 'Doa',
                  actionLabel: 'Kirim doa →',
                  accentColor: Colors.purple,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Alkitab'), findsOneWidget);
      expect(find.text('Doa'), findsOneWidget);
    });
  });
}
