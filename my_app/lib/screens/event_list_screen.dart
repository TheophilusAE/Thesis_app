import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../models/event_registration.dart';
import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_empty_state.dart';
import '../widgets/common/app_skeleton.dart';
import '../widgets/common/app_status_badge.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().loadActiveEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmIvory,
      appBar: AppBar(
        title: const Text('Event & Kegiatan Gereja'),
      ),
      body: Consumer<EventProvider>(
        builder: (_, provider, _) {
          if (provider.isLoading) {
            return _buildLoadingSkeleton();
          }
          final events = provider.activeEvents;
          if (events.isEmpty) {
            return const AppEmptyState(
              icon: Icons.event_busy_rounded,
              title: 'Belum Ada Event Aktif',
              description: 'Jadwal kegiatan dan seminar gereja akan diumumkan di sini. Nantikan informasi selanjutnya!',
            );
          }
          return RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () => provider.loadActiveEvents(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              itemCount: events.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (_, i) => _EventCard(event: events[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: const [
          AppSkeleton(height: 200, borderRadius: BorderRadius.all(Radius.circular(20))),
          SizedBox(height: 16),
          AppSkeleton(height: 200, borderRadius: BorderRadius.all(Radius.circular(20))),
        ],
      ),
    );
  }
}

class _EventCard extends StatefulWidget {
  final ChurchEvent event;
  const _EventCard({required this.event});

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  EventRegistration? _myReg;
  int _registeredCount = 0;
  bool _loadingReg = true;

  @override
  void initState() {
    super.initState();
    _loadRegistrationInfo();
  }

  Future<void> _loadRegistrationInfo() async {
    final uid = context.read<AuthProvider>().user?.id;
    if (uid == null) {
      setState(() => _loadingReg = false);
      return;
    }
    final provider = context.read<EventProvider>();
    final results = await Future.wait([
      provider.getUserRegistration(widget.event.id, uid),
      provider.getRegisteredCount(widget.event.id),
    ]);
    if (!mounted) return;
    setState(() {
      _myReg = results[0] as EventRegistration?;
      _registeredCount = results[1] as int;
      _loadingReg = false;
    });
  }

  bool get _isFull =>
      widget.event.maxCapacity != null &&
      _registeredCount >= widget.event.maxCapacity!;

  int get _spotsLeft => widget.event.maxCapacity == null
      ? -1
      : widget.event.maxCapacity! - _registeredCount;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(widget.event.date);
    final timeStr = DateFormat('HH:mm').format(widget.event.date);
    final registered = _myReg != null;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary,
                  AppTheme.burgundy,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date badge box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            DateFormat('d', 'id_ID').format(widget.event.date),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateFormat('MMM', 'id_ID').format(widget.event.date).toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.goldLight,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.event.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.goldLight),
                              const SizedBox(width: 4),
                              Text(
                                '$timeStr WIB',
                                style: const TextStyle(
                                  color: AppTheme.goldLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (registered || _isFull || (_spotsLeft > 0 && _spotsLeft <= 20)) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (registered)
                        const AppStatusBadge(
                          label: 'Anda Sudah Terdaftar',
                          status: 'completed',
                        ),
                      if (_isFull && !registered)
                        const AppStatusBadge(
                          label: 'Kuota Penuh',
                          status: 'rejected',
                        ),
                      if (!_isFull && _spotsLeft > 0 && _spotsLeft <= 20)
                        AppStatusBadge(
                          label: 'Sisa $_spotsLeft slot',
                          status: 'warning',
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Card Body
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_month_outlined, size: 16, color: AppTheme.neutralMedium),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        dateStr,
                        style: const TextStyle(fontSize: 13, color: AppTheme.darkCharcoal, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                if (widget.event.location.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.neutralMedium),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.event.location,
                          style: const TextStyle(fontSize: 13, color: AppTheme.darkCharcoal),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (widget.event.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    widget.event.description,
                    style: const TextStyle(fontSize: 13, color: AppTheme.neutralMedium, height: 1.45),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (widget.event.maxCapacity != null && !_loadingReg) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.people_outline_rounded, size: 16, color: AppTheme.neutralMedium),
                      const SizedBox(width: 6),
                      Text(
                        '$_registeredCount / ${widget.event.maxCapacity} Peserta',
                        style: const TextStyle(fontSize: 12, color: AppTheme.neutralMedium, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (_registeredCount / widget.event.maxCapacity!).clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: AppTheme.neutralLight,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _isFull ? AppTheme.primary : AppTheme.gold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Action Area
                _loadingReg
                    ? const Center(
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : registered
                        ? _RegisteredActions(
                            event: widget.event,
                            registration: _myReg!,
                            onChanged: _loadRegistrationInfo,
                          )
                        : AppButton(
                            label: _isFull ? 'Pendaftaran Ditutup (Penuh)' : 'Daftar Sekarang',
                            icon: Icons.app_registration_rounded,
                            onPressed: _isFull ? null : () => _showRegistrationSheet(context),
                          ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRegistrationSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _RegistrationSheet(
        event: widget.event,
        existingRegistration: _myReg,
        onSuccess: () {
          Navigator.pop(ctx);
          _loadRegistrationInfo();
        },
      ),
    );
  }
}

class _RegisteredActions extends StatelessWidget {
  final ChurchEvent event;
  final EventRegistration registration;
  final VoidCallback onChanged;

  const _RegisteredActions({
    required this.event,
    required this.registration,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppTheme.emerald, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Anda Telah Terdaftar',
                    style: TextStyle(
                      color: AppTheme.emerald,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${registration.totalCount} Orang',
                    style: const TextStyle(
                      color: AppTheme.darkCharcoal,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (registration.familyMembers.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Anggota: ${registration.familyMembers.map((m) => m.name).join(', ')}',
                  style: const TextStyle(color: AppTheme.neutralMedium, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Ubah Data',
                icon: Icons.edit_outlined,
                variant: AppButtonVariant.outline,
                onPressed: () => _showRegistrationSheet(context),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Batalkan Pendaftaran',
              style: IconButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEF4444)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(48, 48),
              ),
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
              onPressed: () => _confirmCancel(context),
            ),
          ],
        ),
      ],
    );
  }

  void _showRegistrationSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _RegistrationSheet(
        event: event,
        existingRegistration: registration,
        onSuccess: () {
          Navigator.pop(ctx);
          onChanged();
        },
      ),
    );
  }

  void _confirmCancel(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Batalkan Pendaftaran?'),
        content: Text(
          'Apakah Anda yakin ingin membatalkan pendaftaran untuk kegiatan "${event.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tidak, Tetap Ikut', style: TextStyle(color: AppTheme.neutralMedium)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final uid = context.read<AuthProvider>().user?.id;
              if (uid == null) return;
              final ok = await context.read<EventProvider>().cancelRegistration(event.id, uid);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok ? 'Pendaftaran berhasil dibatalkan.' : 'Gagal membatalkan pendaftaran.',
                  ),
                  backgroundColor: ok ? AppTheme.primary : Colors.red,
                ),
              );
              if (ok) onChanged();
            },
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }
}

class _RegistrationSheet extends StatefulWidget {
  final ChurchEvent event;
  final EventRegistration? existingRegistration;
  final VoidCallback onSuccess;

  const _RegistrationSheet({
    required this.event,
    this.existingRegistration,
    required this.onSuccess,
  });

  @override
  State<_RegistrationSheet> createState() => _RegistrationSheetState();
}

class _RegistrationSheetState extends State<_RegistrationSheet> {
  final _notesCtrl = TextEditingController();
  final List<_FamilyRow> _familyRows = [];
  bool _saving = false;

  static const _relationships = [
    'Suami/Istri',
    'Anak',
    'Orang Tua',
    'Saudara',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existingRegistration;
    if (existing != null) {
      _notesCtrl.text = existing.notes ?? '';
      for (final m in existing.familyMembers) {
        _familyRows.add(_FamilyRow(
          nameCtrl: TextEditingController(text: m.name),
          relationship: m.relationship,
        ));
      }
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    for (final r in _familyRows) {
      r.nameCtrl.dispose();
    }
    super.dispose();
  }

  int get _totalPeople => 1 + _familyRows.length;

  Future<void> _submit() async {
    for (final row in _familyRows) {
      if (row.nameCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lengkapi nama semua anggota keluarga.')),
        );
        return;
      }
    }

    setState(() => _saving = true);

    final uid = context.read<AuthProvider>().user?.id;
    if (uid == null) {
      setState(() => _saving = false);
      return;
    }

    final familyMembers = _familyRows
        .map((r) => FamilyMember(
              name: r.nameCtrl.text.trim(),
              relationship: r.relationship,
            ))
        .toList();

    final ok = await context.read<EventProvider>().registerForEvent(
          eventId: widget.event.id,
          userId: uid,
          familyMembers: familyMembers,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pendaftaran berhasil! $_totalPeople peserta terdaftar.'),
          backgroundColor: AppTheme.emerald,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mendaftar. Silakan coba kembali.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final myName = auth.currentUser?.name ?? 'Anda';
    final dateStr = DateFormat('EEEE, d MMMM yyyy • HH:mm', 'id_ID').format(widget.event.date);
    final isEdit = widget.existingRegistration != null;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scroll) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? 'Ubah Data Pendaftaran' : 'Formulir Pendaftaran Event',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkCharcoal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.event.title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: const TextStyle(fontSize: 12, color: AppTheme.neutralMedium),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  // Main Registrant
                  _buildSectionTitle('Pendaftar Utama'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                          child: Text(
                            myName.isNotEmpty ? myName[0].toUpperCase() : 'A',
                            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                myName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const Text('Pendaftar Utama (Terdaftar)', style: TextStyle(fontSize: 12, color: AppTheme.neutralMedium)),
                            ],
                          ),
                        ),
                        const Icon(Icons.lock_outline_rounded, size: 16, color: AppTheme.neutralMedium),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Family Members Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Anggota Keluarga / Tambahan'),
                      Text(
                        '${_familyRows.length} ditambahkan',
                        style: const TextStyle(fontSize: 12, color: AppTheme.neutralMedium, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ..._familyRows.asMap().entries.map((entry) {
                    final i = entry.key;
                    final row = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: TextField(
                              controller: row.nameCtrl,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Nama Lengkap',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                filled: true,
                                fillColor: AppTheme.warmIvory,
                              ),
                              textCapitalization: TextCapitalization.words,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
                            child: DropdownButtonFormField<String>(
                              initialValue: row.relationship,
                              items: _relationships
                                  .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12))))
                                  .toList(),
                              onChanged: (v) => setState(() => row.relationship = v!),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                filled: true,
                                fillColor: AppTheme.warmIvory,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.red, size: 22),
                            onPressed: () {
                              setState(() {
                                row.nameCtrl.dispose();
                                _familyRows.removeAt(i);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),

                  OutlinedButton.icon(
                    icon: const Icon(Icons.person_add_outlined, size: 18),
                    label: const Text('Tambah Anggota Keluarga'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => setState(() {
                      _familyRows.add(_FamilyRow(
                        nameCtrl: TextEditingController(),
                        relationship: _relationships.first,
                      ));
                    }),
                  ),

                  const SizedBox(height: 20),

                  // Notes
                  _buildSectionTitle('Catatan Khusus (Opsional)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Contoh: butuh tempat duduk khusus lansia / kursi roda...',
                      hintStyle: const TextStyle(color: AppTheme.neutralMedium, fontSize: 12),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: AppTheme.warmIvory,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Summary Notice
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.goldLight.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.gold.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppTheme.goldDark, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Total peserta: $_totalPeople orang',
                          style: const TextStyle(
                            color: AppTheme.goldDark,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: AppButton(
                  label: isEdit ? 'Simpan Perubahan' : 'Konfirmasi Pendaftaran ($_totalPeople Orang)',
                  icon: Icons.check_circle_outline_rounded,
                  isLoading: _saving,
                  onPressed: _submit,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.bold,
        color: AppTheme.darkCharcoal,
      ),
    );
  }
}

class _FamilyRow {
  TextEditingController nameCtrl;
  String relationship;
  _FamilyRow({required this.nameCtrl, required this.relationship});
}
