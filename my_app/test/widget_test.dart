import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_app/main.dart';

void main() {
  testWidgets('App opens login screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Selamat Datang'), findsOneWidget);
    expect(find.text('Masuk ke komunitas kami'), findsOneWidget);
  });
}
