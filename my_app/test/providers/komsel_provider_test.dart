import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_app/models/komsel.dart';
import 'package:my_app/providers/komsel_provider.dart';
import 'package:my_app/services/supabase_service.dart';

class MockSupabaseService extends Mock implements SupabaseService {}

void main() {
  late MockSupabaseService mockService;
  late KomselProvider provider;

  setUp(() {
    mockService = MockSupabaseService();
    provider = KomselProvider(service: mockService);
  });

  test('loadActiveKomsel populates activeKomsel from the service', () async {
    when(() => mockService.getActiveKomsels()).thenAnswer((_) async => [
          {'id': 'k1', 'nama': 'Komsel A', 'is_active': true, 'created_at': '2026-01-01T00:00:00.000Z'},
        ]);

    await provider.loadActiveKomsel();

    expect(provider.activeKomsel, hasLength(1));
    expect(provider.activeKomsel.first.nama, 'Komsel A');
  });

  test('addKomsel inserts the created row at the front of allKomsel', () async {
    when(() => mockService.addKomsel(any())).thenAnswer((invocation) async {
      final data = invocation.positionalArguments.first as Map<String, dynamic>;
      return {'id': 'k2', 'created_at': '2026-01-02T00:00:00.000Z', ...data};
    });

    final komsel = Komsel(id: '', nama: 'Komsel B', createdAt: DateTime.now());
    final success = await provider.addKomsel(komsel);

    expect(success, isTrue);
    expect(provider.allKomsel, hasLength(1));
    expect(provider.allKomsel.first.nama, 'Komsel B');
  });

  test('deleteKomsel removes the komsel from both lists', () async {
    when(() => mockService.getKomsels()).thenAnswer((_) async => [
          {'id': 'k3', 'nama': 'Komsel C', 'created_at': '2026-01-01T00:00:00.000Z'},
        ]);
    when(() => mockService.deleteKomsel(any())).thenAnswer((_) async {});

    await provider.loadAllKomsel();
    final success = await provider.deleteKomsel('k3');

    expect(success, isTrue);
    expect(provider.allKomsel, isEmpty);
  });
}
