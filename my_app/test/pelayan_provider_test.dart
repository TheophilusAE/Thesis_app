import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_app/providers/pelayan_provider.dart';
import 'package:my_app/services/supabase_service.dart';

class _MockService extends Mock implements SupabaseService {}

void main() {
  test('loadAllPelayan exposes an error message instead of swallowing it', () async {
    final service = _MockService();
    when(() => service.getPelayans()).thenThrow(Exception('rls'));
    final provider = PelayaniProvider(service: service);

    await provider.loadAllPelayan();

    expect(provider.errorMessage, 'Gagal memuat daftar pelayan.');
    expect(provider.allPelayan, isEmpty);
    expect(provider.isLoading, isFalse);
  });

  test('loadAllPelayan clears the error on success', () async {
    final service = _MockService();
    when(() => service.getPelayans()).thenAnswer((_) async => []);
    final provider = PelayaniProvider(service: service);

    await provider.loadAllPelayan();

    expect(provider.errorMessage, isNull);
  });

  test('id_ID date formatting works after initializeDateFormatting', () async {
    await initializeDateFormatting('id_ID');
    expect(DateFormat('MMMM', 'id_ID').format(DateTime(2026, 8, 1)), 'Agustus');
  });
}
