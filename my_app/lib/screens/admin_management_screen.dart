import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/devotional.dart';
import '../models/event.dart';
import '../models/reading_quest.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
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
    await authProvider.loadPendingUsers();
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
  }

  Future<void> _reloadAll() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.loadPendingUsers();
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
        user.familyGroup ?? '',
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

  Future<void> _showUserDialog({User? existingUser}) async {
    final nameController = TextEditingController(text: existingUser?.name ?? '');
    final emailController = TextEditingController(text: existingUser?.email ?? '');
    final phoneController = TextEditingController(text: existingUser?.phone ?? '');
    final passwordController = TextEditingController();
    final identityController = TextEditingController(text: existingUser?.identityNumber ?? '');
    final familyController = TextEditingController(text: existingUser?.familyGroup ?? '');
    final membershipTypeController = TextEditingController(text: existingUser?.membershipType ?? '');
    final memberCardController = TextEditingController(text: existingUser?.memberCardNumber ?? '');
    final addressController = TextEditingController(text: existingUser?.address ?? '');
    final memberSinceController = TextEditingController(text: existingUser?.memberSince ?? '');
    final baptismController = TextEditingController(text: existingUser?.baptismDate ?? '');
    List<String> selectedRoles = existingUser?.roles ?? ['jemaat'];
    String membershipStatus = existingUser?.membershipStatus ?? 'pending';
    final isMobile = MediaQuery.of(context).size.width < 700;

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
              CheckboxListTile(
                title: const Text('Admin'),
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
            items: const [
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'verified', child: Text('Verified')),
              DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
            ],
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
            controller: familyController,
            label: 'Komunitas / Family Group',
          ),
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
        familyGroup: familyController.text.trim().isEmpty ? null : familyController.text.trim(),
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Data user tersimpan.' : 'Gagal menyimpan user.')),
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
          ).then((_) => true)
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

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Panel Admin')),
        body: const Center(
          child: Text('Akses ditolak. Hanya admin yang dapat membuka halaman ini.'),
        ),
      );
    }

    return DefaultTabController(
      length: 11,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Kelola Data',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A5F), Color(0xFF2C5282)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(color: Color(0xFFD4A017), width: 3),
              insets: EdgeInsets.symmetric(horizontal: 8),
            ),
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.white12,
            padding: const EdgeInsets.only(bottom: 2),
            tabs: const [
              Tab(text: 'User'),
              Tab(text: 'Role'),
              Tab(text: 'Renungan'),
              Tab(text: 'Quest Baca'),
              Tab(text: 'Feedback'),
              Tab(text: 'Pelayan'),
              Tab(text: 'Jadwal Ibadah'),
              Tab(text: 'Jadwal Latihan'),
              Tab(text: 'Substitusi'),
              Tab(text: 'Kehadiran'),
              Tab(text: 'Event'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Muat ulang',
              onPressed: _reloadAll,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildUserTab(),
                  const RoleManagementScreen(),
                  _buildDevotionalTab(),
                  _buildQuestTab(),
                  const FeedbackManagementScreen(),
                  const PelayaniManagementScreen(),
                  const ServiceScheduleManagementScreen(),
                  const TrainingScheduleManagementScreen(),
                  const AdminSubstitutionReviewScreen(),
                  const AdminAttendanceMonitoringScreen(),
                  const _AdminEventTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildUserTab() {
    final filteredUsers = _filteredUsers;
    final pendingCount = _users.where((user) => user.hasRole('jemaat') && user.membershipStatus == 'pending').length;
    final adminCount = _users.where((user) => user.hasRole('admin')).length;
    final verifiedCount = _users.where((user) => user.membershipStatus == 'active').length;

    return RefreshIndicator(
      onRefresh: _reloadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _summaryCard('Total User', _users.length, Icons.groups),
              _summaryCard('Pending', pendingCount, Icons.pending_actions),
              _summaryCard('Verified', verifiedCount, Icons.verified),
              _summaryCard('Admin', adminCount, Icons.admin_panel_settings),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showUserDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah User'),
                ),
              ),
              const SizedBox(width: 12),
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
                                      final roleLabel = role == 'admin' ? 'Admin' : 
                                                       role == 'pelayan' ? 'Pelayan' : 'Jemaat';
                                      return Chip(label: Text(roleLabel));
                                    }),
                                    Chip(label: Text(user.membershipStatus)),
                                    Chip(label: Text('${(completeness * 100).toStringAsFixed(0)}% lengkap')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                await _showUserDialog(existingUser: user);
                              } else if (value == 'delete') {
                                _confirmDelete(
                                  title: 'Hapus user',
                                  message: 'Hapus akun ${user.name}? Tindakan ini tidak bisa dibatalkan.',
                                  onConfirm: () async {
                                    final success = await context.read<AuthProvider>().deleteUser(user.id);
                                    if (success) {
                                      await _reloadAll();
                                    }
                                    if (!mounted) {
                                      return;
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(success ? 'User dihapus.' : 'Gagal menghapus user.')),
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
                      Text('Telepon: ${user.phone}'),
                      Text('NIK: ${user.identityNumber ?? '-'}'),
                      Text('Komunitas: ${user.familyGroup ?? '-'}'),
                      Text('Tipe Keanggotaan: ${user.membershipType ?? '-'}'),
                      Text('Kartu Anggota: ${user.memberCardNumber ?? '-'}'),
                      Text('Alamat: ${user.address ?? '-'}'),
                      Text('Member Sejak: ${user.memberSince ?? '-'}'),
                      Text('Tanggal Baptis: ${user.baptismDate ?? '-'}'),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(value: completeness),
                      const SizedBox(height: 12),
                      if (user.hasRole('jemaat') && user.membershipStatus == 'pending')
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final auth = context.read<AuthProvider>();
                                  final ok = await auth.verifyUser(userId: user.id, approved: false);
                                  if (ok) {
                                    await _reloadAll();
                                  }
                                },
                                icon: const Icon(Icons.close),
                                label: const Text('Tolak'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final auth = context.read<AuthProvider>();
                                  final ok = await auth.verifyUser(userId: user.id, approved: true);
                                  if (ok) {
                                    await _reloadAll();
                                  }
                                },
                                icon: const Icon(Icons.check),
                                label: const Text('Verifikasi'),
                              ),
                            ),
                          ],
                        )
                      else
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
    final filteredDevotionals = _filteredDevotionals;

    return RefreshIndicator(
      onRefresh: _reloadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showDevotionalDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Renungan'),
                ),
              ),
              const SizedBox(width: 12),
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
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestTab() {
    final filteredQuests = _filteredQuests;

    return RefreshIndicator(
      onRefresh: _reloadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showQuestDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Quest'),
                ),
              ),
              const SizedBox(width: 12),
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
          const SizedBox(height: 12),
          TextField(
            controller: _dailyTargetController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Target bacaan harian',
              helperText: 'Dipakai saat plan bawaan dihasilkan ulang',
            ),
          ),
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
              const SizedBox(width: 12),
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
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, int value, IconData icon) {
    const color = Color(0xFF1E3A5F);
    return SizedBox(
      width: 160,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
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
              style: const TextStyle(
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
      (user.familyGroup ?? '').trim().isNotEmpty,
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
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _events = await _service.getAllEvents();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Create button
          ElevatedButton.icon(
            onPressed: () => _showEventDialog(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Buat Event Baru'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A5F),
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
                  onEdit: () => _showEventDialog(existing: event),
                  onDelete: () => _confirmDelete(event),
                  onToggle: () => _toggleActive(event),
                  onViewRegistrations: () => _showRegistrations(event),
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
    DateTime selectedDate = existing?.date ?? DateTime.now().add(const Duration(days: 7));

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
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
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937)),
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
                      color: const Color(0xFFF1F5F9),
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
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFF1F2937)),
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
                          backgroundColor: const Color(0xFF1E3A5F),
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

    bool ok;
    if (existing == null) {
      ok = await _service.createEvent(
        title: title,
        description: descCtrl.text.trim(),
        date: selectedDate,
        location: locationCtrl.text.trim(),
        maxCapacity: capacity,
      );
    } else {
      ok = await _service.updateEvent(existing.copyWith(
        title: title,
        description: descCtrl.text.trim(),
        date: selectedDate,
        location: locationCtrl.text.trim(),
        maxCapacity: capacity,
      ));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Event tersimpan.' : 'Gagal menyimpan event.'),
        backgroundColor: ok ? const Color(0xFF0D9488) : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      if (ok) await _load();
    }
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
        backgroundColor: deleted ? const Color(0xFF0D9488) : Colors.red,
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
      backgroundColor: Colors.white,
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
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937))),
                        Text('${regs.length} keluarga terdaftar',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A5F).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${regs.fold<int>(0, (s, r) => s + r.totalCount)} peserta',
                      style: const TextStyle(
                          color: Color(0xFF1E3A5F),
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: const Color(0xFF1E3A5F)
                                        .withValues(alpha: 0.12),
                                    child: Text(
                                      (r.userName ?? '?')[0].toUpperCase(),
                                      style: const TextStyle(
                                          color: Color(0xFF1E3A5F),
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
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13.5,
                                                color: Color(0xFF1F2937))),
                                        if (r.userEmail != null)
                                          Text(r.userEmail!,
                                              style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: Color(0xFF6B7280))),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD4A017)
                                          .withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${r.totalCount} peserta',
                                      style: const TextStyle(
                                          color: Color(0xFFD4A017),
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
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${m.name} (${m.relationship})',
                                              style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: Color(0xFF374151)),
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
        fillColor: const Color(0xFFF1F5F9),
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;
  final VoidCallback onViewRegistrations;

  const _AdminEventCard({
    required this.event,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
    required this.onViewRegistrations,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('EEE, d MMM yyyy • HH:mm').format(event.date);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: event.isActive
                ? const Color(0xFF1E3A5F).withValues(alpha: 0.2)
                : const Color(0xFFE2E8F0)),
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
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: Color(0xFF1F2937))),
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
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                  if (v == 'toggle') onToggle();
                  if (v == 'registrations') onViewRegistrations();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'registrations',
                      child: Row(children: [
                        Icon(Icons.people_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Lihat Pendaftaran')
                      ])),
                  const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Edit')
                      ])),
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
                      ? const Color(0xFF0D9488).withValues(alpha: 0.1)
                      : const Color(0xFF6B7280).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  event.isActive ? 'Aktif' : 'Nonaktif',
                  style: TextStyle(
                      color: event.isActive
                          ? const Color(0xFF0D9488)
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
                    color: const Color(0xFF1E3A5F).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Maks. ${event.maxCapacity} peserta',
                    style: const TextStyle(
                        color: Color(0xFF1E3A5F),
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
                    foregroundColor: const Color(0xFF1E3A5F),
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
