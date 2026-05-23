import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/devotional.dart';
import '../models/reading_quest.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/feedback_provider.dart';
import '../services/devotional_service.dart';
import '../services/quest_service.dart';
import 'admin_substitution_review_screen.dart';
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
        'verified' => user.membershipStatus == 'verified',
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
    final result = isMobile
        ? await showModalBottomSheet<User?>(
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
          )
        : await showDialog<User?>(
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

    if (result == null) {
      return;
    }

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
    final result = isMobile
        ? await showModalBottomSheet<Devotional?>(
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
          )
        : await showDialog<Devotional?>(
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
    final result = isMobile
        ? await showModalBottomSheet<ReadingQuest?>(
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
          )
        : await showDialog<ReadingQuest?>(
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
      length: 9,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kelola Data'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'User'),
              Tab(icon: Icon(Icons.security), text: 'Role'),
              Tab(icon: Icon(Icons.menu_book), text: 'Renungan'),
              Tab(icon: Icon(Icons.task_alt), text: 'Quest Baca'),
              Tab(icon: Icon(Icons.feedback), text: 'Feedback'),
              Tab(icon: Icon(Icons.volunteer_activism), text: 'Pelayan'),
              Tab(icon: Icon(Icons.event_available), text: 'Jadwal Ibadah'),
              Tab(icon: Icon(Icons.school), text: 'Jadwal Latihan'),
              Tab(icon: Icon(Icons.swap_horiz), text: 'Substitusi'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Muat ulang',
              onPressed: _reloadAll,
              icon: const Icon(Icons.refresh),
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
                ],
              ),
      ),
    );
  }

  Widget _buildUserTab() {
    final filteredUsers = _filteredUsers;
    final pendingCount = _users.where((user) => user.hasRole('jemaat') && user.membershipStatus == 'pending').length;
    final adminCount = _users.where((user) => user.hasRole('admin')).length;
    final verifiedCount = _users.where((user) => user.membershipStatus == 'verified').length;

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
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(height: 12),
              Text(
                value.toString(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(label),
            ],
          ),
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
            value: value,
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
