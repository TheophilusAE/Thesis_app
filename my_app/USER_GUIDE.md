# 🚀 Getting Started - Your Church App

## Quick Start (3 Steps)

### Step 1: Install Dependencies
```bash
cd d:\Thesis\App\my_app
flutter pub get
```

### Step 2: Connect Device
- Connect Android phone via USB, or
- Start Android emulator, or
- Use iOS simulator (Mac only)

Check connected devices:
```bash
flutter devices
```

### Step 3: Run the App
```bash
flutter run
```

That's it! The app will launch on your device. 🎉

---

## First Time Using the App

### 1. Registration Flow
When you first open the app, you'll see:
1. **Splash Screen** → Shows church icon
2. **Login Screen** → Tap "Daftar" (Register)
3. **Registration Form**:
   - Enter your full name
   - Enter email address
   - Enter phone number
   - Create a password (min 6 characters)
   - Confirm password
   - Tap "Daftar" button
4. **Automatic Login** → Goes to home screen

### 2. Explore Features
After registration, you'll see the **Home Screen** with:

#### Quick Access Cards:
- 💳 **Kartu Jemaat** → View your digital member card
- 📖 **Alkitab** → Read offline Bible
- 🎯 **Quest Baca** → Bible reading challenge
- 🙏 **Renungan** → Daily devotional
- 🎵 **Playlist** → Today's worship songs
- 📷 **Scan Event** → Scan QR for attendance

#### Bottom Navigation:
- 🏠 **Beranda** → Home dashboard
- 📖 **Alkitab** → Bible reader
- 🎯 **Quest** → Reading quest
- 👤 **Profil** → Your profile

---

## Feature Walkthrough

### 📱 Managing Your Profile

**To Edit Profile:**
1. Tap "Profil" in bottom navigation
2. Tap edit icon (✏️) in app bar
3. Make changes:
   - Tap circle photo to change picture
   - Update name, phone, address
   - Select birth date
   - Enter baptism date
4. Tap "Simpan Perubahan" (Save Changes)

**To Logout:**
1. Go to Profile tab
2. Scroll down
3. Tap red "Logout" button

---

### 📖 Reading the Bible

**Browse Bible:**
1. Tap "Alkitab" in bottom nav
2. Select book from dropdown (e.g., "Kejadian")
3. Select chapter from dropdown (e.g., "1")
4. Read verses displayed below

**Search Bible:**
1. Tap search icon (🔍) in Bible screen
2. Type search term (e.g., "kasih")
3. View matching verses
4. Tap back to return

**Available Books** (sample data):
- Kejadian (Genesis)
- Keluaran (Exodus)
- Matius (Matthew)
- Yohanes (John)
- Mazmur (Psalms)
- And more...

---

### 💳 Digital Member Card

**View Your Card:**
1. Tap "Kartu Jemaat" from home
2. See your digital member card with:
   - Your name
   - Member number
   - Contact info
   - QR code

**Use QR Code:**
- Show QR code at church events
- Event organizers can scan it
- Automatic attendance tracking

---

### 📷 Scanning Event QR Codes

**To Scan:**
1. Tap QR scanner icon in app bar OR
2. Tap "Scan Event" from home
3. Point camera at event QR code
4. Wait for automatic scan
5. See confirmation dialog
6. Tap "Selesai" (Done) or "Scan Lagi" (Scan Again)

**Toggle Flash:**
- Tap flash icon in app bar
- Useful in dark environments

---

### 🎯 Bible Reading Quest

**View Reading Plan:**
1. Tap "Quest" in bottom nav
2. See your progress:
   - Days completed / 365
   - Current streak
   - Overall progress percentage

**Complete a Day:**
1. Find today's reading in the list
2. Read the suggested chapters
3. Tap ✓ icon on the right
4. Confirm completion
5. See progress update!

**Track Progress:**
- Green checkmark = completed
- Progress bar shows overall %
- Streak shows consecutive days

---

### 🙏 Daily Devotional

**Read Today's Devotional:**
1. Tap "Renungan" from home OR
2. See preview on home screen
3. Read:
   - Title
   - Bible verse
   - Devotional content
   
**Save & Share:**
- Tap "Simpan" to save favorite
- Tap "Bagikan" to share

**View History:**
- Scroll down to see previous devotionals
- Tap any to read again

---

### 🎵 Today's Playlist

**View Playlist:**
1. Tap "Playlist Hari Ini" from home
2. See today's worship songs
3. Tap song to play (future feature)

**View Lyrics:**
1. Tap lyrics icon (📄) on any song
2. Read lyrics in bottom sheet
3. Swipe down to close

**Browse History:**
- Scroll down for previous playlists
- Tap to view old collections

---

## Tips & Tricks

### 🎨 Navigation Tips
- Use bottom nav for main sections
- Use app bar back button to go back
- Swipe right to go back (Android)

### 💾 Data Storage
- All data saved automatically
- Works offline (except future API features)
- Progress synced locally

### 📱 Best Practices
- Keep app updated
- Grant camera permission for QR scanner
- Grant storage permission for photos
- Complete daily reading for streak

---

## Common Questions

### How do I change my password?
Currently stored locally. Future update will add password change.

### Can I use this offline?
Yes! Bible, profile, and quest work offline.

### How do I add more Bible books?
This is sample data. Production version will have full Bible.

### Can multiple people use one device?
Yes, but one account per device currently. Logout and register new account.

### How do I backup my data?
Currently local only. Future update will add cloud sync.

---

## Troubleshooting

### App won't start?
```bash
flutter clean
flutter pub get
flutter run
```

### Camera not working for QR?
- Check camera permissions in device settings
- Android: Settings > Apps > my_app > Permissions

### Can't upload profile photo?
- Check storage permissions
- Ensure you have photos in gallery

### Bible not loading?
- Wait for database initialization
- Restart app if needed

---

## Development Mode Features

### Hot Reload (During Development)
Press `r` in terminal to reload changes without restarting

### Hot Restart
Press `R` in terminal to restart app

### Toggle Debug Mode
Press `p` in terminal to show performance overlay

---

## What's Next?

### Ready for Production
1. Add complete Bible database
2. Connect to backend API
3. Implement real authentication
4. Add more content (devotionals, songs)
5. Enable push notifications

### Extend Features
- Event calendar
- Prayer requests
- Community chat
- Online giving
- Audio Bible
- Video sermons

---

## Support

### Need Help?
- Read IMPLEMENTATION_SUMMARY.md for technical details
- Check README.md for full documentation
- Review code comments in files

### Report Issues
- Check error messages in terminal
- Review logs in IDE
- Document steps to reproduce

---

## Keyboard Shortcuts (Development)

| Key | Action |
|-----|--------|
| `r` | Hot reload |
| `R` | Hot restart |
| `q` | Quit |
| `h` | Help |
| `d` | Detach |
| `p` | Performance overlay |

---

## 🎉 Enjoy Your App!

You now have a fully functional church community app with:
- ✅ User registration and profiles
- ✅ Offline Bible reader
- ✅ Digital member cards
- ✅ QR event scanner
- ✅ Bible reading quest
- ✅ Daily devotionals
- ✅ Worship playlists

**Start using it today and build your faith community!** 🙏

---

*For technical questions, see IMPLEMENTATION_SUMMARY.md*
*For quick reference, see QUICK_START.md*
