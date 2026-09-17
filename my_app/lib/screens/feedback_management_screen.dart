import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/feedback.dart' as fb;
import '../providers/feedback_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_empty_state.dart';

class FeedbackManagementScreen extends StatefulWidget {
  const FeedbackManagementScreen({super.key});

  @override
  State<FeedbackManagementScreen> createState() =>
      _FeedbackManagementScreenState();
}

class _FeedbackManagementScreenState extends State<FeedbackManagementScreen> {
  String? _selectedType;
  String? _sortBy = 'latest'; // latest, oldest, rating_high, rating_low

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedbackProvider>().loadAllFeedback();
    });
  }

  List<fb.UserFeedback> _sortFeedback(List<fb.UserFeedback> feedback) {
    List<fb.UserFeedback> sorted = [...feedback];

    switch (_sortBy) {
      case 'latest':
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'rating_high':
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'rating_low':
        sorted.sort((a, b) => a.rating.compareTo(b.rating));
        break;
    }

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmIvory,
      appBar: AppBar(
        title: const Text(
          'Manajemen Feedback',
          style: TextStyle(
            color: AppTheme.darkCharcoal,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkCharcoal,
        elevation: 0,
      ),
      body: Consumer<FeedbackProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Filter and Sort Section
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type Filter
                    const Text(
                      'Filter Kategori',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkCharcoal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'Semua',
                            selected: _selectedType == null,
                            onSelected: () {
                              setState(() => _selectedType = null);
                              provider.filterByType(null);
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Event',
                            selected: _selectedType == 'event',
                            onSelected: () {
                              setState(() => _selectedType = 'event');
                              provider.filterByType('event');
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Fasilitas',
                            selected: _selectedType == 'facility',
                            onSelected: () {
                              setState(() => _selectedType = 'facility');
                              provider.filterByType('facility');
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Hospitality',
                            selected: _selectedType == 'hospitality',
                            onSelected: () {
                              setState(() => _selectedType = 'hospitality');
                              provider.filterByType('hospitality');
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Sort Options
                    Row(
                      children: [
                        const Text(
                          'Urutkan:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.mutedCharcoal,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.warmIvory,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.neutralBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _sortBy,
                                isDense: true,
                                icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primary),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.darkCharcoal,
                                  fontWeight: FontWeight.w600,
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'latest', child: Text('Terbaru')),
                                  DropdownMenuItem(value: 'oldest', child: Text('Tertua')),
                                  DropdownMenuItem(
                                    value: 'rating_high',
                                    child: Text('Rating Tertinggi'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'rating_low',
                                    child: Text('Rating Terendah'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() => _sortBy = value);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.neutralBorder),

              // Feedback List
              Expanded(
                child: provider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppTheme.primary),
                      )
                    : provider.filteredFeedback.isEmpty
                        ? AppEmptyState(
                            icon: Icons.feedback_outlined,
                            title: 'Tidak Ada Feedback',
                            message: _selectedType == null
                                ? 'Belum ada feedback yang masuk dari jemaat.'
                                : 'Tidak ada feedback untuk kategori "$_selectedType".',
                          )
                        : RefreshIndicator(
                            onRefresh: provider.loadAllFeedback,
                            color: AppTheme.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _sortFeedback(provider.filteredFeedback).length,
                              itemBuilder: (context, index) {
                                final feedback =
                                    _sortFeedback(provider.filteredFeedback)[index];
                                return FeedbackCard(
                                  feedback: feedback,
                                  onDelete: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        title: const Text(
                                          'Hapus Feedback',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        content: const Text(
                                          'Apakah Anda yakin ingin menghapus feedback ini?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text(
                                              'Batal',
                                              style: TextStyle(color: AppTheme.mutedCharcoal),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.errorColor,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text('Hapus'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmed == true) {
                                      await provider.deleteFeedback(feedback.id);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Feedback berhasil dihapus'),
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
        color: selected ? Colors.white : AppTheme.darkCharcoal,
      ),
      backgroundColor: Colors.grey.shade100,
      selectedColor: AppTheme.primary,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? AppTheme.primary : AppTheme.neutralBorder,
        ),
      ),
      onSelected: (_) => onSelected(),
    );
  }
}

class FeedbackCard extends StatelessWidget {
  final fb.UserFeedback feedback;
  final VoidCallback onDelete;

  const FeedbackCard({
    super.key,
    required this.feedback,
    required this.onDelete,
  });

  String _getFeedbackTypeLabel(String type) {
    switch (type) {
      case 'event':
        return 'Event Feedback';
      case 'facility':
        return 'Fasilitas';
      case 'hospitality':
        return 'Hospitality';
      default:
        return type;
    }
  }

  Color _getBadgeBgColor(String type) {
    switch (type) {
      case 'event':
        return const Color(0xFF1E3A8A).withValues(alpha: 0.1);
      case 'facility':
        return AppTheme.gold.withValues(alpha: 0.15);
      case 'hospitality':
        return AppTheme.successColor.withValues(alpha: 0.1);
      default:
        return Colors.grey.withValues(alpha: 0.1);
    }
  }

  Color _getBadgeTextColor(String type) {
    switch (type) {
      case 'event':
        return const Color(0xFF1E3A8A);
      case 'facility':
        return const Color(0xFFB45309);
      case 'hospitality':
        return AppTheme.successColor;
      default:
        return AppTheme.darkCharcoal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getBadgeBgColor(feedback.feedbackType),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getBadgeTextColor(feedback.feedbackType).withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  _getFeedbackTypeLabel(feedback.feedbackType),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _getBadgeTextColor(feedback.feedbackType),
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor, size: 20),
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
              ),
            ],
          ),
          if (feedback.eventName != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.event_rounded, size: 14, color: AppTheme.mutedCharcoal),
                const SizedBox(width: 4),
                Text(
                  'Event: ${feedback.eventName}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.mutedCharcoal,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),

          // Rating Stars
          Row(
            children: [
              for (int i = 0; i < 5; i++)
                Icon(
                  i < feedback.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: i < feedback.rating ? AppTheme.gold : Colors.grey.shade300,
                  size: 20,
                ),
              const SizedBox(width: 8),
              Text(
                '${feedback.rating}/5',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkCharcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Message Content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warmIvory,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.neutralBorder),
            ),
            child: Text(
              feedback.message,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppTheme.darkCharcoal,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: feedback.isAnonymous
                        ? Colors.grey.shade200
                        : AppTheme.primary.withValues(alpha: 0.1),
                    child: Icon(
                      feedback.isAnonymous ? Icons.visibility_off_rounded : Icons.person_rounded,
                      size: 13,
                      color: feedback.isAnonymous ? AppTheme.mutedCharcoal : AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    feedback.isAnonymous ? 'Anonim' : feedback.userName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkCharcoal,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 13, color: AppTheme.mutedCharcoal),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(feedback.createdAt),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.mutedCharcoal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

