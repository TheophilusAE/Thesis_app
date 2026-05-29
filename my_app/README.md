# GPDI Church App

A mobile church management application built with Flutter and Supabase, designed for GPDI (Gereja Pantekosta di Indonesia) congregations. Supports three roles — Jemaat, Pelayan, and Admin — each with a dedicated interface.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| Backend | Supabase (PostgreSQL + Auth + RLS) |
| State management | Provider |
| Local storage | SharedPreferences, sqflite |
| Fonts | Poppins (Google Fonts) |

---

## Roles & Features

### Jemaat (Congregation Member)
- **Home dashboard** — banner carousel, verse of the day, worship schedule, announcements
- **Alkitab** — full Indonesian Bible with chapter navigation and search
- **Renungan Harian** — daily devotional content
- **Quest Baca** — Bible reading challenge with progress tracking
- **Playlist Pujian** — curated worship music playlist
- **Kartu Anggota Digital** — digital membership card with QR code
- **Daftar Event** — register for church events (Natal, Paskah, Ibadah Padang, etc.) including family members in one registration
- **Permintaan Doa** — submit prayer requests to the church
- **Persembahan** — view offering methods (QRIS, bank transfer, in-person)
- **Feedback** — submit feedback on events, facilities, and hospitality
- **Profil** — view and edit personal profile, logout

### Pelayan (Church Minister)
- **Beranda** — dashboard with stats, quick actions, and recent notifications
- **Jadwal** — view service schedules and training schedules with toggle
- **Konfirmasi Kehadiran** — confirm attendance for assigned services
- **Permintaan Substitusi** — request and track service substitutions
- **Profil** — profile management

### Admin
- **Dashboard** — user stats, feedback ratings, and quick actions
- **Kelola Data** — full CRUD across 11 management tabs: User, Role, Renungan, Quest Baca, Feedback, Pelayan, Jadwal Ibadah, Jadwal Latihan, Substitusi, Kehadiran, Event
- **Event Management** — create/edit/delete events, set capacity, view all registrations with family member breakdown
- **Profil** — admin profile and logout

> Users can hold multiple roles simultaneously and switch between them using the role switcher in the app bar.

---

## Database Setup

> ⚠️ The setup file is excluded from this repository (see `.gitignore`).
> Contact the project owner for the `database_setup.sql` file.

1. Open [Supabase Dashboard](https://supabase.com) → your project → **SQL Editor**
2. Paste the full contents of `database_setup.sql`
3. Click **Run All**
4. Default admin: `admin@gereja.com` / `Admin@123` *(change after first login)*

### Tables
`users` · `pelayans` · `schedules` · `training_schedules` · `substitution_requests` · `attendance` · `notifications` · `feedback` · `bible_verses` · `church_events` · `event_registrations`

---

## Project Structure

```
lib/
├── main.dart                  # App entry point, Provider setup
├── models/                    # Data models
├── providers/                 # State management (ChangeNotifier)
├── screens/                   # UI screens
├── services/                  # Supabase & local data services
├── utils/                     # Theme, constants
└── widgets/                   # Reusable components
```

---

## Running the App

```bash
flutter pub get
flutter run
```

Requires Flutter 3.x and a configured Supabase project. The Supabase URL and anon key are configured in `lib/main.dart`.

---

## Notes

- Developed as a thesis project (skripsi) for a church management system
- Role-based access control enforced both in-app and at the database level via Supabase RLS policies
- All sensitive credentials and SQL setup files are excluded from version control
