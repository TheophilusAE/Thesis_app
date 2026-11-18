# GPdI App — GPdI Persadamas Banjarmasin

A mobile church application built with Flutter and Supabase for GPdI (Gereja Pantekosta di Indonesia) Persadamas Banjarmasin. It digitalizes member administration, service scheduling, attendance, church information and spiritual content, and gives church leaders data-based activity recommendations. Developed as an undergraduate thesis project (skripsi): *"Rancang Bangun Aplikasi Digitalisasi Gereja Berbasis Mobile untuk Meningkatkan Efektivitas Pelayanan di GPDI Persadamas Banjarmasin."*

Three roles — **Jemaat**, **Pelayan**, **Admin** — share one account system. A user can hold several roles and switch between them in the app.

---

## Tech Stack

Versions are the constraints declared in `pubspec.yaml`.

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart SDK `^3.10.4`; developed with Flutter 3.41 / Dart 3.11) |
| Backend | Supabase (`supabase_flutter ^1.10.0`) — PostgreSQL, Auth, Row Level Security, Realtime |
| State management | Provider (`^6.1.1`) |
| Offline Bible | `sqflite` / `sqflite_common_ffi` (desktop) + `xml` parsing of a bundled Indonesian Bible |
| Local storage | `shared_preferences` (caches, per-account reading progress and bookmarks) |
| QR | `qr_flutter` (generate) + `mobile_scanner` (scan) |
| Reminders | `flutter_local_notifications` + `timezone` (on-device only, no Firebase/FCM) |
| Links / sharing | `url_launcher` (sermon media, playlist links, WhatsApp) |
| Design | Poppins (`google_fonts`), Material 3, light theme with GPdI burgundy `#A62639` and gold `#C89B3C` |
| Testing | `flutter_test` + `mocktail` (mocks `SupabaseService`) |

---

## Features

### Tamu (Guest, no account)
- Opens straight to a public home: worship schedule (no pelayan names), church events, daily devotional, sermon library and the offline Bible.
- Worship slots show a "Tonton di YouTube" button when a livestream link is set.
- Personal features (member card/QR, Group, prayer requests, Quest Baca) ask the visitor to sign in or register.

### Jemaat (Congregation Member)
- **Registration and login** — email/password via Supabase Auth. New accounts wait for admin approval before they can sign in.
- **Profile and digital member card** — the QR code on the card is used for attendance.
- **Alkitab** — offline Indonesian Bible with chapter navigation and search.
- **Quest Baca** — annual Bible reading plan with progress and a calendar-day streak. Progress is stored **per account on the device** (see Known Limitations).
- **Renungan Harian** — admin-managed daily devotional. Can be saved on the device or shared (copy text or WhatsApp).
- **Playlist Pujian** — admin-managed worship playlist. Songs with a link open in an external app; there is no built-in audio player.
- **Event Gereja** — book a place (including family members) with a server-side quota guarantee, edit or cancel the booking, watch the livestream link, and give event feedback. A booking becomes *Hadir* only after a QR check-in at the event.
- **QR attendance** — show your own signed member QR to an usher, or scan the time-limited check-in code shown at a service or event. Each person is recorded once per service/event.
- **Jadwal Ibadah** — upcoming worship services with time, place and livestream link.
- **Prayer requests**, **Group directory** (Umum, Pemuda, Anak/Sekolah Minggu; contact leaders via WhatsApp; choose your Group in the profile), **sermon/media library** (opens links externally).
- **Feedback** — rate events, facilities and hospitality. The "anonymous" option hides your name from church leaders; the account is still recorded (see Known Limitations).
- **Notifications** — in-app inbox (realtime) for schedule changes, substitution decisions and new events.

### Pelayan (Service Minister)
- Service and training schedules, with attendance confirmation for assigned services.
- **QR check-in** — pick today's service or event, then scan members' cards; or show the check-in code for members to scan.
- **Substitution requests** — request a replacement for an assigned duty and follow its status.
- **Automatic reminders** — local device notifications 24h, 3h and 1h before an upcoming duty.

### Super Admin
- Full create, read, update and delete on every module.
- **Kelola Admin & Izin** — promote members to Admin, choose per module whether each Admin may *view*, *add* or *approve*, and limit an Admin to administrative categories (Umum, Pemuda, Sekolah Minggu, or new ones).
- The only role that may change roles, edit or delete existing records, or deactivate accounts.

### Admin
- **Create and read only**, limited to the modules and categories granted by the Super Admin. Approving members, reviewing substitutions and updating prayer-request status need an explicit *approve* permission.
- **Dashboard** with live counts; menus show only the modules the admin may open.
- Manage users and roles (including approving new members), pelayan (linked to their app account), events (with livestream link and category), devotionals, playlists, Groups and sermons.
- **Jadwal Ibadah** — recurring worship services (weekly, two-weekly, monthly or one-off) with a stable ID; dates are kept 90 days ahead. Pelayan duties and the rehearsal are assigned to a specific service date in one form, so date and place are never retyped.
- **Kas Keuangan & Rekening** — record income/expense per account, filter by account, type, category and date, and see balances. Admins only see and add to accounts they were given access to; only the Super Admin can edit or delete.
- **Substitution review** — choose the replacement pelayan. Approval moves the duty to that pelayan and notifies the people involved.
- **Attendance monitoring** — all check-ins with role (Jemaat/Pelayan), check-in method (manual / self QR / QR by an usher) and filters.
- **Feedback** and **prayer request** review.
- **Rekomendasi Kegiatan** (decision support) — explainable, rule-based recommendations computed from attendance history, building capacity, event registrations and feedback. Each recommendation shows the numbers it is based on.

---

## Project Structure

The Flutter project lives in **`my_app/`**; all commands below run from there.

```
my_app/
├── lib/
│   ├── main.dart        # App entry, Supabase init, Provider registration, auth gate
│   ├── models/          # Typed data models (one per table)
│   ├── providers/       # ChangeNotifier state, one per feature
│   ├── screens/         # UI screens (home_screen.dart hosts the per-role tabs)
│   ├── services/        # SupabaseService (main DB gateway), Bible, events, reminders,
│   │                    # recommendation engine, local bookmarks
│   ├── utils/           # Theme, QR payloads, recurrence, capacity, church config
│   └── widgets/         # Shared UI components
├── assets/              # Bible XML, images
├── test/                # Unit and widget tests
└── android/ ios/        # Platform projects
```

---

## Prerequisites

- Flutter SDK compatible with Dart `^3.10.4`.
- Android SDK / Android Studio for Android builds. Android is the primary target.
- A Supabase project with the app's schema (see Database Notes).

## Setup

```bash
cd my_app
flutter pub get
flutter run            # with an Android device or emulator connected
```

### Configuration

The Supabase project URL and **public anon key** are set in `lib/main.dart` (`Supabase.initialize`). The anon key is designed to be public; data is protected by Row Level Security. **Never put a Supabase service-role key or any other secret in the app.**

The seating capacity used by *Rekomendasi Kegiatan* is set in `lib/utils/church_config.dart` (`ChurchConfig.buildingCapacity`). It is `null` until the church provides the verified number. While it is null, capacity-based recommendations are skipped and the screen says so.

---

## Database Notes

- The app is written against the **existing** Supabase schema. **Future work must not change the database schema, RLS policies, functions, triggers or grants without explicit approval from the project owner** — adapt the app code to the schema instead.
- SQL scripts are kept out of version control (`*.sql` in `.gitignore`). Ask the project owner for them; do not run schema-changing scripts on the live project without approval.
- RBAC v2 and guest access (`migration_rbac_v2.sql`, `migration_guest_access.sql`) are applied to production.
- **Pending owner action (scheduling, booking/QR, Group, Kas):** run, in this order and **before** installing this app version: `migration_scheduling_v2.sql`, `migration_booking_qr_v2.sql`, `migration_groups.sql`, `migration_kas_v1.sql`. The Kas migration only adds security rules, a balance view and functions; the `kas_*` tables are shared with another system and their structure is not changed. After `migration_booking_qr_v2.sql`, older app builds can no longer check in or book directly, so update the app together with the migration.
- Credentials of any seeded admin account are not documented here. If a default admin password was ever used, change it.

---

## Testing and Static Analysis

```bash
cd my_app
flutter analyze        # expected: "No issues found!"
flutter test           # unit + widget tests
```

As of 2026-11-17: `flutter analyze` reports no issues and `flutter test` passes 230/230. All tests use mocks and local storage; **no test talks to a live Supabase project**. Camera, notification delivery, offline behaviour and end-to-end flows require manual testing on a device.

## Android Build

```bash
cd my_app
flutter build apk --release      # APK in build/app/outputs/flutter-apk/
```

Before publishing:
- The release build is currently **signed with the debug key**. Add your own keystore and `signingConfigs` (keep `key.properties` and keystores out of git — they are already ignored).
- The `applicationId` is still the placeholder `com.mycompany.my_app`. Choose the final ID before the first store upload; it cannot be changed afterwards.
- iOS sources are prepared but **have never been built or tested** (no Mac available).
- Google Play requires apps with account creation to offer account deletion; the app has no self-service deletion yet. A privacy policy and the Play data-safety form are also needed.

A debug-signed `flutter build apk --release` was verified to compile on 2026-10-23. Device testing is still required.

---

## Known Limitations

- **Reading progress (Quest Baca)** is stored on the device per account. It does not sync across devices and is lost if the app is reinstalled. The daily target and admin-edited plan apply to the device where they were set.
- **Saved devotionals** are stored on the device.
- **Recurring worship services** keep dates 90 days ahead; the window is extended when the schedule screen is opened. Changing a series affects future dates only. Older per-pelayan recurring schedules created before this version are not converted.
- **Anonymous feedback** hides the name from church leaders, but the submitting account is still stored, as the database security rules require.
- **Notifications** are in-app (and local reminders). Nothing is pushed while the app is fully closed. Only admin actions create notifications for other users.
- **Attendance roles** in monitoring reflect each person's current role, not the role at check-in time.
- **Persembahan (giving) is not implemented.**
- **Recommendations** are rule-based guidance for church leaders, not automatic decisions. They need enough recorded data (at least 3 data points per rule) and a configured building capacity.

## Development Guidelines

- Follow the existing layering: screen → provider (`ChangeNotifier`) → `SupabaseService` → model. New providers accept an optional `{SupabaseService? service}` for test injection.
- Keep user-facing text in Indonesian and colors in `AppTheme`.
- Never show success before an operation actually succeeds.
- Run `flutter analyze` and `flutter test` before committing.
