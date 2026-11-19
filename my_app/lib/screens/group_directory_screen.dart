import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/church_group.dart';
import '../providers/group_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_empty_state.dart';
import '../widgets/common/app_skeleton.dart';

class GroupDirectoryScreen extends StatefulWidget {
  const GroupDirectoryScreen({super.key});

  @override
  State<GroupDirectoryScreen> createState() => _GroupDirectoryScreenState();
}

class _GroupDirectoryScreenState extends State<GroupDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _categoryFilter; // null = all categories

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GroupProvider>();
      provider.loadActiveGroups();
      provider.loadCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDetail(ChurchGroup churchGroup) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
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
                  child: Icon(Icons.groups_rounded, color: AppTheme.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        churchGroup.nama,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkCharcoal,
                        ),
                      ),
                      Text(
                        'Wilayah: ${churchGroup.wilayah}',
                        style: TextStyle(
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
            if (churchGroup.description.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.warmIvory,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.neutralBorder),
                ),
                child: Text(
                  churchGroup.description,
                  style: TextStyle(
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
              label: 'Pemimpin Group',
              value: churchGroup.leaderName,
            ),
            _buildDetailRow(
              icon: Icons.schedule_rounded,
              label: 'Jadwal Pertemuan',
              value: churchGroup.meetingSchedule,
            ),
            _buildDetailRow(
              icon: Icons.location_on_rounded,
              label: 'Lokasi Persekutuan',
              value: churchGroup.location,
            ),
            const SizedBox(height: 20),
            if (churchGroup.leaderPhone.isNotEmpty)
              AppButton(
                label: 'Hubungi via WhatsApp',
                icon: Icons.chat_bubble_rounded,
                color: const Color(0xFF25D366),
                textColor: Colors.white,
                onPressed: () => _contactViaWhatsApp(churchGroup.leaderPhone),
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
                  style: TextStyle(color: AppTheme.neutralMedium, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
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
        title: const Text('Group'),
      ),
      body: Consumer<GroupProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return _buildLoadingSkeleton();
          }

          var items = provider.activeGroups;
          if (_categoryFilter != null) {
            items = items.where((g) => g.categoryId == _categoryFilter).toList();
          }
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
            onRefresh: provider.loadActiveGroups,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                // Info Header
                _buildHeaderBanner(),

                const SizedBox(height: 16),

                // Search Bar
                _buildSearchBar(),

                if (provider.categories.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Semua'),
                        selected: _categoryFilter == null,
                        onSelected: (_) => setState(() => _categoryFilter = null),
                      ),
                      for (final c in provider.categories)
                        ChoiceChip(
                          label: Text(groupCategoryLabel(c)),
                          selected: _categoryFilter == c.id,
                          onSelected: (_) => setState(() => _categoryFilter = c.id),
                        ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                if (items.isEmpty)
                  AppEmptyState(
                    icon: Icons.groups_outlined,
                    title: _searchQuery.isNotEmpty
                        ? 'Group Tidak Ditemukan'
                        : 'Belum ada group yang terdaftar',
                    description: _searchQuery.isNotEmpty
                        ? 'Tidak ada group yang cocok dengan kata kunci "$_searchQuery".'
                        : 'Belum ada group yang terdaftar aktif saat ini.',
                  )
                else
                  ...items.map((churchGroup) => _buildGroupCard(churchGroup)),
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
            child: Icon(Icons.people_outline_rounded, color: AppTheme.primary, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bertumbuh Bersama Group',
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
        color: AppTheme.surface,
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
          hintText: 'Cari nama group, wilayah, atau pemimpin...',
          hintStyle: TextStyle(color: AppTheme.neutralMedium, fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded, color: AppTheme.neutralMedium, size: 20),
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

  Widget _buildGroupCard(ChurchGroup churchGroup) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        onTap: () => _showDetail(churchGroup),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        churchGroup.nama,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkCharcoal,
                        ),
                      ),
                      if (churchGroup.categoryId != null)
                        Text(
                          context.read<GroupProvider>().categoryLabel(churchGroup.categoryId),
                          style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600),
                        ),
                    ],
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
                    churchGroup.wilayah,
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
                Icon(Icons.person_outline_rounded, size: 16, color: AppTheme.neutralMedium),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Pemimpin: ${churchGroup.leaderName}',
                    style: TextStyle(
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
                Icon(Icons.access_time_rounded, size: 16, color: AppTheme.neutralMedium),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    churchGroup.meetingSchedule,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.darkCharcoal,
                    ),
                  ),
                ),
              ],
            ),
            if (churchGroup.location.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: AppTheme.neutralMedium),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      churchGroup.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
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
                Text(
                  'Ketuk untuk info selengkapnya',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (churchGroup.leaderPhone.isNotEmpty)
                  GestureDetector(
                    onTap: () => _contactViaWhatsApp(churchGroup.leaderPhone),
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
