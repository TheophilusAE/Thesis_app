import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/auth_provider.dart';
import '../providers/feedback_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_card.dart';

class FeedbackScreen extends StatefulWidget {
  final ChurchEvent? event;
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
  final TextEditingController _messageController = TextEditingController();
  int _rating = 5;
  bool _isAnonymous = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submitFeedback() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon tuliskan pesan feedback Anda')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi pengguna tidak valid')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await context.read<FeedbackProvider>().submitFeedback(
            userId: user.id,
            userName: user.name,
            feedbackType: widget.feedbackType,
            eventId: widget.event?.id,
            eventName: widget.event?.title,
            rating: _rating,
            message: message,
            isAnonymous: _isAnonymous,
          );

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Terima kasih! Masukan Anda sangat berharga bagi kemajuan pelayanan gereja.'),
              backgroundColor: AppTheme.emerald,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mengirim feedback. Silakan coba lagi.'),
              backgroundColor: AppTheme.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    }
  }

  String _getFeedbackTitle() {
    switch (widget.feedbackType) {
      case 'event':
        return widget.event?.title != null
            ? 'Feedback: ${widget.event!.title}'
            : 'Feedback Kegiatan';
      case 'facility':
        return 'Saran & Fasilitas Gereja';
      case 'hospitality':
        return 'Layanan Penyambutan & Usher';
      default:
        return 'Kritik & Saran Membangun';
    }
  }

  String _getFeedbackSubtitle() {
    switch (widget.feedbackType) {
      case 'event':
        return 'Bagikan pengalaman dan kesan Anda selama mengikuti kegiatan ini untuk evaluasi kami.';
      case 'facility':
        return 'Bantu kami meningkatkan kenyamanan fasilitas ibadah (sound system, AC, kebersihan, dll).';
      case 'hospitality':
        return 'Ceritakan pengalaman penyambutan dan keramahan pelayan jemaat saat Anda hadir.';
      default:
        return 'Suara dan aspirasi Anda sangat berarti demi pertumbuhan jemaat GPDI.';
    }
  }

  String _getRatingSentiment(int rating) {
    switch (rating) {
      case 1:
        return 'Sangat Perlu Ditingkatkan';
      case 2:
        return 'Kurang Memuaskan';
      case 3:
        return 'Cukup Baik';
      case 4:
        return 'Baik & Memberkati';
      case 5:
        return 'Luar Biasa & Sangat Memberkati!';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmIvory,
      appBar: AppBar(
        title: Text(_getFeedbackTitle()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intro Banner
            Container(
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
                    child: const Icon(Icons.rate_review_outlined, color: AppTheme.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _getFeedbackSubtitle(),
                      style: const TextStyle(
                        color: AppTheme.primaryDark,
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Form Card
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bagaimana Penilaian Anda?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.darkCharcoal,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Rating Stars Row
                  Center(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 1; i <= 5; i++)
                              IconButton(
                                iconSize: 38,
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  setState(() => _rating = i);
                                },
                                icon: Icon(
                                  _rating >= i ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: _rating >= i ? AppTheme.goldDark : AppTheme.neutralMedium,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.goldLight.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getRatingSentiment(_rating),
                            style: const TextStyle(
                              color: AppTheme.goldDark,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Message Input
                  const Text(
                    'Saran & Masukan',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppTheme.neutralMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _messageController,
                    maxLines: 5,
                    style: const TextStyle(fontSize: 14, color: AppTheme.darkCharcoal),
                    decoration: InputDecoration(
                      hintText: 'Tuliskan tanggapan, kritik membangun, atau apresiasi Anda...',
                      hintStyle: const TextStyle(color: AppTheme.neutralMedium, fontSize: 13),
                      filled: true,
                      fillColor: AppTheme.warmIvory,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.neutralBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.neutralBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Anonymous Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.warmIvory,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.neutralBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.visibility_off_outlined, color: AppTheme.neutralMedium, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kirim sebagai Anonim',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              Text(
                                'Identitas Anda tidak akan ditampilkan ke pengurus',
                                style: TextStyle(color: AppTheme.neutralMedium, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _isAnonymous,
                          activeTrackColor: AppTheme.primary,
                          onChanged: (val) => setState(() => _isAnonymous = val),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Submit Button
                  AppButton(
                    label: 'Kirim Feedback',
                    icon: Icons.send_rounded,
                    isLoading: _isLoading,
                    onPressed: _submitFeedback,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeedbackDialog extends StatefulWidget {
  final ChurchEvent? event;
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
  final TextEditingController _messageController = TextEditingController();
  int _rating = 5;
  bool _isAnonymous = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submitFeedback() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
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

    setState(() => _isLoading = true);

    try {
      final success = await context.read<FeedbackProvider>().submitFeedback(
            userId: user.id,
            userName: user.name,
            feedbackType: widget.feedbackType,
            eventId: widget.event?.id,
            eventName: widget.event?.title,
            rating: _rating,
            message: message,
            isAnonymous: _isAnonymous,
          );

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.rate_review_outlined, color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Berikan Masukan',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkCharcoal,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 1; i <= 5; i++)
                      IconButton(
                        iconSize: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(() => _rating = i),
                        icon: Icon(
                          _rating >= i ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: _rating >= i ? AppTheme.goldDark : AppTheme.neutralMedium,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _messageController,
                maxLines: 4,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Tulis saran atau evaluasi Anda...',
                  hintStyle: const TextStyle(color: AppTheme.neutralMedium, fontSize: 13),
                  filled: true,
                  fillColor: AppTheme.warmIvory,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.neutralBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.neutralBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _isAnonymous,
                    activeColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (v) => setState(() => _isAnonymous = v ?? false),
                  ),
                  const Text('Kirim Anonim', style: TextStyle(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Batal', style: TextStyle(color: AppTheme.neutralMedium)),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    label: 'Kirim',
                    isLoading: _isLoading,
                    onPressed: _submitFeedback,
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
