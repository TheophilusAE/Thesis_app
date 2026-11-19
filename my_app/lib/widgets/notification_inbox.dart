import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/notification.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../services/notification_router.dart';
import '../utils/app_theme.dart';

/// Inbox sheet opened from the bell: category filter, swipe to delete,
/// tap to open the related page. Notifications are never deleted
/// automatically — only by the user here (or a Super Admin clean-up).
Future<void> showNotificationInbox(BuildContext context) {
  final userId = context.read<AuthProvider>().currentUser?.id;
  if (userId != null) context.read<NotificationProvider>().loadNotifications(userId);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scroll) => NotificationInbox(userId: userId, scrollController: scroll),
    ),
  );
}

class NotificationInbox extends StatefulWidget {
  final String? userId;
  final ScrollController? scrollController;

  const NotificationInbox({super.key, required this.userId, this.scrollController});

  @override
  State<NotificationInbox> createState() => _NotificationInboxState();
}

class _NotificationInboxState extends State<NotificationInbox> {
  String? _category; // null = semua

  Future<void> _open(NotificationProvider np, AppNotification n) async {
    if (!n.isRead) np.markAsRead(n.id);
    final navigator = Navigator.of(context);
    navigator.pop(); // close the sheet, then open the page
    await NotificationRouter.openNotification(n, navigator: navigator);
  }

  @override
  Widget build(BuildContext context) {
    final np = context.watch<NotificationProvider>();
    final theme = Theme.of(context);
    final items = np.allNotifications.where((n) => _category == null || n.category == _category).toList();
    final userId = widget.userId;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Notifikasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              if (np.unreadCount > 0 && userId != null)
                TextButton(
                  onPressed: () async {
                    final ok = await np.markAllAsRead(userId);
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gagal menandai notifikasi.')),
                      );
                    }
                  },
                  child: const Text('Tandai semua dibaca'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('Semua', null, np.allNotifications.length),
                for (final c in NotificationCategory.all)
                  _chip(NotificationCategory.label(c), c,
                      np.allNotifications.where((n) => n.category == c).length),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: np.isLoading && np.allNotifications.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? ListView(
                        controller: widget.scrollController,
                        children: [
                          const SizedBox(height: 40),
                          Icon(Icons.notifications_none_rounded, size: 48, color: theme.disabledColor),
                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              _category == null
                                  ? 'Belum ada notifikasi'
                                  : 'Belum ada notifikasi ${NotificationCategory.label(_category!)}',
                              style: TextStyle(color: theme.disabledColor),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        controller: widget.scrollController,
                        itemCount: items.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          if (i == items.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('Geser ke kiri untuk menghapus notifikasi.',
                                  textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
                            );
                          }
                          final n = items[i];
                          return Dismissible(
                            key: ValueKey(n.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.onErrorContainer),
                            ),
                            confirmDismiss: (_) => np.deleteNotification(n.id),
                            child: _NotificationTile(n: n, onTap: () => _open(np, n)),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String? value, int count) {
    final selected = _category == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(count > 0 ? '$label ($count)' : label),
        selected: selected,
        onSelected: (_) => setState(() => _category = value),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification n;
  final VoidCallback onTap;
  const _NotificationTile({required this.n, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.color;
    return Material(
      color: n.isRead ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5) : AppTheme.secondary.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(NotificationCategory.icon(n.category), color: n.isRead ? muted : AppTheme.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(n.message, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: muted)),
                    const SizedBox(height: 4),
                    Text(
                      '${NotificationCategory.label(n.category)} • ${DateFormat('dd MMM yyyy • HH:mm', 'id_ID').format(n.createdAt.toLocal())}',
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}
