# Gereja App - Church Community Mobile Application

A comprehensive Flutter mobile application for church community management with offline Bible, devotionals, member cards, and more.

## Features

### 1. ✅ Registrasi (Registration)
- User registration with complete profile information
- Email and phone validation
- Automatic member card number generation

### 2. 👤 Info Profil Lengkap (Complete Profile Management)
- View and edit profile information
- Upload profile picture
- Personal information (name, email, phone, address, birth date)
- Church member information (baptism date, member since)

### 3. 📖 Alkitab Offline (Offline Bible)
- Browse Bible by book and chapter
- Search verses by keyword
- Indonesian Bible (Alkitab Terjemahan Baru)
- Offline access with SQLite database

### 4. 💳 Kartu Jemaat Digital (Digital Member Card)
- Digital member card with QR code
- Display member information
- QR code for event check-in

### 5. 📷 Scan Event/Ibadah (Event/Service Scanner)
- QR code scanner for event attendance
- Flashlight support
- Automatic attendance recording

### 6. 🎯 Quest Baca Alkitab Setahun (Yearly Bible Reading Quest)
- 365-day Bible reading plan
- Track reading progress
- Streak counter for consecutive days
- Progress visualization

### 7. 🙏 Renungan (Daily Devotional)
- Daily devotional content
- Bible verses with reflections
- Save favorite devotionals
- History of past devotionals

### 8. 🎵 Playlist Hari Ini (Today's Playlist)
- Daily worship song playlist
- View song lyrics
- Browse previous playlists

## Installation

### Prerequisites
- Flutter SDK (>= 3.10.4)
- Android Studio / Xcode for mobile development
- VS Code or Android Studio IDE

### Setup Steps

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Run the app**
   ```bash
   # For Android
   flutter run

   # For iOS (on macOS)
   flutter run -d ios
   ```

3. **Use your own app logo**
   - Add your logo file at `assets/images/app_logo.png` (recommended square PNG, at least 1024x1024).
   - Generate launcher icons:
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```
   - Rebuild and run the app so the new icon is applied.

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user.dart
│   ├── bible_verse.dart
│   ├── devotional.dart
│   ├── reading_quest.dart
│   ├── playlist.dart
│   └── event.dart
├── providers/                # State management (Provider)
│   ├── auth_provider.dart
│   ├── bible_provider.dart
│   └── quest_provider.dart
├── screens/                  # UI screens
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart
│   ├── profile_screen.dart
│   ├── bible_screen.dart
│   ├── member_card_screen.dart
│   ├── qr_scanner_screen.dart
│   ├── quest_screen.dart
│   ├── devotional_screen.dart
│   └── playlist_screen.dart
├── services/                 # Business logic & data services
│   ├── auth_service.dart
│   ├── bible_service.dart
│   ├── quest_service.dart
│   ├── devotional_service.dart
│   └── playlist_service.dart
└── widgets/                  # Reusable widgets
```

## Key Dependencies

- **provider**: State management
- **sqflite**: Local database for offline Bible
- **shared_preferences**: Local storage for user data
- **qr_code_scanner**: QR code scanning
- **qr_flutter**: QR code generation
- **image_picker**: Profile image selection
- **google_fonts**: Custom fonts
- **intl**: Date formatting

## How to Use

1. **First Launch**: The app will show a splash screen and navigate to login
2. **Register**: Create a new account with your details
3. **Explore Features**: Use bottom navigation to access different features
4. **Scan QR**: Use the scanner icon in the app bar to scan event QR codes
5. **Read Bible**: Browse offline Bible content by book and chapter
6. **Track Reading**: Complete daily Bible reading quests
7. **View Member Card**: Access your digital member card with QR code

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Notes

- This app is designed to work offline for Bible and basic features
- Some features (devotionals, playlists) currently use local mock data
- For production, integrate with a backend API for real-time content

---

**Built with Flutter** 💙 - Adaptive for iOS and Android
