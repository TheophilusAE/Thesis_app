/// One row of `public.admin_permissions`: what an Admin may do in one
/// module, optionally limited to one administrative category.
///
/// `categoryId == null` means the grant applies to every category.
class AdminPermission {
  final String? id;
  final String userId;
  final String module;
  final String? categoryId;
  final bool canCreate;
  final bool canRead;
  final bool canApprove;

  const AdminPermission({
    this.id,
    required this.userId,
    required this.module,
    this.categoryId,
    this.canCreate = false,
    this.canRead = false,
    this.canApprove = false,
  });

  bool get isEmpty => !canCreate && !canRead && !canApprove;

  factory AdminPermission.fromJson(Map<String, dynamic> json) {
    return AdminPermission(
      id: json['id'] as String?,
      userId: (json['user_id'] ?? '') as String,
      module: (json['module'] ?? '') as String,
      categoryId: json['category_id'] as String?,
      canCreate: (json['can_create'] ?? false) as bool,
      canRead: (json['can_read'] ?? false) as bool,
      canApprove: (json['can_approve'] ?? false) as bool,
    );
  }

  /// Shape expected by the `set_admin_permissions` RPC.
  Map<String, dynamic> toGrantJson() => {
        'module': module,
        'category_id': categoryId,
        'can_create': canCreate,
        'can_read': canRead,
        'can_approve': canApprove,
      };

  AdminPermission copyWith({
    bool? canCreate,
    bool? canRead,
    bool? canApprove,
  }) {
    return AdminPermission(
      id: id,
      userId: userId,
      module: module,
      categoryId: categoryId,
      canCreate: canCreate ?? this.canCreate,
      canRead: canRead ?? this.canRead,
      canApprove: canApprove ?? this.canApprove,
    );
  }
}
