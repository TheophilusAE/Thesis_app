# Role Switching System - Technical Reference

## Architecture Overview

### Multi-Role State Management

The system manages users with multiple roles through a 2-tier state model:

```dart
/// Tier 1: What roles does user HAVE?
List<String> userRoles  // e.g., ['jemaat', 'pelayan', 'admin']

/// Tier 2: Which role is user CURRENTLY viewing?
String currentDisplayRole  // e.g., 'pelayan'
```

This separation allows users to switch between roles they possess without losing permissions data.

---

## Component Details

### 1. AuthProvider (lib/providers/auth_provider.dart)

**Responsibilities:**
- Track both `userRoles` (permissions) and `currentDisplayRole` (display preference)
- Initialize display role on login
- Reset display role on logout
- Provide role switching capability

**Key Code:**

```dart
class AuthProvider extends ChangeNotifier {
  // ...existing fields...
  late String _currentDisplayRole;  // NEW: Track displayed role
  
  // Getter for current display role
  String get currentDisplayRole => _currentDisplayRole;
  
  // Method to switch to different role
  void switchRole(String role) {
    if (userRoles.contains(role)) {
      _currentDisplayRole = role;
      notifyListeners();  // Notify all listeners to rebuild
    }
  }
  
  // In login() method:
  Future<bool> login(String email, String password) async {
    // ... authenticate ...
    
    // Initialize currentDisplayRole with priority
    if (userRoles.contains('admin')) {
      _currentDisplayRole = 'admin';
    } else if (userRoles.contains('pelayan')) {
      _currentDisplayRole = 'pelayan';
    } else {
      _currentDisplayRole = 'jemaat';
    }
    
    notifyListeners();
    return true;
  }
  
  // In logout() method:
  void logout() {
    // ... cleanup ...
    _currentDisplayRole = 'jemaat';  // Reset to default
    notifyListeners();
  }
}
```

**Why This Works:**
- Single source of truth for current display role
- `notifyListeners()` triggers Consumer widgets to rebuild
- Priority initialization ensures sensible default
- Role switching is atomic operation

---

### 2. RoleSwitcher Widget (lib/widgets/role_switcher.dart)

**Responsibilities:**
- Display dropdown of available roles
- Handle role selection
- Update AuthProvider when role changes
- Automatically rebuild when provider changes

**Key Code:**

```dart
class RoleSwitcher extends StatelessWidget {  // ← KEY: StatelessWidget, not Stateful
  const RoleSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(  // ← KEY: Listen to provider
      builder: (context, authProvider, _) {
        final currentRole = authProvider.currentDisplayRole;
        final allRoles = authProvider.userRoles;
        
        return DropdownButton<String>(
          value: currentRole,  // ← Current role from provider
          items: allRoles.map((role) {
            return DropdownMenuItem(
              value: role,
              child: Text('$role 👤'),  // Role with emoji
            );
          }).toList(),
          onChanged: (newRole) {
            if (newRole != null) {
              authProvider.switchRole(newRole);  // ← Update provider
              // This triggers rebuilds in:
              // 1. RoleSwitcher (dropdown value changes)
              // 2. HomeScreen (routing changes)
              // 3. Any other Consumer<AuthProvider>
            }
          },
        );
      },
    );
  }
}
```

**Why StatelessWidget:**
- No local state to manage
- Provider is source of truth
- Consumer handles reactivity
- Simpler, more predictable behavior

**Why Consumer Pattern:**
- Automatically listens for provider changes
- Rebuilds only this widget, not entire tree
- Properly unsubscribes when widget disposed
- Built-in memory leak prevention

---

### 3. HomeScreen Router (lib/screens/home_screen.dart)

**Responsibilities:**
- Route to correct screen based on current role
- Rebuild when role changes
- Maintain role validation

**Key Code:**

```dart
class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(  // ← KEY: Listen to provider
      builder: (context, authProvider, _) {
        final currentDisplayRole = authProvider.currentDisplayRole;
        final userRoles = authProvider.userRoles;
        
        // Route based on DISPLAYED role, not priority
        if (currentDisplayRole == 'admin' && userRoles.contains('admin')) {
          return const AdminHomeScreen();
        }
        
        if (currentDisplayRole == 'pelayan' && 
            userRoles.contains('pelayan')) {
          return const PelayaniHomeScreen();
        }
        
        if (currentDisplayRole == 'jemaat' && 
            userRoles.contains('jemaat')) {
          return const UserHomeScreen();
        }
        
        // Fallback: something went wrong, use priority
        if (userRoles.contains('admin')) {
          return const AdminHomeScreen();
        }
        if (userRoles.contains('pelayan')) {
          return const PelayaniHomeScreen();
        }
        
        return const UserHomeScreen();
      },
    );
  }
}
```

**Why Dual Check:**
- Verify user actually HAS the role they selected
- Prevent showing wrong screen if role was revoked mid-session
- Safety fallback to priority if something invalid

**Why Consumer Pattern:**
- Rebuilds entire navigation when `currentDisplayRole` changes
- Not just visual update, actual screen swap
- Efficient: only rebuilds when role actually changes

---

### 4. Pelayan Home Screen (lib/screens/pelayan_home_screen.dart)

**Responsibilities:**
- Display 5-tab interface for Pelayan role
- Load user-specific data on screen open
- Handle attendance confirmation dialogs safely

**Key Data Loading Pattern:**

```dart
class _PelayaniHomeScreenState extends State<PelayaniHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();  // ← Load after first frame
    });
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;  // ← Check before any async work
    
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user != null) {
      final userId = authProvider.user!.id;
      
      if (mounted) {  // ← Check again before provider access
        context.read<SubstitutionRequestProvider>()
            .loadUserRequests(userId);
        context.read<AttendanceConfirmationProvider>()
            .loadUserConfirmations(userId);
        context.read<NotificationProvider>()
            .loadNotifications(userId);
      }
    }
  }
}
```

**Why addPostFrameCallback:**
- Waits for first frame to render
- Ensures context available for provider access
- Prevents jank from loading in initState directly

**Why Multiple mounted Checks:**
- User might navigate away while async loading
- Widget disposal invalidates context
- Guards against "use of unmounted context" errors

**Attendance Confirmation Dialog:**

```dart
void _showConfirmDialog(BuildContext context, AttendanceConfirmation confirmation) {
  final notesController = TextEditingController();
  
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        // ... dialog content ...
        actions: [
          ElevatedButton(
            onPressed: () async {
              if (!context.mounted) return;  // ← Guard before async
              
              await context
                  .read<AttendanceConfirmationProvider>()
                  .confirmAttendance(
                    confirmation.id,
                    notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                  );

              if (!mounted) return;  // ← Check State mounted
              if (context.mounted) {  // ← Extra guard before navigate
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Konfirmasi'),
          ),
        ],
      );
    },
  );
}
```

**Why Multiple Context Checks:**
- `!context.mounted` - Before async operation
- `!mounted` - After async operation (State.mounted)
- `context.mounted` - Before using context for navigation

---

## Data Flow Diagrams

### Login Flow
```
User enters credentials
         │
         ↓
AuthProvider.login()
         │
         ├─ Authenticate with backend
         │
         ├─ Parse user roles: ['jemaat', 'pelayan', 'admin']
         │
         ├─ Initialize _currentDisplayRole:
         │  if ('admin' in roles) → 'admin'
         │  else if ('pelayan' in roles) → 'pelayan'
         │  else → 'jemaat'
         │
         ├─ notifyListeners()
         │
         └─ return true
         
HomeScreen rebuilds:
├─ Checks currentDisplayRole == 'admin'? → YES
└─ Routes to AdminHomeScreen()

AdminHomeScreen displays with RoleSwitcher in AppBar
```

### Role Switch Flow
```
User clicks RoleSwitcher dropdown
         │
         ↓
Selects new role (e.g., 'pelayan')
         │
         ↓
DropdownButton.onChanged(newRole)
         │
         ↓
authProvider.switchRole('pelayan')
         │
         ├─ Verifies: 'pelayan' in userRoles? ✓
         │
         ├─ Updates: _currentDisplayRole = 'pelayan'
         │
         └─ Calls: notifyListeners()
         
All Consumer<AuthProvider> widgets rebuild:
│
├─ RoleSwitcher rebuilds:
│  └─ Dropdown value changes from 'admin' to 'pelayan'
│
├─ HomeScreen rebuilds:
│  ├─ Checks: currentDisplayRole == 'admin'? ✗
│  ├─ Checks: currentDisplayRole == 'pelayan'? ✓
│  └─ Routes to: PelayaniHomeScreen()
│
└─ PelayaniHomeScreen renders:
   └─ 5 tabs load Pelayan-specific data

User sees Pelayan interface
```

### Attendance Confirmation Flow
```
User opens PelayaniHomeScreen > Kehadiran tab
         │
         ↓
Sees pending attendance list (from provider)
         │
         ↓
Clicks pending attendance item
         │
         ↓
_showConfirmDialog() called
         │
         ├─ Check: !context.mounted? → Continue if true
         │
         ├─ await confirmAttendance(id, notes)
         │  (May take 100-500ms)
         │
         ├─ Check: !mounted? → Return if widget disposed
         │
         ├─ Check: context.mounted? → Only if true:
         │  └─ Navigator.pop(dialogContext)
         │
         └─ Dialog closes

AttendanceConfirmationProvider rebuilds UI:
└─ Attendance shows: "✅ Sudah Konfirmasi"
```

---

## State Transitions

### User State Lifecycle

```
┌─ INITIAL: Not Authenticated
│  └─ No userRoles
│  └─ No currentDisplayRole
│
├─ LOGIN
│  ├─ Authenticate
│  ├─ Load user roles
│  ├─ Set currentDisplayRole = highest priority role
│  └─ Rebuild screens
│
├─ AUTHENTICATED: Viewing as selected role
│  ├─ userRoles = stable (what user CAN do)
│  ├─ currentDisplayRole = mutable (what user IS viewing)
│  └─ RoleSwitcher allows switching between roles
│
├─ ROLE SWITCH
│  ├─ User selects different role from dropdown
│  ├─ Verify role in userRoles
│  ├─ Update currentDisplayRole
│  ├─ Trigger rebuilds
│  └─ Navigate to appropriate screen
│
└─ LOGOUT
   ├─ Clear userRoles
   ├─ Reset currentDisplayRole = 'jemaat'
   ├─ Clear cached data
   └─ Return to login screen
```

---

## Error Handling Patterns

### Pattern 1: Mounted Check Before Async

```dart
// ❌ WRONG
onPressed: () async {
  await someAsyncOperation();
  ScaffoldMessenger.of(context).showSnackBar(...);  // Crash if unmounted
}

// ✅ CORRECT
onPressed: () async {
  if (!context.mounted) return;  // Guard before async
  
  await someAsyncOperation();
  
  if (!mounted) return;  // Guard after async
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(...);
  }
}
```

### Pattern 2: Provider Access in initState

```dart
// ❌ WRONG
initState() {
  super.initState();
  // Can't use context.read directly here
  final provider = context.read<SomeProvider>();
}

// ✅ CORRECT
initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Now safe to use context.read
    final provider = context.read<SomeProvider>();
    provider.loadData();
  });
}
```

### Pattern 3: Navigation with Multiple Contexts

```dart
// ❌ WRONG - Might crash if dialog context disposed
showDialog(
  context: context,
  builder: (dialogContext) {
    return AlertDialog(
      actions: [
        ElevatedButton(
          onPressed: () async {
            await asyncOperation();
            Navigator.of(context).pop();  // Might be disposed
          },
        ),
      ],
    );
  },
);

// ✅ CORRECT - Safe navigation
showDialog(
  context: context,
  builder: (dialogContext) {
    return AlertDialog(
      actions: [
        ElevatedButton(
          onPressed: () async {
            if (!context.mounted) return;
            await asyncOperation();
            if (!mounted) return;
            if (context.mounted) {
              Navigator.of(dialogContext).pop();
            }
          },
        ),
      ],
    );
  },
);
```

---

## Performance Considerations

### Optimization 1: Consumer Granularity
```dart
// ❌ LESS EFFICIENT - Whole widget rebuilds
Consumer<AuthProvider>(
  builder: (context, authProvider, _) {
    return Column(
      children: [
        // Expensive widget
        ExpensiveListView(),
        // Just this small part needs to listen
        RoleSwitcher(),
      ],
    );
  },
);

// ✅ MORE EFFICIENT - Only listen where needed
Column(
  children: [
    ExpensiveListView(),
    Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return RoleSwitcher();
      },
    ),
  ],
);
```

### Optimization 2: Provider Selector
```dart
// ❌ LESS EFFICIENT - Rebuilds on ANY AuthProvider change
Consumer<AuthProvider>(
  builder: (context, authProvider, _) {
    final role = authProvider.currentDisplayRole;
    return Text(role);
  },
);

// ✅ MORE EFFICIENT - Rebuilds only if specific value changes
Selector<AuthProvider, String>(
  selector: (context, auth) => auth.currentDisplayRole,
  builder: (context, role, _) {
    return Text(role);
  },
);
```

---

## Testing Considerations

### Unit Test: Role Switching Logic

```dart
test('switchRole updates currentDisplayRole and notifies listeners', () {
  final provider = AuthProvider();
  provider.userRoles = ['jemaat', 'pelayan'];
  provider._currentDisplayRole = 'jemaat';
  
  var notified = false;
  provider.addListener(() {
    notified = true;
  });
  
  provider.switchRole('pelayan');
  
  expect(provider.currentDisplayRole, 'pelayan');
  expect(notified, true);
});

test('switchRole prevents switching to role user does not have', () {
  final provider = AuthProvider();
  provider.userRoles = ['jemaat'];
  provider._currentDisplayRole = 'jemaat';
  
  var notified = false;
  provider.addListener(() {
    notified = true;
  });
  
  provider.switchRole('admin');  // User doesn't have admin role
  
  expect(provider.currentDisplayRole, 'jemaat');  // Unchanged
  expect(notified, false);  // No notification
});
```

### Widget Test: RoleSwitcher

```dart
testWidgets('RoleSwitcher displays current role', (tester) async {
  final authProvider = _MockAuthProvider();
  authProvider.userRoles = ['jemaat', 'pelayan'];
  authProvider.currentDisplayRole = 'pelayan';
  
  await tester.pumpWidget(
    MaterialApp(
      home: ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: const Scaffold(body: RoleSwitcher()),
      ),
    ),
  );
  
  expect(find.text('pelayan 👤'), findsOneWidget);
});

testWidgets('RoleSwitcher calls switchRole on selection', (tester) async {
  // ... setup ...
  
  await tester.tap(find.byType(DropdownButton<String>));
  await tester.pumpAndSettle();
  
  await tester.tap(find.text('admin 👤').last);
  await tester.pumpAndSettle();
  
  verify(authProvider.switchRole('admin')).called(1);
});
```

---

## Migration Guide (From Old System)

### Old System (Before Fix)
```dart
// RoleSwitcher was StatefulWidget with local state
// HomeScreen used priority-based routing
// No centralized display role tracking
```

### New System (After Fix)
```dart
// 1. Update AuthProvider:
//    - Add _currentDisplayRole field
//    - Add switchRole(String role) method
//    - Initialize in login()
//    - Reset in logout()

// 2. Update RoleSwitcher:
//    - Change StatefulWidget → StatelessWidget
//    - Use Consumer<AuthProvider>
//    - Call authProvider.switchRole() in onChanged

// 3. Update HomeScreen:
//    - Check currentDisplayRole instead of just userRoles
//    - Add fallback to priority routing

// 4. Update screens using async context:
//    - Add mounted checks before async operations
//    - Add mounted checks after async operations
//    - Wrap context usage in if (context.mounted) blocks
```

---

## Debugging Tips

### Check Current Role State
```dart
// In DevTools or console
final authProvider = context.read<AuthProvider>();
print('Roles: ${authProvider.userRoles}');
print('Current: ${authProvider.currentDisplayRole}');
```

### Monitor Role Changes
```dart
// Add to AuthProvider.switchRole()
print('Switching from $_currentDisplayRole to $role');

// Or use DevTools Performance > Frame rendering
```

### Verify Provider Rebuilds
```dart
// Add to RoleSwitcher build
@override
Widget build(BuildContext context) {
  print('RoleSwitcher rebuild'); // Should see this on role change
  return Consumer<AuthProvider>(...);
}
```

### Check Mounted Issues
```dart
// If async errors appear:
// 1. Verify mounted checks before async
// 2. Verify mounted checks after async
// 3. Use State.mounted not context.mounted after async gap
// 4. Wrap final context usage in if (context.mounted)
```

---

## Summary

This role switching system provides:
- ✅ Clean separation between user permissions and display preference
- ✅ Safe state management using Provider pattern
- ✅ Automatic UI updates via Consumer pattern
- ✅ Proper async/await context handling
- ✅ Fallback routing for edge cases
- ✅ Multi-role user support without complexity

Key principle: **Single source of truth** - the provider is the only place where role state is managed.
