import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/utils/attendance_labels.dart';

void main() {
  group('attendeeGroup', () {
    test('anyone holding the pelayan role is grouped as pelayan', () {
      expect(attendeeGroup(['jemaat', 'pelayan']), rolePelayan);
      expect(attendeeGroup(['admin', 'pelayan']), rolePelayan);
    });

    test('everyone else, including admin-only and unknown users, is jemaat', () {
      expect(attendeeGroup(['jemaat']), roleJemaat);
      expect(attendeeGroup(['admin']), roleJemaat);
      expect(attendeeGroup(null), roleJemaat);
    });

    test('labels are Indonesian', () {
      expect(attendeeGroupLabel(rolePelayan), 'Pelayan');
      expect(attendeeGroupLabel(roleJemaat), 'Jemaat');
    });
  });

  group('checkInMethodLabel', () {
    test('manual confirmation', () {
      expect(checkInMethodLabel('manual'), 'Konfirmasi manual');
    });

    test('QR without checked_in_by is a self check-in', () {
      expect(checkInMethodLabel('qr'), 'QR mandiri');
      expect(checkInMethodLabel('qr', checkedInBy: ''), 'QR mandiri');
    });

    test('QR with checked_in_by names the pelayan when known', () {
      expect(checkInMethodLabel('qr', checkedInBy: 'u1', checkerName: 'Andi'),
          'QR oleh petugas (Andi)');
      expect(checkInMethodLabel('qr', checkedInBy: 'u1'), 'QR oleh petugas');
    });
  });
}
