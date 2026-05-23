import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/feedback.dart' as fb;
import '../providers/feedback_provider.dart';
import '../services/feedback_service.dart';
import '../utils/app_theme.dart';

class FeedbackManagementScreen extends StatefulWidget {
  const FeedbackManagementScreen({super.key});

  @override
  State<FeedbackManagementScreen> createState() =>
      _FeedbackManagementScreenState();
}

class _FeedbackManagementScreenState extends State<FeedbackManagementScreen> {
  final FeedbackService _feedbackService = FeedbackService();
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
      appBar: AppBar(
        title: const Text('Manajemen Feedback'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
      ),
      body: Consumer<FeedbackProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Filter and Sort Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type Filter
                    Text(
                      'Filter Tipe Feedback',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('Semua'),
                            selected: _selectedType == null,
                            onSelected: (_) {
                              setState(() {
                                _selectedType = null;
                              });
                              provider.filterByType(null);
                            },
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Event'),
                            selected: _selectedType == 'event',
                            onSelected: (_) {
                              setState(() {
                                _selectedType = 'event';
                              });
                              provider.filterByType('event');
                            },
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Fasilitas'),
                            selected: _selectedType == 'facility',
                            onSelected: (_) {
                              setState(() {
                                _selectedType = 'facility';
                              });
                              provider.filterByType('facility');
                            },
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Hospitality'),
                            selected: _selectedType == 'hospitality',
                            onSelected: (_) {
                              setState(() {
                                _selectedType = 'hospitality';
                              });
                              provider.filterByType('hospitality');
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sort Options
                    Text(
                      'Urutkan Berdasarkan',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: _sortBy,
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
                        setState(() {
                          _sortBy = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),

              // Feedback List
              Expanded(
                child: provider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : provider.filteredFeedback.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.feedback_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Tidak ada feedback',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _sortFeedback(provider.filteredFeedback)
                                .length,
                            itemBuilder: (context, index) {
                              final feedback =
                                  _sortFeedback(provider.filteredFeedback)[index];
                              return FeedbackCard(
                                feedback: feedback,
                                onDelete: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Hapus Feedback'),
                                      content: const Text(
                                        'Apakah Anda yakin ingin menghapus feedback ini?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Batal'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Hapus'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmed == true) {
                                    await provider
                                        .deleteFeedback(feedback.id);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Feedback berhasil dihapus'),
                                        ),
                                      );
                                    }
                                  }
                                },
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Chip(
                      label: Text(_getFeedbackTypeLabel(feedback.feedbackType)),
                      backgroundColor: _getChipColor(feedback.feedbackType),
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    if (feedback.eventName != null)
                      Text(
                        'Event: ${feedback.eventName}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Rating
            Row(
              children: [
                for (int i = 0; i < 5; i++)
                  Icon(
                    i < feedback.rating ? Icons.star : Icons.star_border,
                    color: i < feedback.rating ? Colors.amber : Colors.grey,
                    size: 18,
                  ),
                const SizedBox(width: 8),
                Text(
                  '${feedback.rating}/5',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                feedback.message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 12),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feedback.isAnonymous ? 'Anonymous' : feedback.userName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm')
                          .format(feedback.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
                if (feedback.isAnonymous)
                  Chip(
                    label: const Text('Anonymous'),
                    avatar: const Icon(Icons.privacy_tip, size: 18),
                    backgroundColor: Colors.grey[200],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getChipColor(String type) {
    switch (type) {
      case 'event':
        return Colors.blue;
      case 'facility':
        return Colors.orange;
      case 'hospitality':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
