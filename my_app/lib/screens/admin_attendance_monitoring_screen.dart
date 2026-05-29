import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/attendance_confirmation_provider.dart';
import '../models/attendance_confirmation.dart';

class AdminAttendanceMonitoringScreen extends StatefulWidget {
  const AdminAttendanceMonitoringScreen({super.key});

  @override
  State<AdminAttendanceMonitoringScreen> createState() =>
      _AdminAttendanceMonitoringScreenState();
}

class _AdminAttendanceMonitoringScreenState
    extends State<AdminAttendanceMonitoringScreen> {
  String _filterStatus = 'all'; // all, confirmed, pending
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AttendanceConfirmationProvider>();
      provider.loadAllConfirmations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AttendanceConfirmation> _getFilteredConfirmations(
    List<AttendanceConfirmation> confirmations,
  ) {
    List<AttendanceConfirmation> filtered = confirmations;

    // Filter by status
    if (_filterStatus == 'confirmed') {
      filtered = filtered.where((c) => c.confirmed).toList();
    } else if (_filterStatus == 'pending') {
      filtered = filtered.where((c) => !c.confirmed).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((c) =>
              c.userName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              c.scheduleDate
                  .toString()
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  Widget _buildSummaryCard(List<AttendanceConfirmation> all) {
    final confirmed = all.where((c) => c.confirmed).length;
    final pending = all.length - confirmed;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '${all.length}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            Column(
              children: [
                Text(
                  'Sudah Konfirmasi',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '$confirmed',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            Column(
              children: [
                Text(
                  'Belum Konfirmasi',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '$pending',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Search field
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
            decoration: InputDecoration(
              hintText: 'Cari nama atau tanggal...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          const SizedBox(height: 12),
          // Status filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'Semua'),
                const SizedBox(width: 8),
                _buildFilterChip('confirmed', 'Sudah Konfirmasi'),
                const SizedBox(width: 8),
                _buildFilterChip('pending', 'Belum Konfirmasi'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filterStatus == value;
    final colorScheme = Theme.of(context).colorScheme;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterStatus = selected ? value : 'all');
      },
      selectedColor:
          isSelected ? colorScheme.primary.withValues(alpha: 0.3) : null,
      side: BorderSide(
        color: isSelected ? colorScheme.primary : Colors.grey,
      ),
    );
  }

  Widget _buildConfirmationTile(AttendanceConfirmation confirmation) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
    final scheduleDate = dateFormat.format(confirmation.scheduleDate);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: confirmation.confirmed ? Colors.green : Colors.orange,
          ),
          child: Center(
            child: Icon(
              confirmation.confirmed ? Icons.check : Icons.pending,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        title: Text(
          confirmation.userName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Jadwal: $scheduleDate',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (confirmation.confirmed && confirmation.confirmedAt != null)
              Text(
                'Dikonfirmasi: ${dateFormat.format(confirmation.confirmedAt!)}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.green),
              ),
            if (confirmation.notes != null && confirmation.notes!.isNotEmpty)
              Text(
                'Catatan: ${confirmation.notes}',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Icon(
          confirmation.confirmed ? Icons.done_all : Icons.schedule,
          color: confirmation.confirmed ? Colors.green : Colors.orange,
        ),
        onTap: () => _showConfirmationDetails(confirmation),
      ),
    );
  }

  void _showConfirmationDetails(AttendanceConfirmation confirmation) {
    final dateFormat = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Konfirmasi Kehadiran'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nama Pelayan: ${confirmation.userName}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                'Tanggal Jadwal: ${dateFormat.format(confirmation.scheduleDate)}',
              ),
              const SizedBox(height: 12),
              Text(
                'Status: ${confirmation.confirmed ? 'Sudah Dikonfirmasi' : 'Belum Dikonfirmasi'}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: confirmation.confirmed ? Colors.green : Colors.orange,
                ),
              ),
              if (confirmation.confirmedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Waktu Konfirmasi: ${dateFormat.format(confirmation.confirmedAt!)}',
                  ),
                ),
              if (confirmation.notes != null && confirmation.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Catatan: ${confirmation.notes}',
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'ID: ${confirmation.id}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitor Kehadiran Pelayan'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primaryContainer,
              ],
            ),
          ),
        ),
      ),
      body: Consumer<AttendanceConfirmationProvider>(
        builder: (context, provider, _) {
          final allConfirmations = provider.allConfirmations;
          final filteredConfirmations =
              _getFilteredConfirmations(allConfirmations);

          return Column(
            children: [
              _buildSummaryCard(allConfirmations),
              _buildFilterBar(),
              Expanded(
                child: filteredConfirmations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox,
                              size: 64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              allConfirmations.isEmpty
                                  ? 'Belum ada data kehadiran'
                                  : 'Tidak ada data yang cocok',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await provider.loadAllConfirmations();
                        },
                        child: ListView.builder(
                          itemCount: filteredConfirmations.length,
                          itemBuilder: (context, index) =>
                              _buildConfirmationTile(
                            filteredConfirmations[index],
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
