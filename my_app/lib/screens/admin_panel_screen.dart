import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/attendance_service.dart';
import '../models/user.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final AttendanceService _attendanceService = AttendanceService();

  List<Map<String, dynamic>> _records = [];
  List<User> _allUsers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.loadPendingUsers();
    _allUsers = await authProvider.getAllUsers();
    await _loadAttendanceRecords();
  }

  double _profileCompleteness(User user) {
    final checks = [
      user.name.trim().isNotEmpty,
      user.email.trim().isNotEmpty,
      user.phone.trim().isNotEmpty,
      (user.identityNumber ?? '').trim().isNotEmpty,
      (user.address ?? '').trim().isNotEmpty,
      (user.familyGroup ?? '').trim().isNotEmpty,
      (user.memberCardNumber ?? '').trim().isNotEmpty,
    ];
    final score = checks.where((v) => v).length;
    return score / checks.length;
  }

  Future<void> _loadAttendanceRecords() async {
    final records = await _attendanceService.getAttendanceRecords();
    if (!mounted) {
      return;
    }

    setState(() {
      _records = records.reversed.toList();
      _loading = false;
    });
  }

  Future<void> _verify(String userId, bool approved) async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyUser(userId: userId, approved: approved);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? (approved
                ? 'Jemaat berhasil diverifikasi.'
                : 'Pendaftaran jemaat ditolak.')
            : 'Proses verifikasi gagal.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Admin'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final authProvider = context.read<AuthProvider>();
          await authProvider.loadPendingUsers();
          _allUsers = await authProvider.getAllUsers();
          await _loadAttendanceRecords();
        },
        child: Consumer<AuthProvider>(
          builder: (context, auth, child) {
            final pending = auth.pendingUsers;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verifikasi Registrasi Jemaat',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text('Menunggu verifikasi: ${pending.length} akun'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (pending.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Tidak ada registrasi yang menunggu verifikasi.'),
                    ),
                  )
                else
                  ...pending.map((user) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(user.email),
                            Text('Telepon: ${user.phone}'),
                            Text('NIK: ${user.identityNumber ?? '-'}'),
                            Text('Komunitas: ${user.familyGroup ?? '-'}'),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _verify(user.id, false),
                                    icon: const Icon(Icons.close),
                                    label: const Text('Tolak'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _verify(user.id, true),
                                    icon: const Icon(Icons.check),
                                    label: const Text('Verifikasi'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monitoring Kelengkapan Profil',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (_allUsers.isEmpty)
                          const Text('Belum ada data pengguna.')
                        else
                          ..._allUsers
                              .where((user) => user.role == 'jemaat')
                              .map((user) {
                            final pct = _profileCompleteness(user);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: Text(user.name)),
                                      Text('${(pct * 100).toStringAsFixed(0)}%'),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(value: pct),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rekap Kehadiran',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (_loading)
                          const Center(child: CircularProgressIndicator())
                        else if (_records.isEmpty)
                          const Text('Belum ada data kehadiran.')
                        else
                          ..._records.take(20).map((record) {
                            final time = DateTime.tryParse(
                                  record['timestamp']?.toString() ?? '',
                                ) ??
                                DateTime.now();

                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                '${record['memberName']} • ${record['eventName']}',
                              ),
                              subtitle: Text(
                                '${DateFormat('dd MMM yyyy HH:mm').format(time)} (${record['source']})',
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
