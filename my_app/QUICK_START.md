# Quick Start Guide - Gereja App

## 🚀 Running the App

```bash
# Navigate to project directory
cd d:\Thesis\App\my_app

# Get dependencies
flutter pub get

# Check available devices
flutter devices

# Run on connected device
flutter run
```

## 📱 App Navigation

### Bottom Navigation Bar
- **Beranda** (Home): Main dashboard with quick access to all features
- **Alkitab** (Bible): Offline Bible reader
- **Quest**: Yearly Bible reading challenge
- **Profil** (Profile): User profile and settings

## 🎯 Main Features Overview

### 1. Registration & Login
- **Registration**: Create account with name, email, phone, password
- **Login**: Use registered email and password
- **Auto-generated**: Member card number created on registration

### 2. Home Screen Features
Quick access cards for:
- 💳 Kartu Jemaat (Member Card)
- 📖 Alkitab (Bible)
- 🎯 Quest Baca (Reading Quest)
- 🙏 Renungan (Devotional)
- 🎵 Playlist Hari Ini (Today's Playlist)
- 📷 Scan Event (QR Scanner)

### 3. Bible Reader
- **Select Book**: Dropdown to choose from Bible books
- **Select Chapter**: Dropdown to navigate chapters
- **Search**: Use search icon to find verses by keyword
- **Offline**: All content stored locally

### 4. Member Card
- Shows digital member card with QR code
- Display member information
- Can be scanned at church events

### 5. QR Scanner
- Tap camera icon or scanner feature
- Point camera at event QR code
- Automatic attendance recording
- Flash toggle available

### 6. Reading Quest
- View 365-day reading plan
- Track progress percentage
- See current streak
- Mark days as completed

### 7. Profile Management
- Tap edit icon to modify profile
- Upload profile photo
- Update personal information
- Save changes

## 🔧 Development Commands

```bash
# Run in debug mode
flutter run

# Run in release mode
flutter run --release

# Build APK
flutter build apk

# Build for iOS
flutter build ios

# Clean build
flutter clean
flutter pub get

# Update dependencies
flutter pub upgrade

# Run tests
flutter test
```

## 📊 Project Statistics

- **Total Screens**: 10+
- **Models**: 6
- **Services**: 5
- **Providers**: 3
- **Platforms**: Android & iOS

## 🎨 UI/UX Highlights

- **Material Design 3**: Modern, clean interface
- **Consistent Theme**: Blue color scheme
- **Responsive**: Adapts to different screen sizes
- **Icons**: Material Icons throughout
- **Cards**: Elevated cards for better visual hierarchy

## 💾 Data Storage

### Local Storage (SharedPreferences)
- User authentication state
- User profile data
- Quest progress
- Completed reading days

### SQLite Database
- Bible verses
- Books and chapters
- Searchable content

## 🔐 Permissions Required

### Android
- Camera (for QR scanning)
- Storage (for profile images)
- Internet (for future API calls)

### iOS
- Camera Usage
- Photo Library Access

## 🐛 Common Issues & Solutions

### Issue: Dependencies not installing
```bash
flutter clean
flutter pub get
```

### Issue: App not running
```bash
# Check Flutter doctor
flutter doctor

# Check connected devices
flutter devices
```

### Issue: Camera not working
- Grant camera permissions in device settings
- Check AndroidManifest.xml has camera permissions

### Issue: Build errors
```bash
# Clean and rebuild
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get
flutter run
```

## 📝 Next Steps for Production

1. **Backend Integration**
   - Connect to REST API
   - User authentication API
   - Content management API

2. **Additional Bible Content**
   - Load complete Bible data
   - Multiple translations
   - Audio Bible

3. **Enhanced Features**
   - Push notifications
   - Social features
   - Event calendar
   - Online donations

4. **Testing**
   - Unit tests
   - Widget tests
   - Integration tests

5. **Deployment**
   - Play Store release
   - App Store release
   - Version management

## 📧 Support

For issues or questions during development, check:
- Flutter documentation: https://flutter.dev
- Provider package: https://pub.dev/packages/provider
- SQLite plugin: https://pub.dev/packages/sqflite

---

Happy coding! 🎉
