import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/user.dart';
import '../providers/checkin_provider.dart';
import '../providers/group_provider.dart';

/// The member's card QR (with its server-issued secret). Shows a spinner
/// while loading and a small hint instead of a broken QR on failure.
class MemberQrImage extends StatefulWidget {
  final User user;
  final double size;

  const MemberQrImage({super.key, required this.user, this.size = 108});

  @override
  State<MemberQrImage> createState() => _MemberQrImageState();
}

class _MemberQrImageState extends State<MemberQrImage> {
  late Future<String> _data;

  @override
  void initState() {
    super.initState();
    _data = context.read<CheckinProvider>().memberQrData(userId: widget.user.id, name: widget.user.name);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: FutureBuilder<String>(
        future: _data,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          if (snap.hasError) {
            return const Center(
              child: Text('QR belum tersedia', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.black54)),
            );
          }
          return QrImageView(
            data: snap.data!,
            version: QrVersions.auto,
            size: widget.size,
            backgroundColor: Colors.white,
            padding: EdgeInsets.zero,
          );
        },
      ),
    );
  }
}

/// Name of the member's Group (users.group_id), loading groups on demand.
class GroupNameText extends StatefulWidget {
  final String? groupId;
  final TextStyle? style;

  const GroupNameText({super.key, required this.groupId, this.style});

  @override
  State<GroupNameText> createState() => _GroupNameTextState();
}

class _GroupNameTextState extends State<GroupNameText> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<GroupProvider>();
    if (widget.groupId != null && provider.groupById(widget.groupId) == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) provider.loadActiveGroups();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = context.watch<GroupProvider>().groupById(widget.groupId);
    return Text(widget.groupId == null ? '-' : (group?.nama ?? '…'), style: widget.style);
  }
}
