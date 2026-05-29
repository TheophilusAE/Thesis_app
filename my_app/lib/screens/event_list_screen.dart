import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../models/event_registration.dart';
import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';

// ── Palette ──────────────────────────────────────────────
const _navy      = Color(0xFF1E3A5F);
const _navyLight = Color(0xFF2C5282);
const _gold      = Color(0xFFD4A017);
const _teal      = Color(0xFF0D9488);
const _slate     = Color(0xFF1F2937);
const _muted     = Color(0xFF6B7280);

// ─────────────────────────────────────────────────────────
// Entry point — for Jemaat (browse + register)
// ─────────────────────────────────────────────────────────

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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Event Gereja',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_navy, _navyLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Consumer<EventProvider>(
        builder: (_, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = provider.activeEvents;
          if (events.isEmpty) {
            return _EmptyEvents();
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadActiveEvents(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: events.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (_, i) => _EventCard(event: events[i]),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Event card
// ─────────────────────────────────────────────────────────

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

  int get _spotsLeft =>
      widget.event.maxCapacity == null
          ? -1
          : widget.event.maxCapacity! - _registeredCount;

  static const _gradients = [
    LinearGradient(colors: [Color(0xFF1E3A5F), Color(0xFF2C5282)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0F766E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(colors: [Color(0xFFD4A017), Color(0xFFB8860B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  ];

  LinearGradient _gradient(int index) => _gradients[index % _gradients.length];

  @override
  Widget build(BuildContext context) {
    final idx = widget.event.id.hashCode;
    final dateStr = DateFormat('EEE, d MMM yyyy').format(widget.event.date);
    final timeStr = DateFormat('HH:mm').format(widget.event.date);
    final registered = _myReg != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient banner
          Container(
            height: 110,
            decoration: BoxDecoration(
              gradient: _gradient(idx),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20, top: -20,
                  child: Container(
                    width: 110, height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Status chips
                      Row(
                        children: [
                          if (registered) ...[
                            _Chip(
                              label: 'Sudah Terdaftar ✓',
                              bg: Colors.white.withValues(alpha: 0.25),
                              textColor: Colors.white,
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (_isFull && !registered)
                            _Chip(
                              label: 'Penuh',
                              bg: Colors.red.withValues(alpha: 0.25),
                              textColor: Colors.white,
                            ),
                          if (!_isFull && _spotsLeft > 0 && _spotsLeft <= 20)
                            _Chip(
                              label: '$_spotsLeft slot tersisa',
                              bg: _gold.withValues(alpha: 0.3),
                              textColor: Colors.white,
                            ),
                        ],
                      ),
                      // Title
                      Text(
                        widget.event.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date & time row
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: _muted),
                    const SizedBox(width: 5),
                    Text(dateStr, style: const TextStyle(fontSize: 12.5, color: _muted, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time_rounded, size: 14, color: _muted),
                    const SizedBox(width: 5),
                    Text(timeStr, style: const TextStyle(fontSize: 12.5, color: _gold, fontWeight: FontWeight.w700)),
                  ],
                ),
                if (widget.event.location.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: _muted),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          widget.event.location,
                          style: const TextStyle(fontSize: 12.5, color: _muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (widget.event.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.event.description,
                    style: const TextStyle(fontSize: 13, color: _slate, height: 1.45),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (widget.event.maxCapacity != null && !_loadingReg) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.people_rounded, size: 14, color: _muted),
                      const SizedBox(width: 5),
                      Text(
                        '$_registeredCount / ${widget.event.maxCapacity} peserta',
                        style: const TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _registeredCount / widget.event.maxCapacity!,
                            minHeight: 5,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation(
                              _isFull ? Colors.red : _navy,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),

                // Action buttons
                _loadingReg
                    ? const Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : registered
                        ? _RegisteredActions(
                            event: widget.event,
                            registration: _myReg!,
                            onChanged: _loadRegistrationInfo,
                          )
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.app_registration_rounded, size: 18),
                              label: const Text('Daftar Sekarang'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isFull ? Colors.grey : _navy,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _isFull
                                  ? null
                                  : () => _showRegistrationSheet(context),
                            ),
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

// ─────────────────────────────────────────────────────────
// Registered state — shows summary + edit/cancel buttons
// ─────────────────────────────────────────────────────────

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
            color: _teal.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _teal.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: _teal, size: 16),
                  const SizedBox(width: 6),
                  const Text(
                    'Anda terdaftar',
                    style: TextStyle(
                      color: _teal,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${registration.totalCount} peserta',
                    style: const TextStyle(
                      color: _teal,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (registration.familyMembers.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Anggota keluarga: ${registration.familyMembers.map((m) => m.name).join(', ')}',
                  style: const TextStyle(color: _muted, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('Ubah Pendaftaran'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _navy,
                  side: const BorderSide(color: _navy),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _showRegistrationSheet(context),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _confirmCancel(context),
              child: const Icon(Icons.cancel_outlined, size: 18),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Batalkan Pendaftaran?'),
        content: Text(
          'Apakah Anda yakin ingin membatalkan pendaftaran untuk "${event.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final uid = context.read<AuthProvider>().user?.id;
              if (uid == null) return;
              final ok = await context
                  .read<EventProvider>()
                  .cancelRegistration(event.id, uid);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok
                      ? 'Pendaftaran berhasil dibatalkan.'
                      : 'Gagal membatalkan pendaftaran.'),
                  backgroundColor: ok ? _teal : Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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

// ─────────────────────────────────────────────────────────
// Registration bottom sheet
// ─────────────────────────────────────────────────────────

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
    // Validate all family member names filled
    for (final row in _familyRows) {
      if (row.nameCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lengkapi nama semua anggota keluarga.'),
            behavior: SnackBarBehavior.floating,
          ),
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
          content: Text(
            'Pendaftaran berhasil! $_totalPeople peserta terdaftar.',
          ),
          backgroundColor: _teal,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mendaftar. Coba lagi.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final myName = auth.currentUser?.name ?? 'Anda';
    final dateStr =
        DateFormat('EEE, d MMM yyyy • HH:mm').format(widget.event.date);
    final isEdit = widget.existingRegistration != null;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scroll) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? 'Ubah Pendaftaran' : 'Daftar Event',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: _slate,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.event.title,
                    style: const TextStyle(
                        fontSize: 13.5,
                        color: _navy,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: const TextStyle(fontSize: 12, color: _muted),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  // Registrant (self) — read-only
                  _SheetSection(
                    title: 'Pendaftar Utama',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _navy.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _navy.withValues(alpha: 0.18)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                _navy.withValues(alpha: 0.15),
                            child: Text(
                              myName.isNotEmpty
                                  ? myName[0].toUpperCase()
                                  : 'A',
                              style: const TextStyle(
                                  color: _navy, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(myName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: _slate)),
                                const Text('Pendaftar',
                                    style: TextStyle(
                                        fontSize: 12, color: _muted)),
                              ],
                            ),
                          ),
                          const Icon(Icons.lock_outline_rounded,
                              size: 16, color: _muted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Family members
                  _SheetSection(
                    title: 'Anggota Keluarga',
                    trailing: Text(
                      '${_familyRows.length} ditambahkan',
                      style: const TextStyle(
                          fontSize: 12,
                          color: _muted,
                          fontWeight: FontWeight.w500),
                    ),
                    child: Column(
                      children: [
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
                                    decoration: InputDecoration(
                                      labelText: 'Nama',
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFFF1F5F9),
                                    ),
                                    textCapitalization:
                                        TextCapitalization.words,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 4,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: row.relationship,
                                    items: _relationships
                                        .map((r) => DropdownMenuItem(
                                            value: r,
                                            child: Text(r,
                                                style: const TextStyle(
                                                    fontSize: 12.5))))
                                        .toList(),
                                    onChanged: (v) => setState(
                                        () => row.relationship = v!),
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFFF1F5F9),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline_rounded,
                                      color: Colors.red, size: 22),
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
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Tambah Anggota Keluarga'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _navy,
                              side: const BorderSide(
                                  color: _navy, width: 1.5),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => setState(() {
                              _familyRows.add(_FamilyRow(
                                nameCtrl: TextEditingController(),
                                relationship: _relationships.first,
                              ));
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Notes
                  _SheetSection(
                    title: 'Catatan (opsional)',
                    child: TextField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'Contoh: butuh kursi roda, vegetarian, dll.',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Summary chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _gold.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.people_rounded,
                            color: _gold, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Total peserta yang didaftarkan: $_totalPeople orang',
                          style: const TextStyle(
                            color: _gold,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Submit button
            SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navy,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(
                                  Colors.white),
                            ),
                          )
                        : Text(
                            isEdit
                                ? 'Simpan Perubahan'
                                : 'Konfirmasi Pendaftaran ($_totalPeople peserta)',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────

class _FamilyRow {
  TextEditingController nameCtrl;
  String relationship;
  _FamilyRow({required this.nameCtrl, required this.relationship});
}

class _SheetSection extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SheetSection(
      {required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: _slate)),
            if (trailing != null) ...[
              const Spacer(),
              trailing!,
            ],
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;

  const _Chip(
      {required this.label, required this.bg, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _EmptyEvents extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: _navy.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_busy_rounded,
                  size: 44, color: _navy),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Event',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _slate),
            ),
            const SizedBox(height: 6),
            const Text(
              'Event gereja akan muncul di sini.\nNantikan pengumuman selanjutnya!',
              style: TextStyle(color: _muted, fontSize: 13.5, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
