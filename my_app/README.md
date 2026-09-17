# GPDI Church App

A mobile church management application built with Flutter and Supabase, designed for GPDI (Gereja Pantekosta di Indonesia) congregations. Supports three roles — Jemaat, Pelayan, and Admin — each with a dedicated interface, switchable within a single account.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart SDK ^3.10.4) |
| Backend | Supabase (PostgreSQL + Auth + RLS + Realtime) |
| State management | Provider |
| Offline Bible DB | sqflite / sqflite_common_ffi (desktop) + xml parsing |
| Small local caches | SharedPreferences |
| QR | qr_flutter (generate) + mobile_scanner (scan) |
| Notifications | flutter_local_notifications + timezone (local OS reminders only, no Firebase/FCM) |
| Links | url_launcher (sermon media, WhatsApp) |
| Fonts / Design | Poppins (Google Fonts), Material 3, red/gold "Merah Pantekosta" theme |
| Testing | mocktail (mocks `SupabaseService` directly) |

---

## Roles & Features

### Jemaat (Congregation Member)
- **Home dashboard** — banner carousel, verse of the day, worship schedule, announcements
- **Alkitab** — full offline Indonesian Bible with chapter navigation and search
- **Renungan Harian** — daily devotional content
- **Quest Baca** — Bible reading challenge with progress tracking
- **Playlist Pujian** — admin-published "today's playlist" (song titles, not audio streaming)
- **Perpustakaan Khotbah** — sermon/media library; thumbnail grid, opens YouTube/audio/livestream links externally
- **Komsel** — small group directory; browse and contact a group leader via WhatsApp (directory only, no join workflow)
- **Kartu Anggota Digital** — digital membership card with a structured QR payload for attendance check-in
- **Daftar Event** — register for church events (RSVP-style, no payment/ticketing), including family members in one registration
- **Permintaan Doa** — submit prayer requests and track their status (private to the submitter + admins)
- **Persembahan** — static info only (bank transfer details, QRIS label) — no payment gateway, intentionally out of scope
- **Feedback** — submit feedback on events, facilities, and hospitality
- **Notifikasi** — in-app notification inbox (realtime)
- **Profil** — view and edit personal profile, switch roles, logout

### Pelayan (Church Minister)
- **Beranda** — dashboard with stats, quick actions, and recent notifications
- **Jadwal** — view service schedules and training schedules with toggle
- **Konfirmasi Kehadiran** — manual self-check-in for assigned services
- **QR Check-in** — scan a member's card to check them into today's schedule (writes to the same attendance table, tagged by scanning pelayan)
- **Permintaan Substitusi** — request and track service substitutions
- **Pengingat Otomatis** — local device reminders (1h/3h/24h before an upcoming service/training schedule)
- **Profil** — profile management, switch roles

### Admin
- **Dashboard** — user stats, feedback ratings, and quick actions
- **Kelola Data** — CRUD across all domains: users/roles, pelayan, service & training schedules, substitutions, attendance monitoring, events, feedback, prayer requests, komsel groups, sermons/media
- **Monitoring Kehadiran** — unified view of both manual and QR check-ins
- **Profil** — admin profile and logout

> Users can hold multiple roles simultaneously (`jemaat` / `pelayan` / `admin`) and switch between them using the role switcher in the app.

---

## Database Setup

> ⚠️ Both SQL files are excluded from this repository (see `.gitignore`).
> Contact the project owner for the SQL files.

- **`database_setup.sql`** — full from-scratch reset script (drops + recreates everything, seeds the default admin account). Use for a brand-new Supabase project.
- **`migration_new_features.sql`** — additive-only, safe to run against an existing live project without losing data. Adds QR attendance columns/policy and the prayer request / komsel / sermon tables.

1. Open [Supabase Dashboard](https://supabase.com) → your project → **SQL Editor**
2. Paste the contents of the appropriate file
3. Click **Run All**
4. Default admin (fresh setup only): `admin@gereja.com` / `Admin@123` *(change after first login)*

### Tables
`users` · `pelayans` · `schedules` · `training_schedules` · `substitution_requests` · `attendance` · `notifications` · `feedback` · `bible_verses` · `church_events` · `event_registrations` · `prayer_requests` · `komsels` · `sermons`

---

## Project Structure

```
lib/
├── main.dart                  # App entry point, Provider setup, auth gate
├── models/                    # Data models
├── providers/                 # State management (ChangeNotifier, per feature)
├── screens/                   # UI screens
├── services/                  # Supabase gateway + Bible/local notification services
├── utils/                     # Theme, QR payload encoding, constants
└── widgets/                   # Reusable components
```

---

## Running the App

```bash
flutter pub get
flutter run
```

Requires Flutter 3.x and a configured Supabase project. The Supabase URL and anon key are configured in `lib/main.dart`.

```bash
flutter analyze   # should report "No issues found"
flutter test
```

---

## Notes

- Developed as a thesis project (skripsi) for a church management system
- Role-based access control enforced both in-app and at the database level via Supabase RLS policies
- All sensitive credentials and SQL setup files are excluded from version control
- Push notifications when the app is fully closed require Firebase/FCM, which is deliberately out of scope — reminders are local, on-device only
