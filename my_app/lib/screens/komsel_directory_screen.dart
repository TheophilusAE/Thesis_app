import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/komsel.dart';
import '../providers/komsel_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_empty_state.dart';
import '../widgets/common/app_skeleton.dart';

class KomselDirectoryScreen extends StatefulWidget {
  const KomselDirectoryScreen({super.key});

  @override
  State<KomselDirectoryScreen> createState() => _KomselDirectoryScreenState();
}

class _KomselDirectoryScreenState extends State<KomselDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KomselProvider>().loadActiveKomsel();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDetail(Komsel komsel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.neutralLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.groups_rounded, color: AppTheme.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        komsel.nama,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkCharcoal,
                        ),
                      ),
                      Text(
                        'Wilayah: ${komsel.wilayah}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (komsel.description.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.warmIvory,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.neutralBorder),
                ),
                child: Text(
                  komsel.description,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppTheme.darkCharcoal,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _buildDetailRow(
              icon: Icons.person_rounded,
              label: 'Pemimpin Komsel',
              value: komsel.leaderName,
            ),
            _buildDetailRow(
              icon: Icons.schedule_rounded,
              label: 'Jadwal Pertemuan',
              value: komsel.meetingSchedule,
            ),
            _buildDetailRow(
              icon: Icons.location_on_rounded,
              label: 'Lokasi Persekutuan',
              value: komsel.location,
            ),
            const SizedBox(height: 20),
            if (komsel.leaderPhone.isNotEmpty)
              AppButton(
                label: 'Hubungi via WhatsApp',
                icon: Icons.chat_bubble_rounded,
                color: const Color(0xFF25D366),
                textColor: Colors.white,
                onPressed: () => _contactViaWhatsApp(komsel.leaderPhone),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.neutralLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppTheme.darkCharcoal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppTheme.neutralMedium, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppTheme.darkCharcoal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _contactViaWhatsApp(String phone) async {
    var sanitized = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (sanitized.startsWith('0')) {
      sanitized = '62${sanitized.substring(1)}';
    }
    final uri = Uri.parse('https://wa.me/$sanitized');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmIvory,
      appBar: AppBar(
        title: const Text('Komsel / Kelompok Sel'),
      ),
      body: Consumer<KomselProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return _buildLoadingSkeleton();
          }

          var items = provider.activeKomsel;
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            items = items.where((k) {
              return k.nama.toLowerCase().contains(query) ||
                  k.wilayah.toLowerCase().contains(query) ||
                  k.leaderName.toLowerCase().contains(query) ||
                  k.location.toLowerCase().contains(query);
            }).toList();
          }

          return RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: provider.loadActiveKomsel,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                // Info Header
                _buildHeaderBanner(),

                const SizedBox(height: 16),

                // Search Bar
                _buildSearchBar(),

                const SizedBox(height: 16),

                if (items.isEmpty)
                  AppEmptyState(
                    icon: Icons.groups_outlined,
                    title: _searchQuery.isNotEmpty
                        ? 'Komsel Tidak Ditemukan'
                        : 'Belum ada komsel yang terdaftar',
                    description: _searchQuery.isNotEmpty
                        ? 'Tidak ada komsel yang cocok dengan kata kunci "$_searchQuery".'
                        : 'Belum ada kelompok sel yang terdaftar aktif saat ini.',
                  )
                else
                  ...items.map((komsel) => _buildKomselCard(komsel)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline_rounded, color: AppTheme.primary, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bertumbuh Bersama Komsel',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.primaryDark,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Temukan komunitas persekutuan di sekitar wilayah domisili Anda untuk saling mendukung dalam iman.',
                  style: TextStyle(
                    color: AppTheme.primaryDark,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neutralBorder),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        decoration: InputDecoration(
          hintText: 'Cari nama komsel, wilayah, atau pemimpin...',
          hintStyle: const TextStyle(color: AppTheme.neutralMedium, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.neutralMedium, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildKomselCard(Komsel komsel) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        onTap: () => _showDetail(komsel),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    komsel.nama,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkCharcoal,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.goldLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.gold.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    komsel.wilayah,
                    style: const TextStyle(
                      color: AppTheme.goldDark,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 16, color: AppTheme.neutralMedium),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Pemimpin: ${komsel.leaderName}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.darkCharcoal,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.neutralMedium),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    komsel.meetingSchedule,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.darkCharcoal,
                    ),
                  ),
                ),
              ],
            ),
            if (komsel.location.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.neutralMedium),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      komsel.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.neutralMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ketuk untuk info selengkapnya',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (komsel.leaderPhone.isNotEmpty)
                  GestureDetector(
                    onTap: () => _contactViaWhatsApp(komsel.leaderPhone),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.chat_bubble_rounded, size: 14, color: Color(0xFF1E8E3E)),
                          SizedBox(width: 4),
                          Text(
                            'WhatsApp',
                            style: TextStyle(
                              color: Color(0xFF1E8E3E),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: const [
          AppSkeleton(height: 70, borderRadius: BorderRadius.all(Radius.circular(16))),
          SizedBox(height: 16),
          AppSkeleton(height: 46, borderRadius: BorderRadius.all(Radius.circular(12))),
          SizedBox(height: 16),
          AppSkeleton(height: 130, borderRadius: BorderRadius.all(Radius.circular(16))),
          SizedBox(height: 12),
          AppSkeleton(height: 130, borderRadius: BorderRadius.all(Radius.circular(16))),
          SizedBox(height: 12),
          AppSkeleton(height: 130, borderRadius: BorderRadius.all(Radius.circular(16))),
        ],
      ),
    );
  }
}
