import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/feedback.dart' as fb;
import '../models/event.dart';
import '../providers/auth_provider.dart';
import '../services/feedback_service.dart';
import '../utils/app_theme.dart';

class FeedbackScreen extends StatefulWidget {
  final Event? event;
  final String feedbackType; // 'event', 'facility', 'hospitality'

  const FeedbackScreen({
    super.key,
    this.event,
    required this.feedbackType,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final FeedbackService _feedbackService = FeedbackService();
  final TextEditingController _messageController = TextEditingController();
  int _rating = 4;
  bool _isAnonymous = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submitFeedback() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon isi pesan feedback')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User tidak teridentifikasi')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final feedback = fb.UserFeedback(
        id: const Uuid().v4(),
        userId: user.id,
        userName: _isAnonymous ? 'Anonymous' : user.name,
        feedbackType: widget.feedbackType,
        eventId: widget.event?.id,
        eventName: widget.event?.name,
        rating: _rating,
        message: _messageController.text.trim(),
        createdAt: DateTime.now(),
        isAnonymous: _isAnonymous,
      );

      final success = await _feedbackService.submitFeedback(feedback);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Terima kasih! Feedback berhasil dikirim'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mengirim feedback'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _getFeedbackTitle() {
    switch (widget.feedbackType) {
      case 'event':
        return 'Feedback Event: ${widget.event?.name}';
      case 'facility':
        return 'Feedback Fasilitas Gereja';
      case 'hospitality':
        return 'Feedback Hospitality Gereja';
      default:
        return 'Feedback';
    }
  }

  String _getFeedbackSubtitle() {
    switch (widget.feedbackType) {
      case 'event':
        return 'Bagikan pengalaman Anda tentang event ini';
      case 'facility':
        return 'Bagikan saran untuk perbaikan fasilitas gereja';
      case 'hospitality':
        return 'Bagikan pengalaman Anda tentang layanan hospitality';
      default:
        return 'Bagikan feedback Anda';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getFeedbackTitle()),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subtitle
            Text(
              _getFeedbackSubtitle(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),

            // Rating Section
            Text(
              'Rating',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                for (int i = 1; i <= 5; i++)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _rating = i;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        _rating >= i ? Icons.star : Icons.star_border,
                        color: _rating >= i ? Colors.amber : Colors.grey,
                        size: 32,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Message Section
            Text(
              'Pesan Feedback',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Tulis feedback Anda di sini...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Anonymous Option
            CheckboxListTile(
              title: const Text('Kirim sebagai Anonymous'),
              subtitle: const Text('Identitas Anda tidak akan ditampilkan'),
              value: _isAnonymous,
              onChanged: (value) {
                setState(() {
                  _isAnonymous = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Kirim Feedback',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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

class FeedbackDialog extends StatefulWidget {
  final Event? event;
  final String feedbackType;

  const FeedbackDialog({
    super.key,
    this.event,
    required this.feedbackType,
  });

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  final FeedbackService _feedbackService = FeedbackService();
  final TextEditingController _messageController = TextEditingController();
  int _rating = 4;
  bool _isAnonymous = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submitFeedback() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon isi pesan feedback')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final feedback = fb.UserFeedback(
        id: const Uuid().v4(),
        userId: user.id,
        userName: _isAnonymous ? 'Anonymous' : user.name,
        feedbackType: widget.feedbackType,
        eventId: widget.event?.id,
        eventName: widget.event?.name,
        rating: _rating,
        message: _messageController.text.trim(),
        createdAt: DateTime.now(),
        isAnonymous: _isAnonymous,
      );

      final success = await _feedbackService.submitFeedback(feedback);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Berikan Feedback',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Rating:',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (int i = 1; i <= 5; i++)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _rating = i;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          _rating >= i ? Icons.star : Icons.star_border,
                          color: _rating >= i ? Colors.amber : Colors.grey,
                          size: 28,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Tulis feedback Anda...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text('Anonymous'),
                value: _isAnonymous,
                onChanged: (value) {
                  setState(() {
                    _isAnonymous = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Kirim'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
