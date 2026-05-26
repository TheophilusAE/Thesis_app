# Dokumentasi Teknis - Sistem Multi-Role

## Daftar Isi
1. [Arsitektur Sistem](#arsitektur-sistem)
2. [Model Data](#model-data)
3. [Layanan (Services)](#layanan-services)
4. [State Management (Providers)](#state-management-providers)
5. [Alur Kerja Substitusi](#alur-kerja-substitusi)
6. [Alur Kerja Konfirmasi Kehadiran](#alur-kerja-konfirmasi-kehadiran)
7. [Fitur Pemindahan Peran](#fitur-pemindahan-peran)
8. [Notifikasi Sistem](#notifikasi-sistem)

---

## Arsitektur Sistem

### Lapisan Arsitektur

```
UI Layer (Screens)
        ↓
State Management (Providers)
        ↓
Services Layer
        ↓
Data Storage (SharedPreferences)
```

### Teknologi Utama
- **Framework**: Flutter dengan Material Design 3
- **State Management**: Provider 6.x dengan ChangeNotifier pattern
- **Penyimpanan Data**: SharedPreferences (local persistence)
- **Serialisasi**: JSON dengan factory constructors
- **ID Generation**: UUID v4
- **Localization**: intl package (Indonesian locale)

---

## Model Data

### User Model

**File:** `lib/models/user.dart`

```dart
class User {
  final String id;
  final String name;
  final String email;
  final List<String> roles;  // NEW: Multi-role support
  final String? phone;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Helper methods
  bool hasRole(String role) => roles.contains(role);
  bool hasAnyRole(List<String> checkRoles) => 
    roles.any((r) => checkRoles.contains(r));
  
  // Convenience getters
  bool get isAdmin => hasRole('admin');
  bool get isPelayan => hasRole('pelayan');
  bool get isJemaat => hasRole('jemaat');
}
```

**Perubahan:**
- Dari: `role: String` (single role)
- Ke: `roles: List<String>` (multiple roles)
- **Backward Compatibility**: `fromJson` factory menangani kedua format

### SubstitutionRequest Model

**File:** `lib/models/substitution_request.dart`

```dart
class SubstitutionRequest {
  final String id;                      // UUID v4
  final String serviceScheduleId;       // Referensi ke jadwal
  final String requestedByUserId;       // Pelayan yang minta
  final String requestedByName;         // Nama pelayan
  final String? replacementUserId;      // Pelayan pengganti (setelah disetujui)
  final String? replacementName;        // Nama pengganti
  final String reason;                  // Alasan substitusi
  final String status;                  // pending|approved|rejected|completed
  final String? adminNotes;             // Catatan dari admin
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? reviewedAt;           // Kapan admin menanggapi
  final String? reviewedByAdminId;      // Admin yang meninjau
}
```

### AttendanceConfirmation Model

**File:** `lib/models/attendance_confirmation.dart`

```dart
class AttendanceConfirmation {
  final String id;                  // UUID v4
  final String userId;              // Pelayan
  final String userName;            // Nama pelayan
  final String serviceScheduleId;   // Referensi jadwal
  final DateTime scheduleDate;      // Tanggal jadwal
  final bool confirmed;             // true/false
  final DateTime? confirmedAt;      // Kapan dikonfirmasi
  final String? notes;              // Catatan pelayan
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

---

## Layanan (Services)

### AuthService

**File:** `lib/services/auth_service.dart`

**Tanggung Jawab:**
- Autentikasi pengguna (login/register)
- Manajemen pengguna
- Pemeriksaan role-based access

**Metode Penting:**
- `login(email, password)` - Authenticate user
- `register(email, password, name)` - Create jemaat account
- `createUser(email, password, name, roles)` - Create multi-role user
- `getUserById(id)` - Get user data
- `getAllUsers()` - Get all users (admin)
- `updateUser(user)` - Update user (including roles)

**Perubahan untuk Multi-Role:**
```dart
// OLD: user.role == 'admin'
// NEW: user.hasRole('admin')

// OLD: role: 'admin'
// NEW: roles: const ['admin']
```

### SubstitutionRequestService

**File:** `lib/services/substitution_request_service.dart`

**Tanggung Jawab:**
- CRUD operations untuk substitution requests
- Persistence ke SharedPreferences
- Pencarian dan filtering

**Metode Utama:**
- `addSubstitutionRequest(request)` - Create baru
- `getAllSubstitutionRequests()` - Get semua
- `getPendingRequests()` - Get status='pending'
- `getRequestsByUser(userId)` - Get request milik user
- `approveSubstitutionRequest(requestId, replacementUserId, replacementName, adminNotes)`
- `rejectSubstitutionRequest(requestId, adminNotes)`
- `updateRequestStatus(requestId, status)` - Generic update

**Storage Key:** `'_substitutionRequestKey'`

### AttendanceConfirmationService

**File:** `lib/services/attendance_confirmation_service.dart`

**Tanggung Jawab:**
- CRUD untuk attendance confirmations
- Pencarian jadwal yang perlu dikonfirmasi
- Tracking status konfirmasi

**Metode Utama:**
- `addOrUpdateAttendanceConfirmation(confirmation)` - Create/Update
- `getAllAttendanceConfirmations()` - Get semua
- `getPendingConfirmations()` - Get unconfirmed (within 1 day)
- `getPendingConfirmationsByUserId(userId)` - Get pending untuk user
- `confirmAttendance(confirmationId, notes)` - Mark as confirmed
- `cancelConfirmation(confirmationId)` - Revert to unconfirmed
- `getUnconfirmedCount(userId)` - Count for badge

**Storage Key:** `'attendance_confirmations'`

**Logika Pending:**
```dart
// Jadwal yang perlu dikonfirmasi:
// - Jadwal date dalam 1 hari ke depan
// - Status confirmed = false

final now = DateTime.now();
final tomorrow = now.add(Duration(days: 1));
return confirmations.where((c) => 
  !c.confirmed && 
  c.scheduleDate.isAfter(now) && 
  c.scheduleDate.isBefore(tomorrow)
).toList();
```

### NotificationService

**File:** `lib/services/notification_service.dart`

**Tanggung Jawab:**
- CRUD untuk notifications
- Tracking read/unread status
- Persistence

**Metode Utama:**
- `createNotification(userId, title, message, type, relatedScheduleId)`
- `getNotificationsByUserId(userId)` - Get all notifications
- `getUnreadNotifications(userId)` - Get unread only
- `markAsRead(notificationId)` - Mark single as read
- `markAllAsRead(userId)` - Mark all as read

**Storage Key:** `'_notificationKey'`

**Notification Types:**
- `'substitution_approved'` - Substitution disetujui
- `'substitution_rejected'` - Substitution ditolak
- `'schedule_created'` - Jadwal baru dibuat
- `'schedule_updated'` - Jadwal diubah
- `'schedule_cancelled'` - Jadwal dibatalkan

---

## State Management (Providers)

### AuthProvider

**File:** `lib/providers/auth_provider.dart`

**State:**
```dart
User? _currentUser;
List<User> _allUsers = [];
bool _isLoggedIn = false;
bool _isLoading = false;
```

**Getters Multi-Role:**
```dart
List<String> get userRoles => _currentUser?.roles ?? [];
bool get isAdmin => _currentUser?.hasRole('admin') ?? false;
bool get isPelayan => _currentUser?.hasRole('pelayan') ?? false;
bool get isJemaat => _currentUser?.hasRole('jemaat') ?? false;
```

**Metode Penting:**
- `login(email, password)`
- `register(email, password, name)` - Default: `roles: ['jemaat']`
- `updateUser(user)` - Update roles
- `getAllUsers()` - For admin to manage roles
- `logout()`

### SubstitutionRequestProvider

**File:** `lib/providers/substitution_request_provider.dart`

**Dependencies:**
- `SubstitutionRequestService service`
- `NotificationService notificationService` ← **NEW**

**State:**
```dart
List<SubstitutionRequest> _allRequests = [];
List<SubstitutionRequest> _pendingRequests = [];
List<SubstitutionRequest> _userRequests = [];
int _pendingCount = 0;
```

**Metode Penting:**
- `loadAllRequests()` - Load semua
- `loadPendingRequests()` - Load pending (for admin)
- `loadUserRequests(userId)` - Load milik user
- `createSubstitutionRequest(request)` - Submit baru
- `approveRequest(requestId, replacementUserId, replacementName, adminNotes)` - **Creates notification**
- `rejectRequest(requestId, adminNotes)` - **Creates notification**

**Notifikasi Otomatis:**
```dart
// Saat approveRequest():
await _notificationService.createNotification(
  userId: approvedRequest.requestedByUserId,
  title: 'Permintaan Substitusi Disetujui',
  message: 'Permintaan substitusi Anda telah disetujui. Pengganti: $replacementName',
  type: 'substitution_approved',
  relatedScheduleId: approvedRequest.serviceScheduleId,
);

// Saat rejectRequest():
await _notificationService.createNotification(
  userId: rejectedRequest.requestedByUserId,
  title: 'Permintaan Substitusi Ditolak',
  message: 'Permintaan substitusi Anda ditolak. Alasan: $adminNotes',
  type: 'substitution_rejected',
  relatedScheduleId: rejectedRequest.serviceScheduleId,
);
```

### AttendanceConfirmationProvider

**File:** `lib/providers/attendance_confirmation_provider.dart`

**State:**
```dart
List<AttendanceConfirmation> _allConfirmations = [];
List<AttendanceConfirmation> _userConfirmations = [];
List<AttendanceConfirmation> _pendingConfirmations = [];
int _unconfirmedCount = 0;
```

**Metode Penting:**
- `loadAllConfirmations()` - Load semua (admin view)
- `loadUserConfirmations(userId)` - Load milik user + count pending
- `createOrUpdateConfirmation(confirmation)` - Create or update
- `confirmAttendance(confirmationId, notes)` - Mark confirmed with timestamp
- `cancelConfirmation(confirmationId)` - Revert to unconfirmed
- `deleteConfirmation(confirmationId)` - Remove record

### NotificationProvider

**File:** `lib/providers/notification_provider.dart`

**State:**
```dart
List<AppNotification> _notifications = [];
int _unreadCount = 0;
```

**Metode Penting:**
- `loadNotifications(userId)` - Load user's notifications
- `loadUnreadNotifications(userId)` - Load unread only
- `markAsRead(notificationId)` - Mark single
- `markAllAsRead(userId)` - Mark all
- `deleteNotification(notificationId)`

---

## Alur Kerja Substitusi

### Sequence Diagram

```
Pelayan                 Admin                    System
  |                       |                        |
  |--Buat Permintaan------|                        |
  |  (reason, optional    |                        |
  |   replacement name)   |                        |
  |                       |-- Save ke DB---------->|
  |                       |<-- ID generated--------|
  |                       |                        |
  |-- Notifikasi baru-----|<-- Create Notification|
  |   (pending count++)   |                        |
  |                       |                        |
  |                       |-- View Pending-------->|
  |                       |<-- Get pending list---|
  |                       |                        |
  |                       |--Pilih Replacement----|
  |                       |   (add admin notes)    |
  |                       |                        |
  |                       |--Approve/Reject------->|
  |                       |     (Update status)    |
  |                       |<-- Update complete----|
  |                       |                        |
  |<-- Notifikasi Result--|<-- Create Notification|
  |   (Approved/Rejected) |                        |
  |                       |                        |
  |-- Riwayat ter-update--|                        |
  |   di Substitusi tab   |                        |
```

### Data Flow

1. **Create Request**
   ```
   SubstitutionRequestScreen → SubstitutionRequestProvider.createSubstitutionRequest()
   → SubstitutionRequestService.addSubstitutionRequest()
   → SharedPreferences save
   → Provider state updated + notifyListeners()
   ```

2. **Admin Review**
   ```
   AdminSubstitutionReviewScreen
   → SubstitutionRequestProvider.loadPendingRequests()
   → Service.getPendingRequests()
   → Parse from SharedPreferences
   → Display filtered by status
   ```

3. **Approval with Notification**
   ```
   Admin clicks Approve
   → SubstitutionRequestProvider.approveRequest()
   → SubstitutionRequestService.approveSubstitutionRequest() [update status]
   → NotificationService.createNotification() [auto notify requester]
   → Provider state updated
   → UI refreshes
   → Pelayan menerima notifikasi
   ```

---

## Alur Kerja Konfirmasi Kehadiran

### Automatic Generation

```
Backend/Timer Logic (Optional future implementation)
                ↓
Generate AttendanceConfirmation records
for each service schedule 1-2 days before
                ↓
Insert into AttendanceConfirmationService
                ↓
Pelayan sees in "Kehadiran" tab
```

**Current Implementation:**
- Sistem menggunakan pending logic di service (belum fully automatic)
- Jadwal dihitung real-time untuk yang perlu dikonfirmasi

### Confirmation Flow

```
Pelayan                     System                      Admin
  |                           |                          |
  |-- View Kehadiran tab------>|                          |
  |   (Get pending)            |-- Get from DB----------->|
  |                            |<-- Pending list---------|
  |                            |                          |
  |-- Click Konfirmasi Hadir-->|                          |
  |   (notes optional)         |                          |
  |                            |-- Save confirmation---->|
  |                            |   (mark confirmed=true) |
  |                            |   (timestamp)           |
  |                            |<-- Update complete-----|
  |                            |                          |
  |-- Success message          |                          |
  |-- Tab ter-update           |                          |
  |   (item berubah dari      |                          |
  |    pending ke confirmed)   |                          |
  |                            |                          |
  |                            |-- Admin can view status--|
  |                            |   in Monitoring screen-->
```

### Data Recorded

```dart
AttendanceConfirmation(
  id: UUID.v4(),
  userId: pelayerId,
  userName: pelayerName,
  serviceScheduleId: scheduleId,
  scheduleDate: schedule.date,
  confirmed: true,
  confirmedAt: DateTime.now(),  // TIMESTAMP
  notes: userNotes,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
)
```

---

## Fitur Pemindahan Peran

### RoleSwitcher Widget

**File:** `lib/widgets/role_switcher.dart`

```dart
class RoleSwitcher extends StatefulWidget {
  const RoleSwitcher({super.key});

  @override
  State<RoleSwitcher> createState() => _RoleSwitcherState();
}

class _RoleSwitcherState extends State<RoleSwitcher> {
  late String _selectedRole;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final roles = authProvider.userRoles;
        
        // Hidden jika hanya 1 role
        if (roles.length <= 1) {
          return SizedBox.shrink();
        }
        
        // Dropdown dengan semua role
        return DropdownButton<String>(
          value: _selectedRole,
          items: roles.map((role) {
            final emoji = _getRoleEmoji(role);
            return DropdownMenuItem(
              value: role,
              child: Text('$emoji $role'),
            );
          }).toList(),
          onChanged: (newRole) {
            if (newRole != null) {
              setState(() => _selectedRole = newRole);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Beralih ke role: $newRole')),
              );
            }
          },
        );
      },
    );
  }
  
  String _getRoleEmoji(String role) {
    switch (role) {
      case 'admin':
        return '👨‍💼';
      case 'pelayan':
        return '🙏';
      case 'jemaat':
        return '👥';
      default:
        return '❓';
    }
  }
}
```

### Integration Points

**1. PelayaniHomeScreen AppBar**
```dart
appBar: AppBar(
  actions: [
    Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.userRoles.length > 1) {
          return RoleSwitcher();
        }
        return SizedBox.shrink();
      },
    ),
  ],
)
```

**2. AdminHomeScreen AppBar** - Similar pattern

**3. UserHomeScreen AppBar** - Similar pattern

### Logic Flow

```
User dengan multiple roles
         ↓
HomeScreen router mengecek:
- if hasRole('admin') → AdminHomeScreen
- else if hasRole('pelayan') → PelayaniHomeScreen
- else → UserHomeScreen
         ↓
AppBar menampilkan RoleSwitcher
         ↓
User klik dropdown dan pilih role lain
         ↓
RoleSwitcher updates _selectedRole
         ↓
Navigation ke screen yang sesuai
(Implementasi future: bisa pakai GoRouter)
         ↓
UI berubah sesuai role baru
```

---

## Notifikasi Sistem

### Architecture

```
Service Layer
  ↓
NotificationService (CRUD)
  ↓
SharedPreferences Storage
  ↓
NotificationProvider (State)
  ↓
UI (NotificationProvider tab)
```

### Notification Types & Triggers

| Type | Trigger | Title | Message |
|------|---------|-------|---------|
| substitution_approved | SubstitutionRequestProvider.approveRequest() | Permintaan Substitusi Disetujui | "Permintaan disetujui. Pengganti: [Name]" |
| substitution_rejected | SubstitutionRequestProvider.rejectRequest() | Permintaan Substitusi Ditolak | "Ditolak. Alasan: [Reason]" |
| schedule_created | ServiceScheduleProvider (future) | Jadwal Baru | "Jadwal baru telah ditambahkan" |
| schedule_updated | ServiceScheduleProvider (future) | Jadwal Diubah | "Jadwal telah diperbarui" |

### Storage Format

```dart
// SharedPreferences key: '_notificationKey'
[
  {
    "id": "uuid-v4",
    "userId": "user-uuid",
    "title": "Permintaan Substitusi Disetujui",
    "message": "Permintaan substitusi Anda telah disetujui...",
    "type": "substitution_approved",
    "relatedScheduleId": "schedule-uuid",
    "isRead": false,
    "createdAt": "2026-05-25T10:30:00.000Z",
    "readAt": null
  }
]
```

### Notification Badge/Count

```dart
// Pelayan home screen
NotificationProvider
  → getUnreadNotifications(userId)
  → Display count in tab badge
  → Update when new notification arrives
```

---

## Testing Checklist

### Unit Tests to Add

- [ ] User.hasRole() logic
- [ ] SubstitutionRequest validation
- [ ] AttendanceConfirmation pending logic
- [ ] Notification creation with correct userId

### Integration Tests

- [ ] Create substitution → Admin approve → Notification sent
- [ ] Confirm attendance → Data persists → Admin sees it
- [ ] Multi-role user → Can switch roles → Appropriate screen shows
- [ ] Notification → Mark as read → State updates

### Manual Testing

- [ ] RoleSwitcher appears only for multi-role users
- [ ] Substitution approval creates notification
- [ ] Attendance monitoring shows correct counts
- [ ] Data persists after app restart

---

## Future Improvements

1. **Backend Sync** - Replace SharedPreferences dengan API calls
2. **Real-time Updates** - WebSocket untuk notifications instant
3. **Advanced Filtering** - Date range filtering di admin screens
4. **Export Reports** - CSV/PDF export untuk attendance reports
5. **Offline Support** - Queue API calls saat offline
6. **Role-based Widgets** - Conditional rendering berdasarkan role
7. **Audit Logs** - Track semua changes dengan timestamps

---

**Terakhir diperbarui:** 25 Mei 2026
