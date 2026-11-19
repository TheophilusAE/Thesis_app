import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/devotional.dart';
import '../models/event.dart';
import '../models/event_registration.dart';
import '../providers/group_provider.dart';
import '../utils/qr_payload.dart';
import '../utils/youtube_url.dart';
import 'checkin_qr_display_screen.dart';
import '../models/reading_quest.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../services/devotional_service.dart';
import '../services/event_service.dart';
import '../services/quest_service.dart';
import 'admin_substitution_review_screen.dart';
import 'admin_attendance_monitoring_screen.dart';
import 'feedback_management_screen.dart';
import 'pelayan_management_screen.dart';
import 'role_management_screen.dart';
import 'service_schedule_management_screen.dart';
import 'training_schedule_management_screen.dart';
import '../utils/app_theme.dart';
import '../utils/permissions.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  final DevotionalService _devotionalService = DevotionalService();
  final QuestService _questService = QuestService();
  final TextEditingController _userSearchController = TextEditingController();
  final TextEditingController _devotionalSearchController = TextEditingController();
  final TextEditingController _questSearchController = TextEditingController();
  final TextEditingController _dailyTargetController = TextEditingController();

  List<User> _users = [];
  List<Devotional> _devotionals = [];
  List<ReadingQuest> _quests = [];
  bool _loading = true;
  String _userFilter = 'all';
  String _devotionalQuery = '';
  String _questQuery = '';

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _userSearchController.addListener(() {
      setState(() {});
    });
    _devotionalSearchController.addListener(() {
      setState(() {
        _devotionalQuery = _devotionalSearchController.text.trim().toLowerCase();
      });
    });
    _questSearchController.addListener(() {
      setState(() {
        _questQuery = _questSearchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _userSearchController.dispose();
    _devotionalSearchController.dispose();
    _questSearchController.dispose();
    _dailyTargetController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final authProvider = context.read<AuthProvider>();
    final loadedUsers = await authProvider.getAllUsers();
    final loadedDevotionals = await _devotionalService.getAllDevotionals();
    final loadedQuests = await _questService.getManagedPlan();
    final target = await _questService.getDailyReadingTarget();

    if (!mounted) {
      return;
    }

    setState(() {
      _users = loadedUsers;
      _devotionals = loadedDevotionals;
      _quests = loadedQuests;
      _dailyTargetController.text = target.toString();
      _loading = false;
    });

    if (loadedUsers.isEmpty && authProvider.lastMessage != null) {
      _showLoadError(authProvider.lastMessage!);
    }
  }

  Future<void> _reloadAll() async {
    final authProvider = context.read<AuthProvider>();
    final loadedUsers = await authProvider.getAllUsers();
    final loadedDevotionals = await _devotionalService.getAllDevotionals();
    final loadedQuests = await _questService.getManagedPlan();
    final target = await _questService.getDailyReadingTarget();

    if (!mounted) {
      return;
    }

    setState(() {
      _users = loadedUsers;
      _devotionals = loadedDevotionals;
      _quests = loadedQuests;
      _dailyTargetController.text = target.toString();
    });

    if (loadedUsers.isEmpty && authProvider.lastMessage != null) {
      _showLoadError(authProvider.lastMessage!);
    }
  }

  void _showLoadError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gagal memuat data pengguna: $message'),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 6),
      ),
    );
  }

  List<User> get _filteredUsers {
    final query = _userSearchController.text.trim().toLowerCase();
    return _users.where((user) {
      final matchesFilter = switch (_userFilter) {
        'admin' => user.hasRole('admin'),
        'pelayan' => user.hasRole('pelayan'),
        'jemaat' => user.hasRole('jemaat'),
        'pending' => user.membershipStatus == 'pending',
        'verified' => user.membershipStatus == 'active',
        _ => true,
      };

      final searchTarget = [
        user.name,
        user.email,
        user.phone,
        user.identityNumber ?? '',
        user.membershipType ?? '',
        user.address ?? '',
        user.memberCardNumber ?? '',
      ].join(' ').toLowerCase();

      return matchesFilter && (query.isEmpty || searchTarget.contains(query));
    }).toList();
  }

  List<Devotional> get _filteredDevotionals {
    if (_devotionalQuery.isEmpty) {
      return _devotionals;
    }

    return _devotionals.where((devotional) {
      final searchable = [
        devotional.title,
        devotional.content,
        devotional.verse,
        devotional.verseReference,
        devotional.author ?? '',
      ].join(' ').toLowerCase();
      return searchable.contains(_devotionalQuery);
    }).toList();
  }

  List<ReadingQuest> get _filteredQuests {
    if (_questQuery.isEmpty) {
      return _quests;
    }

    return _quests.where((quest) {
      final searchable = [
        quest.day.toString(),
        quest.readings.map((reading) => reading.displayText).join(' '),
      ].join(' ').toLowerCase();
      return searchable.contains(_questQuery);
    }).toList();
  }

  Future<void> _confirmDelete({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      onConfirm();
    }
  }

  /// Approve or reject a pending member via the permission-checked RPC and
  /// tell the admin what happened (a refusal is no longer silent).
  Future<void> _setMemberStatus(User user, {required bool approved}) async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyUser(userId: user.id, approved: approved);
    if (ok) {
      await _reloadAll();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? (approved ? '${user.name} disetujui.' : '${user.name} ditolak.')
            : 'Gagal: ${auth.lastMessage ?? 'periksa koneksi lalu coba lagi.'}'),
      ),
    );
  }

  Future<void> _showUserDialog({User? existingUser}) async {
    final nameController = TextEditingController(text: existingUser?.name ?? '');
    final emailController = TextEditingController(text: existingUser?.email ?? '');
    final phoneController = TextEditingController(text: existingUser?.phone ?? '');
    final passwordController = TextEditingController();
    final identityController = TextEditingController(text: existingUser?.identityNumber ?? '');
    final membershipTypeController = TextEditingController(text: existingUser?.membershipType ?? '');
    final memberCardController = TextEditingController(text: existingUser?.memberCardNumber ?? '');
    final addressController = TextEditingController(text: existingUser?.address ?? '');
    final memberSinceController = TextEditingController(text: existingUser?.memberSince ?? '');
    final baptismController = TextEditingController(text: existingUser?.baptismDate ?? '');
    // Copy: never mutate the loaded user's role list in place.
    final List<String> selectedRoles = List<String>.of(existingUser?.roles ?? const ['jemaat']);
    // Normalize legacy 'verified' value (DB uses 'active')
    final rawStatus = existingUser?.membershipStatus ?? 'pending';
    String membershipStatus = rawStatus == 'verified' ? 'active' : rawStatus;
    final isMobile = MediaQuery.of(context).size.width < 700;
    final auth = context.read<AuthProvider>();
    // Only a Super Admin may grant the admin role (DB-enforced as well).
    final canGrantAdmin = auth.isSuperAdmin;
    // Status options mirror the server rules: a new account made by an Admin
    // starts pending unless they hold users:approve; editing an existing
    // account (Super Admin only) may set any status.
    final statusItems = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: 'pending', child: Text('Pending')),
      if (existingUser != null || auth.can(AppModule.users, PermissionAction.approve))
        const DropdownMenuItem(value: 'active', child: Text('Active')),
      if (existingUser != null) ...const [
        DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
        DropdownMenuItem(value: 'inactive', child: Text('Nonaktif')),
      ],
    ];
    if (!statusItems.any((i) => i.value == membershipStatus)) {
      membershipStatus = 'pending';
    }

    Widget formFields(void Function(VoidCallback fn) setDialogState) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dialogSectionTitle('Akun'),
          const SizedBox(height: 8),
          _dialogTextField(controller: nameController, label: 'Nama'),
          _dialogTextField(controller: emailController, label: 'Email'),
          _dialogTextField(controller: phoneController, label: 'Telepon'),
          if (existingUser == null)
            _dialogTextField(
              controller: passwordController,
              label: 'Password',
              obscureText: true,
            ),
          _dialogSectionTitle('Role'),
          const SizedBox(height: 8),
          Column(
            children: [
              CheckboxListTile(
                title: const Text('Jemaat'),
                value: selectedRoles.contains('jemaat'),
                onChanged: (value) {
                  setDialogState(() {
                    if (value == true) {
                      if (!selectedRoles.contains('jemaat')) selectedRoles.add('jemaat');
                    } else {
                      selectedRoles.remove('jemaat');
                    }
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Pelayan'),
                value: selectedRoles.contains('pelayan'),
                onChanged: (value) {
                  setDialogState(() {
                    if (value == true) {
                      if (!selectedRoles.contains('pelayan')) selectedRoles.add('pelayan');
                    } else {
                      selectedRoles.remove('pelayan');
                    }
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              if (canGrantAdmin)
                CheckboxListTile(
                  title: const Text('Admin'),
                  subtitle: const Text('Atur izin modulnya di Kelola Admin & Izin'),
                  value: selectedRoles.contains('admin'),
                  onChanged: (value) {
                    setDialogState(() {
                      if (value == true) {
                        if (!selectedRoles.contains('admin')) selectedRoles.add('admin');
                      } else {
                        selectedRoles.remove('admin');
                      }
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
          const SizedBox(height: 6),
          _dialogDropdownField<String>(
            label: 'Status Keanggotaan',
            value: membershipStatus,
            items: statusItems,
            onChanged: (value) {
              if (value != null) {
                setDialogState(() {
                  membershipStatus = value;
                });
              }
            },
          ),
          const SizedBox(height: 6),
          _dialogSectionTitle('Profil Tambahan'),
          const SizedBox(height: 8),
          _dialogTextField(controller: identityController, label: 'NIK'),
          _dialogTextField(
            controller: membershipTypeController,
            label: 'Tipe Keanggotaan',
          ),
          _dialogTextField(
            controller: memberCardController,
            label: 'Nomor Kartu Anggota',
          ),
          _dialogTextField(controller: addressController, label: 'Alamat', maxLines: 2),
          _dialogTextField(
            controller: memberSinceController,
            label: 'Member Sejak (yyyy-MM-dd)',
          ),
          _dialogTextField(controller: baptismController, label: 'Tanggal Baptis'),
        ],
      );
    }

    User buildResultUser() {
      return User(
        id: existingUser?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        roles: selectedRoles.isEmpty ? ['jemaat'] : selectedRoles,
        membershipStatus: membershipStatus,
        identityNumber: identityController.text.trim().isEmpty ? null : identityController.text.trim(),
        // family_group is no longer edited (replaced by the member's Group);
        // existing values are carried through unchanged.
        familyGroup: existingUser?.familyGroup,
        groupId: existingUser?.groupId,
        membershipType: membershipTypeController.text.trim().isEmpty ? null : membershipTypeController.text.trim(),
        memberCardNumber: memberCardController.text.trim().isEmpty ? null : memberCardController.text.trim(),
        address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
        memberSince: memberSinceController.text.trim().isEmpty ? null : memberSinceController.text.trim(),
        baptismDate: baptismController.text.trim().isEmpty ? null : baptismController.text.trim(),
      );
    }
    final User? result;
    if (isMobile) {
      result = await showModalBottomSheet<User?>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.92,
                minChildSize: 0.7,
                maxChildSize: 0.98,
                builder: (context, scrollController) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 10, 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                existingUser == null ? 'Tambah User' : 'Edit User',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                          child: formFields(setDialogState),
                        ),
                      ),
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(sheetContext),
                                  child: const Text('Batal'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(sheetContext, buildResultUser()),
                                  child: const Text('Simpan'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      );
    } else {
      result = await showDialog<User?>(
        context: context,
        builder: (dialogContext) {
          final maxDialogHeight = MediaQuery.of(dialogContext).size.height * 0.72;
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                title: Text(existingUser == null ? 'Tambah User' : 'Edit User'),
                content: SizedBox(
                  width: 520,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxDialogHeight),
                    child: SingleChildScrollView(
                      child: formFields(setDialogState),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext, buildResultUser()),
                    child: const Text('Simpan'),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    if (result == null) {
      return;
    }

    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    final success = existingUser == null
        ? await authProvider.createUser(
            name: result.name,
            email: result.email,
            phone: result.phone,
            password: passwordController.text.trim(),
            roles: result.roles,
            identityNumber: result.identityNumber,
            familyGroup: result.familyGroup,
            membershipType: result.membershipType,
            address: result.address,
            memberCardNumber: result.memberCardNumber,
            memberSince: result.memberSince,
            baptismDate: result.baptismDate,
            membershipStatus: result.membershipStatus,
          )
        : await authProvider.updateUser(result);

    if (success) {
      await _reloadAll();
    }

    if (!mounted) {
      return;
    }

    final errMsg = authProvider.lastMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success
          ? 'Data user tersimpan.'
          : 'Gagal menyimpan user.${errMsg != null ? " ($errMsg)" : ""}')),
    );
  }

  Future<void> _showDevotionalDialog({Devotional? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final verseController = TextEditingController(text: existing?.verse ?? '');
    final verseRefController = TextEditingController(text: existing?.verseReference ?? '');
    final contentController = TextEditingController(text: existing?.content ?? '');
    final authorController = TextEditingController(text: existing?.author ?? '');
    final dateController = TextEditingController(
      text: existing?.date.toIso8601String().substring(0, 10) ?? DateTime.now().toIso8601String().substring(0, 10),
    );
    final isMobile = MediaQuery.of(context).size.width < 700;

    Widget formFields() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dialogSectionTitle('Konten Renungan'),
          const SizedBox(height: 8),
          _dialogTextField(controller: titleController, label: 'Judul'),
          _dialogTextField(controller: verseRefController, label: 'Referensi Ayat'),
          _dialogTextField(controller: verseController, label: 'Ayat', maxLines: 3),
          _dialogTextField(controller: contentController, label: 'Isi Renungan', maxLines: 6),
          const SizedBox(height: 6),
          _dialogSectionTitle('Meta Data'),
          const SizedBox(height: 8),
          _dialogTextField(controller: authorController, label: 'Penulis'),
          _dialogTextField(controller: dateController, label: 'Tanggal (yyyy-MM-dd)'),
        ],
      );
    }

    Devotional buildResultDevotional() {
      final parsedDate = DateTime.tryParse(dateController.text.trim()) ??
          existing?.date ??
          DateTime.now();
      return Devotional(
        id: existing?.id ?? 'dev-${DateTime.now().millisecondsSinceEpoch}',
        title: titleController.text.trim(),
        content: contentController.text.trim(),
        verse: verseController.text.trim(),
        verseReference: verseRefController.text.trim(),
        date: parsedDate,
        author: authorController.text.trim().isEmpty ? null : authorController.text.trim(),
      );
    }
    final Devotional? result;
    if (isMobile) {
      result = await showModalBottomSheet<Devotional?>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.9,
            minChildSize: 0.68,
            maxChildSize: 0.98,
            builder: (context, scrollController) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 10, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            existing == null ? 'Tambah Renungan' : 'Edit Renungan',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: formFields(),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              child: const Text('Batal'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(sheetContext, buildResultDevotional()),
                              child: const Text('Simpan'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } else {
      result = await showDialog<Devotional?>(
        context: context,
        builder: (dialogContext) {
          final maxDialogHeight = MediaQuery.of(dialogContext).size.height * 0.72;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            title: Text(existing == null ? 'Tambah Renungan' : 'Edit Renungan'),
            content: SizedBox(
              width: 520,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxDialogHeight),
                child: SingleChildScrollView(
                  child: formFields(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, buildResultDevotional()),
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      );
    }

    if (result == null) {
      return;
    }

    final success = existing == null
        ? await _devotionalService.addDevotional(
            title: result.title,
            content: result.content,
            verse: result.verse,
            verseReference: result.verseReference,
            date: result.date,
            author: result.author ?? 'Admin',
          )
        : await _devotionalService.updateDevotional(result);

    if (success) {
      await _reloadAll();
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Renungan tersimpan.' : 'Gagal menyimpan renungan.')),
    );
  }

  Future<void> _showQuestDialog({ReadingQuest? existing}) async {
    final dayController = TextEditingController(text: existing?.day.toString() ?? '');
    final bookController = TextEditingController(text: existing?.readings.isNotEmpty == true ? existing!.readings.first.book : '');
    final startController = TextEditingController(text: existing?.readings.isNotEmpty == true ? existing!.readings.first.startChapter.toString() : '');
    final endController = TextEditingController(text: existing?.readings.isNotEmpty == true ? existing!.readings.first.endChapter.toString() : '');
    final isMobile = MediaQuery.of(context).size.width < 700;

    Widget formFields() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dialogTextField(
            controller: dayController,
            label: 'Hari ke-',
            keyboardType: TextInputType.number,
          ),
          _dialogTextField(controller: bookController, label: 'Buku'),
          _dialogTextField(
            controller: startController,
            label: 'Pasal Mulai',
            keyboardType: TextInputType.number,
          ),
          _dialogTextField(
            controller: endController,
            label: 'Pasal Selesai',
            keyboardType: TextInputType.number,
          ),
        ],
      );
    }

    ReadingQuest? buildResultQuest() {
      final day = int.tryParse(dayController.text.trim());
      final start = int.tryParse(startController.text.trim());
      final end = int.tryParse(endController.text.trim());

      if (day == null || start == null || end == null || bookController.text.trim().isEmpty) {
        return null;
      }

      return ReadingQuest(
        day: day,
        readings: [
          ReadingPlan(
            book: bookController.text.trim(),
            startChapter: start,
            endChapter: end,
          ),
        ],
      );
    }
    final ReadingQuest? result;
    if (isMobile) {
      result = await showModalBottomSheet<ReadingQuest?>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.86,
            minChildSize: 0.62,
            maxChildSize: 0.98,
            builder: (context, scrollController) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 10, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            existing == null ? 'Tambah Quest Baca' : 'Edit Quest Baca',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: formFields(),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              child: const Text('Batal'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(sheetContext, buildResultQuest()),
                              child: const Text('Simpan'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } else {
      result = await showDialog<ReadingQuest?>(
        context: context,
        builder: (dialogContext) {
          final maxDialogHeight = MediaQuery.of(dialogContext).size.height * 0.68;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            title: Text(existing == null ? 'Tambah Quest Baca' : 'Edit Quest Baca'),
            content: SizedBox(
              width: 460,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxDialogHeight),
                child: SingleChildScrollView(
                  child: formFields(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, buildResultQuest()),
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      );
    }

    if (result == null) {
      return;
    }

    final success = existing == null
        ? await _questService.addReadingQuest(result)
        : await _questService.updateReadingQuest(existing.day, result);

    if (success) {
      await _reloadAll();
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Quest tersimpan.' : 'Gagal menyimpan quest.')),
    );
  }

  String _devotionalSubtitle(Devotional devotional) {
    final date = DateFormat('dd MMM yyyy').format(devotional.date);
    final author = devotional.author == null || devotional.author!.isEmpty ? '' : ' • ${devotional.author}';
    return '$date$author';
  }

  String _questSubtitle(ReadingQuest quest) {
    return quest.readings.map((reading) => reading.displayText).join(', ');
  }

  /// Tabs this account may open. Each tab is listed only when the admin holds
  /// read/create/approve on its module; "Role" is Super Admin only. The
  /// embedded screens and the database apply the same checks again.
  List<({String label, Widget Function() build})> _visibleTabs(AuthProvider auth) {
    final tabs = <({String label, String? module, bool superOnly, Widget Function() build})>[
      (label: 'User', module: AppModule.users, superOnly: false, build: _buildUserTab),
      (label: 'Role', module: null, superOnly: true, build: () => const RoleManagementScreen()),
      (label: 'Renungan', module: AppModule.renungan, superOnly: false, build: _buildDevotionalTab),
      (label: 'Quest Baca', module: AppModule.quest, superOnly: false, build: _buildQuestTab),
      (label: 'Feedback', module: AppModule.feedback, superOnly: false,
          build: () => const FeedbackManagementScreen()),
      (label: 'Pelayan', module: AppModule.pelayan, superOnly: false,
          build: () => const PelayaniManagementScreen()),
      (label: 'Jadwal Ibadah', module: AppModule.jadwalPelayanan, superOnly: false,
          build: () => const ServiceScheduleManagementScreen()),
      (label: 'Jadwal Latihan', module: AppModule.jadwalPelayanan, superOnly: false,
          build: () => const TrainingScheduleManagementScreen()),
      (label: 'Substitusi', module: AppModule.jadwalPelayanan, superOnly: false,
          build: () => const AdminSubstitutionReviewScreen()),
      (label: 'Kehadiran', module: AppModule.kehadiran, superOnly: false,
          build: () => const AdminAttendanceMonitoringScreen()),
      (label: 'Event', module: AppModule.event, superOnly: false, build: () => const _AdminEventTab()),
    ];
    return [
      for (final t in tabs)
        if (t.superOnly ? auth.isSuperAdmin : auth.canAccess(t.module!))
          (label: t.label, build: t.build),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tabs = auth.isAdminMode ? _visibleTabs(auth) : const <({String label, Widget Function() build})>[];

    if (tabs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Panel Admin')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Akses ditolak. Akun Anda belum diberi izin untuk modul di halaman ini. '
              'Hubungi Super Admin.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: AppTheme.warmIvory,
        appBar: AppBar(
          title: Text(
            'Kelola Data',
            style: TextStyle(
              color: AppTheme.darkCharcoal,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          backgroundColor: AppTheme.surface,
          foregroundColor: AppTheme.darkCharcoal,
          elevation: 0,
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.neutralMedium,
            labelStyle: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(color: AppTheme.primary, width: 3),
              insets: EdgeInsets.symmetric(horizontal: 8),
            ),
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: AppTheme.neutralBorder,
            padding: const EdgeInsets.only(bottom: 2),
            tabs: [for (final t in tabs) Tab(text: t.label)],
          ),
          actions: [
            IconButton(
              tooltip: 'Muat ulang',
              onPressed: _reloadAll,
              icon: Icon(Icons.refresh_rounded, color: AppTheme.darkCharcoal),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [for (final t in tabs) t.build()],
              ),
      ),
    );
  }

  Widget _buildUserTab() {
    final auth = context.read<AuthProvider>();
    final canCreateUser = auth.can(AppModule.users, PermissionAction.create);
    final canApproveUser = auth.can(AppModule.users, PermissionAction.approve);
    final canModify = auth.canModifyExisting;
    final filteredUsers = _filteredUsers;
    final pendingCount = _users.where((user) => user.hasRole('jemaat') && user.membershipStatus == 'pending').length;
    final adminCount = _users.where((user) => user.hasRole('admin')).length;
    final verifiedCount = _users.where((user) => user.membershipStatus == 'active').length;

    return RefreshIndicator(
      onRefresh: _reloadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: _summaryCard('Total User', _users.length, Icons.groups_rounded, const Color(0xFF3B82F6))),
              const SizedBox(width: 12),
              Expanded(child: _summaryCard('Pending', pendingCount, Icons.pending_actions_rounded, const Color(0xFFF59E0B))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _summaryCard('Verified', verifiedCount, Icons.verified_rounded, const Color(0xFF10B981))),
              const SizedBox(width: 12),
              Expanded(child: _summaryCard('Admin', adminCount, Icons.admin_panel_settings_rounded, AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (canCreateUser) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showUserDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah User'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _reloadAll,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Muat Ulang'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _userSearchController,
            decoration: InputDecoration(
              labelText: 'Cari user',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _userSearchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _userSearchController.clear();
                      },
                      icon: const Icon(Icons.clear),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Semua'),
                selected: _userFilter == 'all',
                onSelected: (_) => setState(() => _userFilter = 'all'),
              ),
              ChoiceChip(
                label: const Text('Jemaat'),
                selected: _userFilter == 'jemaat',
                onSelected: (_) => setState(() => _userFilter = 'jemaat'),
              ),
              ChoiceChip(
                label: const Text('Admin'),
                selected: _userFilter == 'admin',
                onSelected: (_) => setState(() => _userFilter = 'admin'),
              ),
              ChoiceChip(
                label: const Text('Pending'),
                selected: _userFilter == 'pending',
                onSelected: (_) => setState(() => _userFilter = 'pending'),
              ),
              ChoiceChip(
                label: const Text('Verified'),
                selected: _userFilter == 'verified',
                onSelected: (_) => setState(() => _userFilter = 'verified'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (filteredUsers.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Tidak ada user yang cocok dengan filter saat ini.'),
              ),
            )
          else
            ...filteredUsers.map((user) {
              final completeness = _profileCompleteness(user);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(user.email),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    // Display all roles
                                    ...user.roles.map((role) {
                                      final roleLabel = switch (role) {
                                        'super_admin' => 'Super Admin',
                                        'admin' => 'Admin',
                                        'pelayan' => 'Pelayan',
                                        _ => 'Jemaat',
                                      };
                                      return Chip(label: Text(roleLabel));
                                    }),
                                    Chip(label: Text(user.membershipStatus)),
                                    Chip(label: Text('${(completeness * 100).toStringAsFixed(0)}% lengkap')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Edit / deactivate existing accounts: Super Admin only.
                          if (canModify && user.id != auth.currentUser?.id)
                            PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  await _showUserDialog(existingUser: user);
                                } else if (value == 'deactivate') {
                                  _confirmDelete(
                                    title: 'Nonaktifkan user',
                                    message: 'Nonaktifkan akun ${user.name}? Akun tidak bisa login, '
                                        'tetapi riwayat datanya tetap tersimpan dan bisa diaktifkan kembali.',
                                    onConfirm: () async {
                                      final success = await auth.deactivateUser(user.id);
                                      if (success) {
                                        await _reloadAll();
                                      }
                                      if (!mounted) {
                                        return;
                                      }
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(success
                                              ? 'User dinonaktifkan.'
                                              : 'Gagal menonaktifkan user. ${auth.lastMessage ?? ''}'),
                                        ),
                                      );
                                    },
                                  );
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'edit', child: Text('Edit')),
                                PopupMenuItem(value: 'deactivate', child: Text('Nonaktifkan')),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Telepon: ${user.phone}'),
                      Text('NIK: ${user.identityNumber ?? '-'}'),
                      Text('Tipe Keanggotaan: ${user.membershipType ?? '-'}'),
                      Text('Kartu Anggota: ${user.memberCardNumber ?? '-'}'),
                      Text('Alamat: ${user.address ?? '-'}'),
                      Text('Member Sejak: ${user.memberSince ?? '-'}'),
                      Text('Tanggal Baptis: ${user.baptismDate ?? '-'}'),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(value: completeness),
                      const SizedBox(height: 12),
                      if (user.hasRole('jemaat') && user.membershipStatus == 'pending' && canApproveUser)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _setMemberStatus(user, approved: false),
                                icon: const Icon(Icons.close),
                                label: const Text('Tolak'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _setMemberStatus(user, approved: true),
                                icon: const Icon(Icons.check),
                                label: const Text('Verifikasi'),
                              ),
                            ),
                          ],
                        )
                      else if (canModify)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _showUserDialog(existingUser: user),
                            icon: const Icon(Icons.manage_accounts),
                            label: const Text('Kelola data'),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDevotionalTab() {
    final auth = context.read<AuthProvider>();
    final canCreate = auth.can(AppModule.renungan, PermissionAction.create);
    final canModify = auth.canModifyExisting;
    final filteredDevotionals = _filteredDevotionals;

    return RefreshIndicator(
      onRefresh: _reloadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              if (canCreate) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDevotionalDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Renungan'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _reloadAll,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Muat Ulang'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _devotionalSearchController,
            decoration: InputDecoration(
              labelText: 'Cari renungan',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _devotionalSearchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _devotionalSearchController.clear();
                      },
                      icon: const Icon(Icons.clear),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          if (filteredDevotionals.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Belum ada renungan.'),
              ),
            )
          else
            ...filteredDevotionals.map(
              (devotional) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  devotional.title,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(_devotionalSubtitle(devotional)),
                              ],
                            ),
                          ),
                          if (canModify)
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                await _showDevotionalDialog(existing: devotional);
                              } else if (value == 'delete') {
                                _confirmDelete(
                                  title: 'Hapus renungan',
                                  message: 'Hapus renungan "${devotional.title}"?',
                                  onConfirm: () async {
                                    final success = await _devotionalService.deleteDevotional(devotional.id);
                                    if (success) {
                                      await _reloadAll();
                                    }
                                    if (!mounted) {
                                      return;
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(success ? 'Renungan dihapus.' : 'Gagal menghapus renungan.')),
                                    );
                                  },
                                );
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(value: 'delete', child: Text('Hapus')),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        devotional.verseReference,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        devotional.verse,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        devotional.content,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (canModify) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _showDevotionalDialog(existing: devotional),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestTab() {
    final auth = context.read<AuthProvider>();
    final canCreate = auth.can(AppModule.quest, PermissionAction.create);
    // Changing the target, resetting or editing the plan alters existing
    // data: Super Admin only.
    final canModify = auth.canModifyExisting;
    final filteredQuests = _filteredQuests;

    return RefreshIndicator(
      onRefresh: _reloadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              if (canCreate)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showQuestDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Quest'),
                ),
              ),
              if (canCreate && canModify) const SizedBox(width: 12),
              if (canModify)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final target = int.tryParse(_dailyTargetController.text.trim());
                    if (target == null) {
                      return;
                    }
                    await _questService.updateDailyReadingTarget(target);
                    await _reloadAll();
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Simpan Target'),
                ),
              ),
            ],
          ),
          if (canModify) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _dailyTargetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target bacaan harian',
                helperText: 'Dipakai saat plan bawaan dihasilkan ulang',
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _questSearchController,
                  decoration: InputDecoration(
                    labelText: 'Cari quest',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _questSearchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _questSearchController.clear();
                            },
                            icon: const Icon(Icons.clear),
                          ),
                  ),
                ),
              ),
              if (canModify) const SizedBox(width: 12),
              if (canModify)
              OutlinedButton.icon(
                onPressed: () async {
                  final shouldReset = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) {
                      return AlertDialog(
                        title: const Text('Reset quest baca'),
                        content: const Text('Kembalikan quest baca ke plan bawaan?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, false),
                            child: const Text('Batal'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: const Text('Reset'),
                          ),
                        ],
                      );
                    },
                  );

                  if (shouldReset == true) {
                    await _questService.resetManagedPlan();
                    await _reloadAll();
                  }
                },
                icon: const Icon(Icons.restore),
                label: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (filteredQuests.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Belum ada quest baca.'),
              ),
            )
          else
            ...filteredQuests.map(
              (quest) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Hari ${quest.day}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (canModify)
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                await _showQuestDialog(existing: quest);
                              } else if (value == 'delete') {
                                _confirmDelete(
                                  title: 'Hapus quest',
                                  message: 'Hapus quest hari ${quest.day}?',
                                  onConfirm: () async {
                                    final success = await _questService.deleteReadingQuest(quest.day);
                                    if (success) {
                                      await _reloadAll();
                                    }
                                    if (!mounted) {
                                      return;
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(success ? 'Quest dihapus.' : 'Gagal menghapus quest.')),
                                    );
                                  },
                                );
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(value: 'delete', child: Text('Hapus')),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _questSubtitle(quest),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (canModify) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _showQuestDialog(existing: quest),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, int value, IconData icon, [Color color = const Color(0xFF1E3A8A)]) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _dialogSectionTitle(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }

  Widget _dialogTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: obscureText,
            maxLines: obscureText ? 1 : maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: label,
              isDense: true,
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.7), width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.8), width: 1.3),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colorScheme.error, width: 1.4),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colorScheme.error, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogDropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<T>(
            initialValue: value,
            items: items,
            onChanged: onChanged,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.7), width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.8), width: 1.3),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colorScheme.error, width: 1.4),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colorScheme.error, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  double _profileCompleteness(User user) {
    final checks = [
      user.name.trim().isNotEmpty,
      user.email.trim().isNotEmpty,
      user.phone.trim().isNotEmpty,
      (user.identityNumber ?? '').trim().isNotEmpty,
      (user.address ?? '').trim().isNotEmpty,
      user.groupId != null,
      (user.memberCardNumber ?? '').trim().isNotEmpty,
    ];
    return checks.where((value) => value).length / checks.length;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Admin Event Tab  (self-contained StatefulWidget so it owns its own state)
// ─────────────────────────────────────────────────────────────────────────────

class _AdminEventTab extends StatefulWidget {
  const _AdminEventTab();

  @override
  State<_AdminEventTab> createState() => _AdminEventTabState();
}

class _AdminEventTabState extends State<_AdminEventTab> {
  final _service = EventService();
  List<ChurchEvent> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<GroupProvider>().loadCategories();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _events = await _service.getAllEvents();
    if (mounted) setState(() => _loading = false);
  }

  void _showCheckinQr(ChurchEvent event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckinQrDisplayScreen(
          targetType: CheckinTarget.event,
          targetId: event.id,
          title: event.title,
          subtitle: DateFormat('EEEE, d MMM yyyy • HH:mm', 'id_ID').format(event.date),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final auth = context.watch<AuthProvider>();
    final canCreate = auth.can(AppModule.event, PermissionAction.create);
    final canRead = auth.can(AppModule.event, PermissionAction.read);
    final canModify = auth.canModifyExisting;
    // Same rule as issue_checkin_token(): pelayan or kehadiran:create.
    final canShowQr = auth.isPelayan || auth.can(AppModule.kehadiran, PermissionAction.create);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Create button
          if (canCreate)
          ElevatedButton.icon(
            onPressed: () => _showEventDialog(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Buat Event Baru'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 16),

          if (_events.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'Belum ada event.\nTambahkan event pertama!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                ),
              ),
            )
          else
            ..._events.map((event) => _AdminEventCard(
                  event: event,
                  onEdit: canModify ? () => _showEventDialog(existing: event) : null,
                  onDelete: canModify ? () => _confirmDelete(event) : null,
                  onToggle: canModify ? () => _toggleActive(event) : null,
                  onViewRegistrations: canRead ? () => _showRegistrations(event) : null,
                  onShowQr: canShowQr && event.isActive ? () => _showCheckinQr(event) : null,
                )),
        ],
      ),
    );
  }

  Future<void> _showEventDialog({ChurchEvent? existing}) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final locationCtrl = TextEditingController(text: existing?.location ?? '');
    final capacityCtrl = TextEditingController(
        text: existing?.maxCapacity?.toString() ?? '');
    final youtubeCtrl = TextEditingController(text: existing?.youtubeUrl ?? '');
    DateTime selectedDate = existing?.date ?? DateTime.now().add(const Duration(days: 7));
    String? categoryId = existing?.categoryId;
    final auth = context.read<AuthProvider>();
    // Only categories this admin may create events in (Super Admin: all).
    final categories = context
        .read<GroupProvider>()
        .categories
        .where((c) => auth.can(AppModule.event, PermissionAction.create, categoryId: c.id))
        .toList();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 4, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  existing == null ? 'Buat Event Baru' : 'Edit Event',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkCharcoal),
                ),
                const SizedBox(height: 16),
                _field(titleCtrl, 'Judul Event'),
                const SizedBox(height: 10),
                _field(descCtrl, 'Deskripsi', maxLines: 3),
                const SizedBox(height: 10),
                _field(locationCtrl, 'Lokasi'),
                const SizedBox(height: 10),
                _field(capacityCtrl, 'Kapasitas Maksimal (opsional)',
                    keyboardType: TextInputType.number),
                const SizedBox(height: 10),
                _field(youtubeCtrl, 'Link YouTube Live (opsional)',
                    keyboardType: TextInputType.url),
                if (categories.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String?>(
                    initialValue: categories.any((c) => c.id == categoryId) ? categoryId : null,
                    decoration: const InputDecoration(labelText: 'Kategori (opsional)'),
                    items: [
                      if (auth.can(AppModule.event, PermissionAction.create))
                        const DropdownMenuItem<String?>(value: null, child: Text('Tanpa kategori')),
                      for (final c in categories)
                        DropdownMenuItem<String?>(value: c.id, child: Text(c.nama)),
                    ],
                    onChanged: (v) => setSheet(() => categoryId = v),
                  ),
                ],
                const SizedBox(height: 10),
                // Date picker row
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (picked == null) return;
                    if (!ctx.mounted) return;
                    final time = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.fromDateTime(selectedDate),
                    );
                    if (!ctx.mounted) return;
                    setSheet(() {
                      selectedDate = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                        time?.hour ?? selectedDate.hour,
                        time?.minute ?? selectedDate.minute,
                      );
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.neutralLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 18, color: Color(0xFF6B7280)),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('EEE, d MMM yyyy • HH:mm')
                              .format(selectedDate),
                          style: TextStyle(
                              fontSize: 14, color: AppTheme.darkCharcoal),
                        ),
                        const Spacer(),
                        const Icon(Icons.edit_rounded,
                            size: 16, color: Color(0xFF6B7280)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result != true || !mounted) return;

    final title = titleCtrl.text.trim();
    if (title.isEmpty) return;
    final capacity = int.tryParse(capacityCtrl.text.trim());
    final youtube = youtubeCtrl.text.trim();
    final youtubeError = validateYoutubeUrl(youtube);
    if (youtubeError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Event tidak disimpan: $youtubeError')),
      );
      return;
    }

    bool ok;
    var notified = true;
    if (existing == null) {
      ok = await _service.createEvent(
        title: title,
        description: descCtrl.text.trim(),
        date: selectedDate,
        location: locationCtrl.text.trim(),
        maxCapacity: capacity,
        youtubeUrl: youtube,
        categoryId: categoryId,
      );
      if (ok && mounted) notified = await _announceEvent(title, selectedDate);
    } else {
      ok = await _service.updateEvent(ChurchEvent(
        id: existing.id,
        title: title,
        description: descCtrl.text.trim(),
        date: selectedDate,
        location: locationCtrl.text.trim(),
        maxCapacity: capacity,
        isActive: existing.isActive,
        createdAt: existing.createdAt,
        youtubeUrl: youtube.isEmpty ? null : youtube,
        categoryId: categoryId,
      ));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(!ok
            ? 'Gagal menyimpan event.'
            : notified
                ? 'Event tersimpan.'
                : 'Event tersimpan, namun pengumuman notifikasi gagal dikirim.'),
        backgroundColor: ok ? const Color(0xFF2563EB) : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      if (ok) await _load();
    }
  }

  /// In-app announcement of a new event to every approved account.
  Future<bool> _announceEvent(String title, DateTime date) async {
    final auth = context.read<AuthProvider>();
    final notifications = context.read<NotificationProvider>();
    final users = await auth.getAllUsers();
    final recipients = users
        .where((u) => AuthProvider.isApprovedStatus(u.membershipStatus))
        .map((u) => u.id);
    return notifications.notifyUsers(
      userIds: recipients,
      title: 'Kegiatan Gereja Baru',
      message: '"$title" pada ${DateFormat('EEEE, dd MMM yyyy • HH:mm', 'id_ID').format(date)}. '
          'Lihat menu Event Gereja untuk mendaftar.',
      type: 'event',
    );
  }

  Future<void> _confirmDelete(ChurchEvent event) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Event?'),
        content: Text('Hapus "${event.title}"? Semua pendaftaran akan ikut terhapus.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final deleted = await _service.deleteEvent(event.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(deleted ? 'Event dihapus.' : 'Gagal menghapus event.'),
        backgroundColor: deleted ? const Color(0xFF2563EB) : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      if (deleted) await _load();
    }
  }

  Future<void> _toggleActive(ChurchEvent event) async {
    await _service.toggleActive(event.id, isActive: !event.isActive);
    await _load();
  }

  Future<void> _showRegistrations(ChurchEvent event) async {
    final regs = await _service.getEventRegistrations(event.id);
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.92,
        builder: (ctx, scroll) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.title,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkCharcoal)),
                        Text(
                            '${regs.where((r) => r.isActive).length} pendaftaran aktif • '
                            '${regs.where((r) => r.isAttended).length} sudah check-in • '
                            '${regs.where((r) => !r.isActive).length} batal',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${regs.where((r) => r.isActive).fold<int>(0, (s, r) => s + r.totalCount)} peserta',
                      style: TextStyle(
                          color: AppTheme.navy,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: regs.isEmpty
                  ? const Center(
                      child: Text('Belum ada pendaftaran.',
                          style: TextStyle(color: Color(0xFF6B7280))))
                  : ListView.separated(
                      controller: scroll,
                      padding: const EdgeInsets.all(16),
                      itemCount: regs.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final r = regs[i];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppTheme.neutralBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: const Color(0xFF1E3A8A)
                                        .withValues(alpha: 0.12),
                                    child: Text(
                                      (r.userName ?? '?')[0].toUpperCase(),
                                      style: TextStyle(
                                          color: AppTheme.navy,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(r.userName ?? '-',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13.5,
                                                color: AppTheme.darkCharcoal)),
                                        if (r.userEmail != null)
                                          Text(r.userEmail!,
                                              style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: Color(0xFF6B7280))),
                                        Text(RegistrationStatus.label(r.status),
                                            style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                                color: r.isAttended
                                                    ? const Color(0xFF059669)
                                                    : r.isActive
                                                        ? const Color(0xFF6B7280)
                                                        : Colors.red)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFBBF24)
                                          .withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${r.totalCount} peserta',
                                      style: const TextStyle(
                                          color: Color(0xFFFBBF24),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                              if (r.familyMembers.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: r.familyMembers
                                      .map((m) => Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppTheme.neutralLight,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${m.name} (${m.relationship})',
                                              style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: AppTheme.secondaryText),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ],
                              if (r.notes != null &&
                                  r.notes!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text('Catatan: ${r.notes}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7280),
                                        fontStyle: FontStyle.italic)),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppTheme.neutralLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Admin Event Card widget
// ─────────────────────────────────────────────────────────────────────────────

class _AdminEventCard extends StatelessWidget {
  final ChurchEvent event;
  // Null = the action is not permitted for this account (hidden).
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggle;
  final VoidCallback? onViewRegistrations;
  final VoidCallback? onShowQr;

  const _AdminEventCard({
    required this.event,
    this.onEdit,
    this.onDelete,
    this.onToggle,
    this.onViewRegistrations,
    this.onShowQr,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('EEE, d MMM yyyy • HH:mm').format(event.date);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: event.isActive
                ? const Color(0xFF1E3A8A).withValues(alpha: 0.2)
                : AppTheme.neutralBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: AppTheme.darkCharcoal)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 12, color: Color(0xFF6B7280)),
                        const SizedBox(width: 4),
                        Text(dateStr,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF6B7280))),
                      ],
                    ),
                    if (event.location.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 12, color: Color(0xFF6B7280)),
                          const SizedBox(width: 4),
                          Text(event.location,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF6B7280))),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (onEdit != null || onDelete != null || onToggle != null ||
                  onViewRegistrations != null || onShowQr != null)
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') onEdit?.call();
                  if (v == 'delete') onDelete?.call();
                  if (v == 'toggle') onToggle?.call();
                  if (v == 'registrations') onViewRegistrations?.call();
                  if (v == 'qr') onShowQr?.call();
                },
                itemBuilder: (_) => [
                  if (onShowQr != null)
                  const PopupMenuItem(
                      value: 'qr',
                      child: Row(children: [
                        Icon(Icons.qr_code_2_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Tampilkan QR Check-in')
                      ])),
                  if (onViewRegistrations != null)
                  const PopupMenuItem(
                      value: 'registrations',
                      child: Row(children: [
                        Icon(Icons.people_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Lihat Pendaftaran')
                      ])),
                  if (onEdit != null)
                  const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Edit')
                      ])),
                  if (onToggle != null)
                  PopupMenuItem(
                      value: 'toggle',
                      child: Row(children: [
                        Icon(
                            event.isActive
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 18),
                        const SizedBox(width: 8),
                        Text(event.isActive
                            ? 'Nonaktifkan'
                            : 'Aktifkan')
                      ])),
                  if (onDelete != null)
                  const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_rounded,
                            size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Hapus',
                            style: TextStyle(color: Colors.red))
                      ])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: event.isActive
                      ? const Color(0xFF2563EB).withValues(alpha: 0.1)
                      : const Color(0xFF6B7280).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  event.isActive ? 'Aktif' : 'Nonaktif',
                  style: TextStyle(
                      color: event.isActive
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF6B7280),
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
              if (event.maxCapacity != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Maks. ${event.maxCapacity} peserta',
                    style: TextStyle(
                        color: AppTheme.navy,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.people_rounded, size: 15),
                label: const Text('Peserta', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                    foregroundColor: AppTheme.navy,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                onPressed: onViewRegistrations,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
