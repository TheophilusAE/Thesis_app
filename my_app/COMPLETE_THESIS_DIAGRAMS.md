# Gereja App - Complete Thesis Diagrams

**Comprehensive thesis documentation for Gereja App (Church Community Application)**

All diagrams follow standard UML and systems design practices for academic thesis submission.

---

## ✅ DIAGRAM CHECKLIST - All 6 Types Included

| No. | Diagram Type | Location | Coverage |
|-----|--------------|----------|----------|
| 1 | **Flowchart** | [Section 1](#1-system-flowchart) | Complete app workflow from launch to all features |
| 2 | **Use Case Diagram** | [Section 2](#2-use-case-diagram) | All actors (User, Admin) and 40+ use cases |
| 3 | **Class Diagram** | [Section 3](#3-class-diagram) | 10+ classes with relationships (Providers, Models, Services) |
| 4 | **ERD (Entity Relationship Diagram)** | [Section 4](#4-entity-relationship-diagram) | 9 database tables with all relationships |
| 5 | **Activity Diagrams** | [Sections 5-12](#5-authentication-features) | 16 swimlane diagrams (one per feature) |
| 6 | **Sequence Diagrams** | [Sections 5-12](#5-authentication-features) | 16 UML sequence diagrams (one per feature) |

**Total: 36 Diagrams** ✅
- Main System: 4 diagrams (Flowchart, Use Case, Class, ERD)
- Features: 32 diagrams (16 features × Activity + Sequence)

---

## 📑 TABLE OF CONTENTS

### Main System Diagrams (Keseluruhan Sistem Aplikasi)
1. [System Flowchart](#1-system-flowchart) - Alur lengkap aplikasi
2. [Use Case Diagram](#2-use-case-diagram) - Semua aktor dan interaksi
3. [Class Diagram](#3-class-diagram) - Struktur objek aplikasi
4. [Entity Relationship Diagram (ERD)](#4-entity-relationship-diagram) - Skema database

### Feature-Specific Diagrams (Activity + Sequence for Each)
5. [Authentication Features](#5-authentication-features)
   - 5.1 Login
   - 5.2 Register
   - 5.3 Logout
6. [Bible Features](#6-bible-features)
   - 6.1 Bible Search & Read
   - 6.2 Home & Dashboard Navigation
7. [Quest Features](#7-quest-features)
   - 7.1 Mark Quest Complete
   - 7.2 View Quest Progress
8. [Devotional Features](#8-devotional-features)
   - 8.1 Devotional Management
9. [Playlist Features](#9-playlist-features)
   - 9.1 Playlist Management
10. [Profile Features](#10-profile-features)
    - 10.1 Profile Management
    - 10.2 Member Card Generation
11. [Attendance Features](#11-attendance-features)
    - 11.1 QR Scan & Attendance
12. [Admin Features](#12-admin-features)
    - 12.1 User Verification
    - 12.2 Admin Reports

---

# MAIN SYSTEM DIAGRAMS

## 1. SYSTEM FLOWCHART

Alur lengkap aplikasi dari launching hingga semua fitur utama dengan swimlane dan decision logic yang jelas.

```mermaid
flowchart TD
    %% ========== APP INITIALIZATION ==========
    Start(["START"]) --> InitApp["Initialize App<br/>Load SQLite Database<br/>Load SharedPreferences"]
    InitApp --> CheckDevice["Check Device Connection<br/>Load Cache"]
    
    %% ========== TOKEN VALIDATION ==========
    CheckDevice --> LoadToken{"Token<br/>Saved?"}
    LoadToken -->|No Token| AuthScreen["Go to Authentication Screen"]
    LoadToken -->|Token Exists| ValidateToken{"Is Token<br/>Still Valid?"}
    ValidateToken -->|Token Expired| ClearExpired["Delete Expired Token"]
    ClearExpired --> AuthScreen
    ValidateToken -->|Token Valid| LoadUserData["Load User Profile Data"]
    LoadUserData --> HomePage["Go to Home Screen"]
    
    %% ========== AUTHENTICATION SECTION ==========
    AuthScreen --> AuthType{{"User<br/>Action?"}}
    
    %% ===== LOGIN FLOW =====
    AuthType -->|Login| InputEmail["Input: Email Address"]
    InputEmail --> ValidateEmailFormat{"Is Email<br/>Format Valid?"}
    ValidateEmailFormat -->|Invalid| EmailFormatError["Display Error:<br/>Invalid Email Format"]
    EmailFormatError --> InputEmail
    ValidateEmailFormat -->|Valid| InputPassword["Input: Password"]
    InputPassword --> ValidatePasswordLen{"Is Password<br/>6+ Characters?"}
    ValidatePasswordLen -->|Too Short| PassLenError["Display Error:<br/>Password Too Short"]
    PassLenError --> InputPassword
    ValidatePasswordLen -->|Valid| QueryUser["Query Database:<br/>Find User by Email"]
    QueryUser --> UserExists{"User<br/>Found?"}
    UserExists -->|Not Found| UserNotFoundError["Display Error:<br/>User Not Found"]
    UserNotFoundError --> InputEmail
    UserExists -->|Found| CompareHash["Compare Password Hash<br/>with Input"]
    CompareHash --> PasswordMatch{"Password<br/>Matches?"}
    PasswordMatch -->|No Match| PasswordError["Display Error:<br/>Incorrect Password"]
    PasswordError --> InputPassword
    PasswordMatch -->|Match| CheckStatus["Query Database:<br/>Check User Status"]
    CheckStatus --> StatusCheck{"User<br/>Status?"}
    StatusCheck -->|Rejected| RejectedMsg["Display Error:<br/>Account Rejected"]
    RejectedMsg --> AuthScreen
    StatusCheck -->|Pending| PendingMsg["Display Message:<br/>Awaiting Admin Approval"]
    PendingMsg --> AuthScreen
    StatusCheck -->|Approved| GenerateToken["Generate Authentication Token"]
    GenerateToken --> SaveSession["Save Token to SharedPreferences<br/>Save User ID<br/>Save User Role"]
    SaveSession --> HomePage
    
    %% ===== REGISTER FLOW =====
    AuthType -->|Register| InputName["Input: Full Name"]
    InputName --> InputRegEmail["Input: Email Address"]
    InputRegEmail --> ValidateRegEmail{"Is Email<br/>Format Valid?"}
    ValidateRegEmail -->|Invalid| RegEmailError["Display Error:<br/>Invalid Email Format"]
    RegEmailError --> InputRegEmail
    ValidateRegEmail -->|Valid| CheckEmailExists["Query Database:<br/>Check if Email Exists"]
    CheckEmailExists --> EmailDuplicate{"Email<br/>Already Used?"}
    EmailDuplicate -->|Duplicate| DuplicateError["Display Error:<br/>Email Already Registered"]
    DuplicateError --> InputRegEmail
    EmailDuplicate -->|Unique| InputPhone["Input: Phone Number"]
    InputPhone --> InputRegPassword["Input: Password"]
    InputRegPassword --> ValidateRegPass{"Is Password<br/>6+ Characters?"}
    ValidateRegPass -->|Too Short| RegPassError["Display Error:<br/>Password Too Short"]
    RegPassError --> InputRegPassword
    ValidateRegPass -->|Valid| ConfirmPassword["Input: Confirm Password"]
    ConfirmPassword --> PassMatch{"Password<br/>Match?"}
    PassMatch -->|No Match| PassMismatch["Display Error:<br/>Passwords Don't Match"]
    PassMismatch --> InputRegPassword
    PassMatch -->|Match| InputBirthDate["Input: Birth Date<br/>Input: Baptism Date"]
    InputBirthDate --> HashPassword["Hash Password<br/>Generate Secure Hash"]
    HashPassword --> CreateUser["Insert New User Record<br/>into DATABASE"]
    CreateUser --> InsertSuccess{"User<br/>Created?"}
    InsertSuccess -->|Failed| CreateError["Display Error:<br/>Registration Failed"]
    CreateError --> InputName
    InsertSuccess -->|Success| SetUserStatus["Set User Status = PENDING<br/>Set User Role = MEMBER"]
    SetUserStatus --> RegistrationSuccess["Display Success Message:<br/>Account Created - Awaiting Approval"]
    RegistrationSuccess --> AuthScreen
    
    %% ========== HOME PAGE MAIN MENU ==========
    HomePage --> DisplayHome["Display Home Screen<br/>Show User Name<br/>Show Quest Progress<br/>Show Unread Devotionals"]
    DisplayHome --> MenuChoice{{"User Selects<br/>Feature?"}}
    
    %% ========== FEATURE 1: BIBLE READER ==========
    MenuChoice -->|Bible| BibleEntry["Go to Bible Screen"]
    BibleEntry --> SelectBibleAction{{"Select<br/>Bible Action?"}}
    
    %% Bible: Browse Books
    SelectBibleAction -->|Browse Books| QueryBooks["Query Database:<br/>Get All 66 Books"]
    QueryBooks --> DisplayBooks["Display List of Books<br/>Genesis to Revelation"]
    DisplayBooks --> SelectBook["User Selects Book"]
    SelectBook --> GetChapters["Query Database:<br/>Get Chapter Count<br/>for Selected Book"]
    GetChapters --> DisplayChapters["Display Chapter Numbers"]
    DisplayChapters --> SelectChapter["User Selects Chapter"]
    SelectChapter --> GetVerses["Query Database:<br/>Get All Verses<br/>in Chapter"]
    GetVerses --> DisplayVerses["Display Verses<br/>with Text & Numbers"]
    DisplayVerses --> BibleVerseMenu{{"Verse<br/>Action?"}}
    BibleVerseMenu -->|Read| DisplayVerse["Display Full Verse Text"]
    DisplayVerse --> BibleVerseMenu
    BibleVerseMenu -->|Add to Playlist| GoAddBible["Go to Add Verse Section"]
    GoAddBible --> SelectPlaylistB["User Selects Target Playlist"]
    SelectPlaylistB --> InsertPlaylistVerse["Insert Verse into PLAYLIST_VERSE Table"]
    InsertPlaylistVerse --> VerseAdded["Display Success:<br/>Verse Added to Playlist"]
    VerseAdded --> DisplayVerses
    BibleVerseMenu -->|Back| HomePage
    
    %% Bible: Search Verses
    SelectBibleAction -->|Search| InputSearchTerm["Input: Search Term<br/>Book/Chapter/Keyword"]
    InputSearchTerm --> QuerySearch["Query Database:<br/>Search BIBLE_VERSE Table<br/>Match Text & Book Name"]
    QuerySearch --> SearchResults{"Results<br/>Found?"}
    SearchResults -->|No Results| NoResultsMsg["Display Message:<br/>No Verses Found"]
    NoResultsMsg --> InputSearchTerm
    SearchResults -->|Results Found| DisplaySearchResults["Display Search Results<br/>List of Matching Verses"]
    DisplaySearchResults --> SelectSearchResult["User Selects a Verse"]
    SelectSearchResult --> DisplayVerseFull["Display Full Verse"]
    DisplayVerseFull --> HomePage
    
    %% Bible: View My Playlists
    SelectBibleAction -->|View Playlists| QueryMyPlaylists["Query Database:<br/>Get User's Playlists"]
    QueryMyPlaylists --> DisplayPlaylists["Display List of Playlists<br/>with Verse Counts"]
    DisplayPlaylists --> HomePage
    
    SelectBibleAction -->|Back| HomePage
    
    %% ========== FEATURE 2: DAILY QUEST ==========
    MenuChoice -->|Quest| QuestEntry["Go to Quest Screen"]
    QuestEntry --> SelectQuestAction{{"Select<br/>Quest Action?"}}
    
    %% Quest: View Progress
    SelectQuestAction -->|View Progress| QueryQuestStatus["Query Database:<br/>Get QUEST_PROGRESS<br/>for Current User"]
    QueryQuestStatus --> CalcProgress["Calculate Progress:<br/>Current Day / 365"]
    CalcProgress --> GetStreak["Query Last Completed Date<br/>Calculate Streak Days"]
    GetStreak --> DisplayQuestStats["Display Quest Stats:<br/>Progress %<br/>Current Day<br/>Streak Count"]
    DisplayQuestStats --> ShowQuestText["Display Today's Quest<br/>Bible Reading Challenge"]
    ShowQuestText --> SelectQuestAction
    
    %% Quest: Mark Complete
    SelectQuestAction -->|Mark Complete| QueryToday["Query Database:<br/>Get Last Completion Date"]
    QueryToday --> CheckCompleted{"Completed<br/>Today?"}
    CheckCompleted -->|Already Done| AlreadyCompleteMsg["Display Message:<br/>Already Completed Today"]
    AlreadyCompleteMsg --> SelectQuestAction
    CheckCompleted -->|Not Done| MarkQuestDone["Update QUEST_PROGRESS:<br/>Increment current_day<br/>Update last_completed_date<br/>Update streak_count"]
    MarkQuestDone --> UpdateCalc["Recalculate Progress %"]
    UpdateCalc --> SaveQuestUpdate["Save to SQLite Database"]
    SaveQuestUpdate --> QuestComplete["Display Success:<br/>Quest Completed!<br/>Streak: +1"]
    QuestComplete --> SelectQuestAction
    
    SelectQuestAction -->|Back| HomePage
    
    %% ========== FEATURE 3: DEVOTIONAL ==========
    MenuChoice -->|Devotional| DevEntry["Go to Devotional Screen"]
    DevEntry --> SelectDevAction{{"Select<br/>Devotional Action?"}}
    
    %% Devotional: View All
    SelectDevAction -->|View All| QueryDevotionals["Query Database:<br/>Get All DEVOTIONAL Records<br/>Published = True"]
    QueryDevotionals --> DisplayDevotionals["Display Devotional List<br/>Title, Date, Author"]
    DisplayDevotionals --> SelectDev["User Selects Devotional"]
    SelectDev --> GetDevVerses["Query DEVOTIONAL_VERSE Table<br/>Get Associated Verses"]
    GetDevVerses --> DisplayDevContent["Display:<br/>Devotional Title<br/>Content<br/>Associated Verses"]
    DisplayDevContent --> SelectDevAction
    
    %% Devotional: Create New
    SelectDevAction -->|Create| InputDevTitle["Input: Devotional Title"]
    InputDevTitle --> InputDevContent["Input: Devotional Content<br/>Text/Reflection"]
    InputDevContent --> SelectDevVerses["Select Associated Bible Verses"]
    SelectDevVerses --> CreateDevRecord["Insert Record into DEVOTIONAL Table:<br/>is_published = False<br/>user_id = Current User<br/>created_at = Current Timestamp"]
    CreateDevRecord --> InsertDevVerses["Insert Records into DEVOTIONAL_VERSE Table<br/>Link Devotional to Selected Verses"]
    InsertDevVerses --> DevCreated["Display Success:<br/>Devotional Created - Draft Status"]
    DevCreated --> SelectDevAction
    
    %% Devotional: Publish
    SelectDevAction -->|Publish| QueryMyDev["Query Database:<br/>Get User's Draft Devotionals"]
    QueryMyDev --> DisplayMyDev["Display List of Draft Devotionals"]
    DisplayMyDev --> SelectDraftDev["User Selects Draft to Publish"]
    SelectDraftDev --> UpdatePublish["Update DEVOTIONAL Record:<br/>is_published = True"]
    UpdatePublish --> SavePublish["Save to Database"]
    SavePublish --> PublishSuccess["Display Success:<br/>Devotional Published"]
    PublishSuccess --> SelectDevAction
    
    SelectDevAction -->|Back| HomePage
    
    %% ========== FEATURE 4: PLAYLIST ==========
    MenuChoice -->|Playlist| PlayEntry["Go to Playlist Screen"]
    PlayEntry --> SelectPlayAction{{"Select<br/>Playlist Action?"}}
    
    %% Playlist: View All
    SelectPlayAction -->|View All| QueryPlaylists["Query Database:<br/>Get All PLAYLIST Records<br/>is_public = True"]
    QueryPlaylists --> DisplayAllPlaylists["Display Playlist List<br/>Title, Verse Count, Owner"]
    DisplayAllPlaylists --> SelectPlaylist["User Selects Playlist"]
    SelectPlaylist --> GetPlayVerses["Query PLAYLIST_VERSE Table<br/>Get All Verses in Order"]
    GetPlayVerses --> DisplayPlayContent["Display Playlist:<br/>Title, Verses in Order"]
    DisplayPlayContent --> SelectPlayAction
    
    %% Playlist: Create New
    SelectPlayAction -->|Create| InputPlayTitle["Input: Playlist Title"]
    InputPlayTitle --> InputPlayDesc["Input: Playlist Description"]
    InputPlayDesc --> ChoosePrivacy["Choose:<br/>Public / Private"]
    ChoosePrivacy --> CreatePlayRecord["Insert Record into PLAYLIST Table:<br/>user_id = Current User<br/>is_public = User Selection<br/>created_at = Current Timestamp"]
    CreatePlayRecord --> PlayCreated["Display Success:<br/>Playlist Created - Empty"]
    PlayCreated --> SelectPlayAction
    
    %% Playlist: Edit
    SelectPlayAction -->|Edit| QueryMyPlaylists2["Query Database:<br/>Get User's Playlists"]
    QueryMyPlaylists2 --> DisplayEditPlaylists["Display User's Playlists"]
    DisplayEditPlaylists --> SelectEditPlaylist["User Selects Playlist to Edit"]
    SelectEditPlaylist --> EditWhat{{"Edit<br/>What?"}}
    EditWhat -->|Title/Description| EditPlayDetails["Update Playlist Details<br/>Save to Database"]
    EditPlayDetails --> SelectPlayAction
    EditWhat -->|Add Verse| SelectVersesToAdd["Browse & Select Verses<br/>from Bible Database"]
    SelectVersesToAdd --> InsertToPlaylist["Insert Verses into PLAYLIST_VERSE Table<br/>with order_in_playlist"]
    InsertToPlaylist --> SelectPlayAction
    EditWhat -->|Remove Verse| SelectVersesToRemove["Select Verses to Remove"]
    SelectVersesToRemove --> DeleteFromPlaylist["Delete from PLAYLIST_VERSE Table"]
    DeleteFromPlaylist --> SelectPlayAction
    EditWhat -->|Change Privacy| UpdatePrivacy["Update is_public Field"]
    UpdatePrivacy --> SelectPlayAction
    
    SelectPlayAction -->|Back| HomePage
    
    %% ========== FEATURE 5: PROFILE MANAGEMENT ==========
    MenuChoice -->|Profile| ProfileEntry["Go to Profile Screen"]
    ProfileEntry --> SelectProfileAction{{"Select<br/>Profile Action?"}}
    
    %% Profile: View Profile
    SelectProfileAction -->|View Profile| QueryProfile["Query DATABASE:<br/>Get Current User Record"]
    QueryProfile --> DisplayProfile["Display User Profile:<br/>Name, Email, Phone<br/>Birth Date, Baptism Date<br/>Member Card Number<br/>Account Status, Role"]
    DisplayProfile --> SelectProfileAction
    
    %% Profile: Edit Profile
    SelectProfileAction -->|Edit| EditWhat2{{"Edit<br/>Field?"}}
    EditWhat2 -->|Name| UpdateName["Update User Name<br/>Save to DATABASE"]
    UpdateName --> SelectProfileAction
    EditWhat2 -->|Phone| UpdatePhone["Update Phone Number<br/>Save to DATABASE"]
    UpdatePhone --> SelectProfileAction
    EditWhat2 -->|Birthdate| UpdateBirthdate["Update Birth Date<br/>Save to DATABASE"]
    UpdateBirthdate --> SelectProfileAction
    EditWhat2 -->|Baptism Date| UpdateBaptism["Update Baptism Date<br/>Save to DATABASE"]
    UpdateBaptism --> SelectProfileAction
    
    %% Profile: Generate Member Card
    SelectProfileAction -->|Generate Card| CheckMemberCard{"Member Card<br/>Exists?"}
    CheckMemberCard -->|Yes| DisplayCard["Display Existing Card:<br/>Card Number<br/>QR Code Image"]
    DisplayCard --> SelectProfileAction
    CheckMemberCard -->|No| GenerateCard["Generate New Member Card<br/>Create Unique Card Number<br/>Generate QR Code<br/>Set Expiry Date (1 Year)"]
    GenerateCard --> InsertCard["Insert Record into MEMBER_CARD Table"]
    InsertCard --> CardGenerated["Display New Card:<br/>Card Number<br/>QR Code<br/>Expiry Date"]
    CardGenerated --> SelectProfileAction
    
    SelectProfileAction -->|Back| HomePage
    
    %% ========== FEATURE 6: ATTENDANCE MANAGEMENT ==========
    MenuChoice -->|Attendance| AttEntry["Go to Attendance Screen"]
    AttEntry --> SelectAttAction{{"Select<br/>Attendance Action?"}}
    
    %% Attendance: Scan QR
    SelectAttAction -->|Scan QR| RequestCamera["Request Camera Permission"]
    RequestCamera --> CameraGranted{"Permission<br/>Granted?"}
    CameraGranted -->|Denied| PermissionError["Display Error:<br/>Camera Permission Denied"]
    PermissionError --> SelectAttAction
    CameraGranted -->|Granted| OpenCamera["Open Camera Interface"]
    OpenCamera --> CaptureQR["User Scans QR Code"]
    CaptureQR --> ParseQR["Parse QR Code Data"]
    ParseQR --> ValidateQR{"QR Code<br/>Valid?"}
    ValidateQR -->|Invalid| InvalidQRMsg["Display Error:<br/>Invalid QR Code Format"]
    InvalidQRMsg --> OpenCamera
    ValidateQR -->|Valid| ExtractEventInfo["Extract:<br/>Event Name<br/>Event Date"]
    ExtractEventInfo --> QueryAttendance["Query ATTENDANCE_RECORD Table:<br/>Check if Already Scanned Today<br/>for This Event"]
    QueryAttendance --> AlreadyScanned{"Already<br/>Scanned?"}
    AlreadyScanned -->|Yes| AlreadyAttMsg["Display Message:<br/>Already Marked Present"]
    AlreadyAttMsg --> SelectAttAction
    AlreadyScanned -->|No| InsertAttendance["Insert Record into ATTENDANCE_RECORD Table:<br/>user_id = Current User<br/>event_name = Event<br/>attendance_time = Current Time<br/>qr_code_scanned = True"]
    InsertAttendance --> AttendanceSuccess["Display Success:<br/>Attendance Recorded"]
    AttendanceSuccess --> SelectAttAction
    
    %% Attendance: View History
    SelectAttAction -->|View History| QueryAttHistory["Query ATTENDANCE_RECORD Table:<br/>Get Current User's Records<br/>Order by attendance_time DESC"]
    QueryAttHistory --> DisplayAttHistory["Display Attendance History:<br/>Event, Date, Time"]
    DisplayAttHistory --> SelectAttAction
    
    SelectAttAction -->|Back| HomePage
    
    %% ========== FEATURE 7: ADMIN MANAGEMENT ==========
    MenuChoice -->|Admin| AdminEntry["Go to Admin Screen"]
    AdminEntry --> CheckAdminRole{"User<br/>Role = ADMIN?"}
    CheckAdminRole -->|No| AccessDenied["Display Error:<br/>Access Denied<br/>Admin Only"]
    AccessDenied --> HomePage
    CheckAdminRole -->|Yes| SelectAdminAction{{"Select<br/>Admin Action?"}}
    
    %% Admin: View Pending
    SelectAdminAction -->|View Pending| QueryPending["Query USER Table:<br/>Get Users with status = PENDING"]
    QueryPending --> DisplayPending["Display Pending Users List:<br/>Name, Email, Registration Date"]
    DisplayPending --> SelectAdminAction
    
    %% Admin: Approve/Reject
    SelectAdminAction -->|Approve/Reject| SelectPendingUser["User Selects a Pending User"]
    SelectPendingUser --> ReviewAction{{"Admin<br/>Action?"}}
    ReviewAction -->|Approve| UpdateUserApproved["Update USER Record:<br/>status = APPROVED"]
    UpdateUserApproved --> SaveApproval["Save to DATABASE"]
    SaveApproval --> ApprovalMsg["Display Success:<br/>User Approved"]
    ApprovalMsg --> SelectAdminAction
    ReviewAction -->|Reject| UpdateUserRejected["Update USER Record:<br/>status = REJECTED"]
    UpdateUserRejected --> SaveRejection["Save to DATABASE"]
    SaveRejection --> RejectionMsg["Display Success:<br/>User Rejected"]
    RejectionMsg --> SelectAdminAction
    
    %% Admin: View Reports
    SelectAdminAction -->|View Reports| SelectReport{{"Select<br/>Report Type?"}}
    SelectReport -->|User Stats| CalcUserStats["Count:<br/>Total Users<br/>Active Users<br/>Pending Users<br/>Rejected Users"]
    CalcUserStats --> DisplayUserStats["Display User Statistics"]
    DisplayUserStats --> SelectAdminAction
    SelectReport -->|Quest Stats| QueryQuestStats["Query QUEST_PROGRESS Table:<br/>Calculate Average Progress<br/>Top Streaks"]
    QueryQuestStats --> DisplayQuestStats2["Display Quest Statistics"]
    DisplayQuestStats2 --> SelectAdminAction
    SelectReport -->|Attendance Stats| QueryAttStats["Query ATTENDANCE_RECORD Table:<br/>Calculate Total Attendance<br/>Events Attended"]
    QueryAttStats --> DisplayAttStats["Display Attendance Statistics"]
    DisplayAttStats --> SelectAdminAction
    
    SelectAdminAction -->|Back| HomePage
    
    %% ========== LOGOUT ==========
    MenuChoice -->|Logout| ConfirmLogout{"Confirm<br/>Logout?"}
    ConfirmLogout -->|Cancel| HomePage
    ConfirmLogout -->|Confirm| ClearToken["Delete Token from SharedPreferences"]
    ClearToken --> ClearCache["Clear App Cache<br/>Clear Session Data"]
    ClearCache --> LogoutSuccess["Display Message:<br/>Successfully Logged Out"]
    LogoutSuccess --> AuthScreen
    
    %% ========== END ==========
    AuthType -->|Exit App| EndApp(["END"])
    
    %% ========== STYLING ==========
    style Start fill:#4CAF50,stroke:#2E7D32,stroke-width:3px,color:#fff
    style EndApp fill:#D32F2F,stroke:#B71C1C,stroke-width:3px,color:#fff
    style HomePage fill:#2196F3,stroke:#1565C0,stroke-width:2px,color:#fff
    style AuthScreen fill:#FF9800,stroke:#E65100,stroke-width:2px,color:#fff
    style BibleEntry fill:#2196F3,stroke:#1565C0,stroke-width:2px,color:#fff
    style QuestEntry fill:#9C27B0,stroke:#6A1B9A,stroke-width:2px,color:#fff
    style DevEntry fill:#F44336,stroke:#C62828,stroke-width:2px,color:#fff
    style PlayEntry fill:#00BCD4,stroke:#0097A7,stroke-width:2px,color:#fff
    style ProfileEntry fill:#673AB7,stroke:#4527A0,stroke-width:2px,color:#fff
    style AttEntry fill:#FF5722,stroke:#D84315,stroke-width:2px,color:#fff
    style AdminEntry fill:#D32F2F,stroke:#B71C1C,stroke-width:2px,color:#fff
```

---

## 2. USE CASE DIAGRAM

Semua aktor dan gunakasus di seluruh sistem.

```mermaid
graph TB
    subgraph Actors["👥 ACTORS"]
        User["👤 User/Jemaat"]
        Admin["👨‍💼 Admin"]
        System["⚙️ System"]
    end
    
    subgraph AuthUseCases["🔐 AUTHENTICATION & AUTHORIZATION"]
        UC1["Login"]
        UC2["Register"]
        UC3["Logout"]
        UC31["Verify Admin Role"]
    end
    
    subgraph BibleUseCases["📖 BIBLE READING"]
        UC4["View All Books"]
        UC5["Select Chapter"]
        UC6["View Verses"]
        UC7["Search Verse"]
        UC8["Add to Playlist"]
    end
    
    subgraph QuestUseCases["🎯 DAILY QUEST"]
        UC9["View Quest Status"]
        UC10["Mark Quest Complete"]
        UC11["View Streak"]
        UC12["View Progress"]
    end
    
    subgraph DevotionalUseCases["🙏 DEVOTIONAL"]
        UC13["View Devotional"]
        UC14["Create Devotional"]
        UC15["Add Verse to Dev"]
        UC16["Publish Devotional"]
        UC17["Share Devotional"]
    end
    
    subgraph PlaylistUseCases["📚 PLAYLIST MANAGEMENT"]
        UC18["Create Playlist"]
        UC19["Add Verse to Playlist"]
        UC20["Reorder Verses"]
        UC21["Delete Verse"]
        UC22["Delete Playlist"]
    end
    
    subgraph ProfileUseCases["👤 PROFILE & CARD"]
        UC23["View Profile"]
        UC24["Edit Profile"]
        UC25["Upload Photo"]
        UC26["Generate Member Card"]
        UC27["View QR Code"]
    end
    
    subgraph AttendanceUseCases["📷 ATTENDANCE"]
        UC28["Scan QR Code"]
        UC29["Record Attendance"]
        UC30["View Attendance History"]
    end
    
    subgraph AdminUseCases["🔑 ADMIN MANAGEMENT"]
        UC32["View Pending Users"]
        UC33["Review User Documents"]
        UC34["Approve User"]
        UC35["Reject User"]
        UC36["Generate Member Card"]
        UC37["View Reports"]
    end
    
    User --> UC1
    User --> UC2
    User --> UC3
    User --> UC4
    User --> UC5
    User --> UC6
    User --> UC7
    User --> UC8
    User --> UC9
    User --> UC10
    User --> UC11
    User --> UC12
    User --> UC13
    User --> UC14
    User --> UC15
    User --> UC16
    User --> UC17
    User --> UC18
    User --> UC19
    User --> UC20
    User --> UC21
    User --> UC22
    User --> UC23
    User --> UC24
    User --> UC25
    User --> UC26
    User --> UC27
    User --> UC28
    User --> UC29
    User --> UC30
    
    Admin --> UC1
    Admin --> UC31
    Admin --> UC32
    Admin --> UC33
    Admin --> UC34
    Admin --> UC35
    Admin --> UC36
    Admin --> UC37
    
    System -.->|triggers| UC10
    System -.->|sends| UC12
    System -.->|validates| UC31
    
    UC1 -.->|requires| UC2
    UC26 -.->|generates| UC27
    UC29 -.->|uses| UC28
    UC34 -.->|generates| UC36
    UC10 -.->|updates| UC11
    
    style AuthUseCases fill:#E3F2FD,stroke:#1976D2
    style BibleUseCases fill:#E8F5E9,stroke:#388E3C
    style QuestUseCases fill:#F3E5F5,stroke:#7B1FA2
    style DevotionalUseCases fill:#FCE4EC,stroke:#C2185B
    style PlaylistUseCases fill:#E0F2F1,stroke:#00796B
    style ProfileUseCases fill:#FFF3E0,stroke:#F57C00
    style AttendanceUseCases fill:#FFF9C4,stroke:#F57F17
    style AdminUseCases fill:#FFEBEE,stroke:#D32F2F
```

---

## 3. CLASS DIAGRAM

Struktur objek lengkap dari aplikasi.

```mermaid
classDiagram
    class User {
        -userId: String
        -name: String
        -email: String
        -phone: String
        -passwordHash: String
        -role: String
        -status: String
        -memberCardNumber: String
        -birthDate: DateTime
        -baptismDate: DateTime
        -profileImage: String
        -familyGroup: String
        +login(): bool
        +updateProfile(data): void
        +logout(): void
        +generateMemberCard(): String
    }
    
    class AuthProvider {
        -currentUser: User?
        -isLoggedIn: bool
        -authToken: String?
        -isAdmin: bool
        +login(email, password): Future
        +register(data): Future
        +logout(): void
        +checkApproval(): Future
        +verifyAdminRole(): bool
        +notifyListeners(): void
    }
    
    class BibleVerse {
        -verseId: int
        -bookName: String
        -chapterNumber: int
        -verseNumber: int
        -verseText: String
        -version: String
        +getFullReference(): String
        +getNextVerse(): BibleVerse
        +getPreviousVerse(): BibleVerse
    }
    
    class BibleProvider {
        -books: List~String~
        -verses: List~BibleVerse~
        -cachedBooks: Map
        -selectedBook: String
        +loadBooks(): Future
        +loadChapters(book): Future
        +loadVerses(book, chapter): Future
        +searchVerses(keyword): Future
        +addToPlaylist(verse): void
        +notifyListeners(): void
    }
    
    class Quest {
        -questId: String
        -userId: String
        -currentDay: int
        -streakCount: int
        -maxStreak: int
        -lastCompletedDate: DateTime
        -progressPercentage: float
        -dailyVerseId: int
        +markComplete(): Future
        +resetStreak(): void
        +calculateProgress(): float
        +getStreak(): int
    }
    
    class QuestProvider {
        -quest: Quest?
        -dailyVerses: List~BibleVerse~
        -isCompleteToday: bool
        +loadQuestData(): Future
        +markQuestComplete(): Future
        +checkTodayCompleted(): bool
        +calculateStreak(): int
        +notifyListeners(): void
    }
    
    class Devotional {
        -devotionalId: String
        -userId: String
        -title: String
        -content: String
        -verses: List~BibleVerse~
        -isPublished: bool
        -createdAt: DateTime
        -updatedAt: DateTime
        +publishDevotional(): Future
        +addVerse(verse): void
        +removeVerse(verse): void
        +shareDevotional(): Future
    }
    
    class Playlist {
        -playlistId: String
        -userId: String
        -title: String
        -description: String
        -verses: List~BibleVerse~
        -isPublic: bool
        -createdAt: DateTime
        +addVerse(verse): void
        +removeVerse(verse): void
        +reorderVerse(from, to): void
        +delete(): void
    }
    
    class AttendanceRecord {
        -attendanceId: String
        -userId: String
        -memberCardNumber: String
        -eventName: String
        -attendanceTime: DateTime
        -qrCodeScanned: String
        +recordAttendance(): void
        +getAttendanceStatus(): String
        +getAttendanceHistory(): List
    }
    
    class MemberCard {
        -cardId: String
        -userId: String
        -cardNumber: String
        -qrCode: String
        -createdAt: DateTime
        +generateQR(): String
        +downloadCard(): void
        +shareCard(): void
    }
    
    class ThemeProvider {
        -isDarkMode: bool
        +toggleTheme(): void
        +setTheme(mode): void
        +notifyListeners(): void
    }
    
    User "1" --> "1" AuthProvider
    User "1" --> "1" Quest
    User "1" --> "*" Devotional
    User "1" --> "*" Playlist
    User "1" --> "*" AttendanceRecord
    User "1" --> "0..1" MemberCard
    BibleVerse "many" --> "1" BibleProvider
    BibleVerse "many" --> "*" Playlist
    BibleVerse "many" --> "*" Devotional
    Quest "1" --> "1" QuestProvider
    Quest "1" --> "*" BibleVerse
```

---

## 4. ENTITY RELATIONSHIP DIAGRAM

Skema database lengkap dengan semua relationships.

```mermaid
erDiagram
    USER ||--o{ QUEST_PROGRESS : has
    USER ||--o{ PLAYLIST : creates
    USER ||--o{ DEVOTIONAL : creates
    USER ||--o{ ATTENDANCE_RECORD : generates
    USER ||--o{ MEMBER_CARD : has
    PLAYLIST ||--o{ PLAYLIST_VERSE : contains
    BIBLE_VERSE ||--o{ PLAYLIST_VERSE : "added to"
    BIBLE_VERSE ||--o{ DEVOTIONAL_VERSE : references
    DEVOTIONAL ||--o{ DEVOTIONAL_VERSE : includes
    
    USER {
        string user_id PK
        string name
        string email UK
        string phone
        string password_hash
        string role "user|admin"
        string membership_status "pending|approved|rejected"
        string member_card_number UK
        string family_group
        string profile_image_url
        date birth_date
        date baptism_date
        timestamp created_at
        timestamp updated_at
    }
    
    QUEST_PROGRESS {
        string quest_id PK
        string user_id FK
        int current_day "1-365"
        int streak_count
        int max_streak
        float progress_percentage
        int daily_verse_id FK
        timestamp last_completed_date
        timestamp created_at
    }
    
    BIBLE_VERSE {
        int verse_id PK
        string book_name "66 books"
        int chapter_number
        int verse_number
        string verse_text "Indonesian"
        string version
        timestamp created_at
    }
    
    PLAYLIST {
        string playlist_id PK
        string user_id FK
        string title
        string description
        boolean is_public
        int verse_count
        timestamp created_at
        timestamp updated_at
    }
    
    PLAYLIST_VERSE {
        string playlist_verse_id PK
        string playlist_id FK
        int verse_id FK
        int order_in_playlist
    }
    
    DEVOTIONAL {
        string devotional_id PK
        string user_id FK
        string title
        string content
        string devotional_type
        boolean is_published
        int view_count
        timestamp published_date
        timestamp created_at
        timestamp updated_at
    }
    
    DEVOTIONAL_VERSE {
        string devotional_verse_id PK
        string devotional_id FK
        int verse_id FK
        int order_in_devotional
    }
    
    ATTENDANCE_RECORD {
        string attendance_id PK
        string user_id FK
        string member_card_number FK
        string event_name
        timestamp attendance_time
        string qr_code_scanned
        string status "present|late|absent"
    }
    
    MEMBER_CARD {
        string card_id PK
        string user_id FK
        string card_number UK
        string qr_code_image
        boolean is_active
        timestamp created_at
        timestamp expiry_date
    }
```

---

# FEATURE-SPECIFIC DIAGRAMS

Each feature has 2 diagrams: Activity (swimlane) + Sequence (UML template format)

---

# 5. AUTHENTICATION FEATURES (Login, Register, Logout)

## 5.1 LOGIN

### 5.1.1 Activity Diagram: Login Process

```mermaid
graph TD
    subgraph User1[" 👤 USER "]
        U1([Start])
        U2["📝 Enter Email<br/>& Password"]
        U3{"Valid<br/>Input?"}
        U4["⏳ Pending<br/>Approval"]
        U5["✅ Success"]
    end
    
    subgraph App1[" 📱 APP/FRONTEND "]
        A1["Validate<br/>Format & Length"]
        A2{"Pass?"}
        A3["❌ Error<br/>Message"]
        A4["📤 Send to<br/>API"]
        A5{"Check<br/>Status"}
        A6["⏳ Show Pending"]
        A7["💾 Save Token<br/>to Storage"]
    end
    
    subgraph API1[" 🔌 AUTH API "]
        B1["Query User<br/>from DB"]
        B2{"User<br/>Found?"}
        B3{"Password<br/>Match?"}
        B4["Check Admin<br/>Approval"]
        B5{"Approved?"}
    end
    
    subgraph DB1[" 💾 DATABASE "]
        D1[(Users Table)]
    end
    
    U1 --> U2
    U2 --> A1
    A1 --> A2
    A2 -->|No| A3
    A3 --> U3
    U3 -->|No| U1
    A2 -->|Yes| A4
    A4 --> B1
    B1 --> D1
    D1 --> B2
    B2 -->|No| A3
    B2 -->|Yes| B3
    B3 -->|No| A3
    B3 -->|Yes| B4
    B4 --> B5
    B5 -->|No| A6
    A6 --> U4
    U4 --> A5
    B5 -->|Yes| A7
    A7 --> A5
    A5 -->|OK| U5
    U5 --> U1
    
    style User1 fill:#E3F2FD,stroke:#1976D2
    style App1 fill:#F3E5F5,stroke:#7B1FA2
    style API1 fill:#E8F5E9,stroke:#388E3C
    style DB1 fill:#FFF3E0,stroke:#F57C00
```

### 5.1.2 Sequence Diagram: Login Process

```mermaid
sequenceDiagram
    autonumber
    actor User as 👤 User
    participant UI as 📱 Flutter App
    participant Validator as ✓ Validator
    participant AuthAPI as 🔌 Auth API
    participant Database as 💾 Database
    participant Storage as 📦 Storage
    
    rect rgb(200, 230, 230)
    Note over User,Storage: INPUT & VALIDATION PHASE
    User->>UI: Enter Email & Password
    UI->>Validator: Validate Format
    alt Format Invalid
        Validator-->>UI: ❌ Error
        UI-->>User: Show Error
    else Format Valid
        Validator-->>UI: ✅ Pass
    end
    end
    
    rect rgb(200, 220, 250)
    Note over UI,AuthAPI: AUTHENTICATION PHASE
    UI->>AuthAPI: POST /auth/login
    AuthAPI->>Database: Query User by Email
    Database-->>AuthAPI: User Record
    alt User Not Found
        AuthAPI-->>UI: ❌ 401 Invalid
        UI-->>User: ❌ Invalid Credentials
    else User Found
        AuthAPI->>Validator: Hash Match?
        alt Password Mismatch
            Validator-->>AuthAPI: ❌ No
            AuthAPI-->>UI: ❌ 401 Invalid
            UI-->>User: ❌ Invalid Credentials
        else Password Match
            Validator-->>AuthAPI: ✅ Yes
            AuthAPI->>Database: Check Approval
            Database-->>AuthAPI: Status
        end
    end
    end
    
    rect rgb(220, 250, 220)
    Note over AuthAPI,Storage: APPROVAL & SESSION PHASE
    alt User Not Approved
        AuthAPI-->>UI: ⏳ 202 Pending
        UI-->>User: Awaiting Admin
    else User Approved
        AuthAPI-->>UI: ✅ 200 OK + Token
        UI->>Storage: Save Auth Token
        Storage-->>UI: ✅ Saved
        UI-->>User: 🚀 Navigate Home
    end
    end
```

---

## 5.2 REGISTER

### 5.2.1 Activity Diagram: Registration Process

```mermaid
graph TD
    subgraph User2[" 👤 USER "]
        U1([Start])
        U2["📋 Enter<br/>Personal Data"]
        U3{"Valid<br/>Data?"}
        U4["✅ Registered<br/>Pending"]
    end
    
    subgraph App2[" 📱 APP/FRONTEND "]
        A1["Validate<br/>All Fields"]
        A2{"Pass?"}
        A3["❌ Error<br/>Message"]
        A4["📤 Send<br/>to API"]
        A5["✅ Show<br/>Success"]
    end
    
    subgraph API2[" 🔌 AUTH API "]
        B1["Check Email<br/>Exists?"]
        B2["Generate<br/>User ID"]
        B3["Hash<br/>Password"]
        B4["Insert into<br/>Users Table"]
        B5["Send<br/>Verification"]
    end
    
    subgraph DB2[" 💾 DATABASE "]
        D1[(Users Table<br/>status: pending)]
    end
    
    U1 --> U2
    U2 --> A1
    A1 --> A2
    A2 -->|No| A3
    A3 --> U3
    U3 -->|No| U1
    A2 -->|Yes| A4
    A4 --> B1
    B1 --> B2
    B2 --> B3
    B3 --> B4
    B4 --> D1
    D1 --> B5
    B5 --> A5
    A5 --> U4
    U4 --> U1
    
    style User2 fill:#E3F2FD,stroke:#1976D2
    style App2 fill:#F3E5F5,stroke:#7B1FA2
    style API2 fill:#E8F5E9,stroke:#388E3C
    style DB2 fill:#FFF3E0,stroke:#F57C00
```

### 5.2.2 Sequence Diagram: Registration Process

```mermaid
sequenceDiagram
    autonumber
    actor User as 👤 User
    participant UI as 📱 Flutter App
    participant Validator as ✓ Validator
    participant RegAPI as 🔌 Register API
    participant Database as 💾 Database
    participant Email as 📧 Email Service
    
    rect rgb(200, 230, 230)
    Note over User,Email: INPUT & VALIDATION PHASE
    User->>UI: Enter User Data
    UI->>Validator: Validate All Fields
    alt Validation Failed
        Validator-->>UI: ❌ Error List
        UI-->>User: Show Errors
    else Validation Passed
        Validator-->>UI: ✅ All Valid
    end
    end
    
    rect rgb(200, 220, 250)
    Note over UI,RegAPI: REGISTRATION PHASE
    UI->>RegAPI: POST /auth/register
    RegAPI->>Database: Check Email Exists
    alt Email Already Used
        Database-->>RegAPI: ❌ Email Exists
        RegAPI-->>UI: ❌ 409 Conflict
        UI-->>User: Email Already Used
    else Email Available
        Database-->>RegAPI: ✅ Available
        RegAPI->>Validator: Hash Password
        Validator-->>RegAPI: Hashed
        RegAPI->>Database: BEGIN TRANSACTION
        RegAPI->>Database: INSERT INTO Users
        Database-->>RegAPI: User ID Generated
        RegAPI->>Database: COMMIT
    end
    end
    
    rect rgb(220, 250, 220)
    Note over RegAPI,Email: VERIFICATION PHASE
    RegAPI->>Email: Send Verification
    Email-->>RegAPI: ✅ Email Sent
    RegAPI-->>UI: ✅ 201 Created
    UI-->>User: ✅ Registration Complete
    end
```

---

## 5.3 LOGOUT

### 5.3.1 Activity Diagram: Logout Process

```mermaid
graph TD
    subgraph UserL[" 👤 USER "]
        UL1([Start])
        UL2["🚪 Click<br/>Logout"]
        UL3{"Confirm<br/>Logout?"}
        UL4["✅ Logged Out"]
    end
    
    subgraph AppL[" 📱 APP/FRONTEND "]
        AL1["Show Confirmation<br/>Dialog"]
        AL2{"User<br/>Confirms?"}
        AL3["❌ Cancel"]
        AL4["Clear App State"]
        AL5["Delete Token"]
        AL6["Navigate to<br/>Auth Screen"]
    end
    
    subgraph ProviderL[" 👤 AUTH PROVIDER "]
        PL1["logout()"]
        PL2["clearSession()"]
        PL3["clearCache()"]
    end
    
    subgraph StorageL[" 📦 STORAGE "]
        SL1["SharedPreferences<br/>AuthToken"]
    end
    
    UL1 --> UL2
    UL2 --> AL1
    AL1 --> AL2
    AL2 -->|No| AL3
    AL3 --> UL1
    AL2 -->|Yes| PL1
    PL1 --> PL2
    PL2 --> SL1
    SL1 --> PL3
    PL3 --> AL4
    AL4 --> AL5
    AL5 --> AL6
    AL6 --> UL4
    UL4 --> UL1
    
    style UserL fill:#E3F2FD,stroke:#1976D2
    style AppL fill:#F3E5F5,stroke:#7B1FA2
    style ProviderL fill:#E8F5E9,stroke:#388E3C
    style StorageL fill:#FFF3E0,stroke:#F57C00
```

### 5.3.2 Sequence Diagram: Logout Process

```mermaid
sequenceDiagram
    autonumber
    actor User as 👤 User
    participant UI as 📱 App UI
    participant Provider as 👤 Auth Provider
    participant Storage as 📦 SharedPreferences
    participant Navigation as 🧭 Navigation
    
    rect rgb(200, 230, 250)
    Note over User,Navigation: LOGOUT INITIATION
    User->>UI: Click Logout Button
    UI-->>User: Show Confirmation Dialog
    User->>UI: Confirm Logout
    end
    
    rect rgb(220, 230, 250)
    Note over Provider,Storage: SESSION CLEANUP PHASE
    UI->>Provider: logout()
    Provider->>Provider: clearSession()
    Provider->>Storage: Delete authToken
    Storage-->>Provider: ✅ Deleted
    Provider->>Provider: clearCache()
    Provider-->>UI: ✅ Logout Complete
    end
    
    rect rgb(240, 250, 220)
    Note over UI,Navigation: NAVIGATION PHASE
    UI->>Navigation: clearStack()
    Navigation-->>UI: ✅ Cleared
    UI->>Navigation: Navigate to Login
    Navigation-->>UI: ✅ Navigated
    UI-->>User: 🔐 Auth Screen
    end
```

---

# 6. BIBLE FEATURES

## 6.1 BIBLE SEARCH & READ

### 6.1.1 Activity Diagram: Bible Navigation & Search

```mermaid
graph TD
    subgraph User3[" 👤 USER "]
        U1([Start])
        U2["📖 Open<br/>Bible Tab"]
        U3{"Action?"}
        U4["🔍 Search"]
        U5["✅ Done"]
    end
    
    subgraph App3[" 📱 APP/FRONTEND "]
        A1["Display<br/>66 Books"]
        A2["Display<br/>Chapters"]
        A3["Display<br/>All Verses"]
        A4["Display<br/>Search Results"]
        A5{"User<br/>Action?"}
    end
    
    subgraph Provider3[" 📋 BIBLE PROVIDER "]
        P1["loadBooks()"]
        P2["loadChapters(book)"]
        P3["loadVerses(book,chapter)"]
        P4["searchVerses(keyword)"]
        P5["addToPlaylist(verse)"]
    end
    
    subgraph DB3[" 💾 SQLITE DB "]
        D1[(Verses Table<br/>~31K Verses)]
    end
    
    U1 --> U2
    U2 --> P1
    P1 --> D1
    D1 --> A1
    A1 --> U3
    U3 -->|Browse| P2
    P2 --> D1
    D1 --> A2
    A2 --> P3
    P3 --> D1
    D1 --> A3
    A3 --> A5
    U3 -->|Search| U4
    U4 --> P4
    P4 --> D1
    D1 --> A4
    A4 --> A5
    A5 -->|Add to Playlist| P5
    A5 -->|Back| U5
    U5 --> U1
    
    style User3 fill:#E3F2FD,stroke:#1976D2
    style App3 fill:#F3E5F5,stroke:#7B1FA2
    style Provider3 fill:#E8F5E9,stroke:#388E3C
    style DB3 fill:#FFF3E0,stroke:#F57C00
```

### 6.1.2 Sequence Diagram: Bible Search & Read

```mermaid
sequenceDiagram
    autonumber
    actor User as 👤 User
    participant UI as 📱 App UI
    participant Provider as 📋 Bible Provider
    participant LocalDB as 💾 SQLite DB
    participant Cache as 📦 Cache
    
    rect rgb(200, 230, 250)
    Note over User,LocalDB: LOAD BOOKS PHASE
    User->>UI: Navigate to Bible Tab
    UI->>Provider: loadBooks()
    Provider->>Cache: Check Books Cache
    alt Cache Miss
        Provider->>LocalDB: SELECT DISTINCT book
        LocalDB-->>Provider: 66 Books
        Provider->>Cache: Store Books
    end
    Provider-->>UI: Books List
    UI-->>User: Display Books
    end
    
    rect rgb(250, 230, 200)
    Note over User,LocalDB: SELECT CHAPTER PHASE
    User->>UI: Select Book (Genesis)
    UI->>Provider: loadChapters(Genesis)
    Provider->>LocalDB: SELECT DISTINCT chapter
    LocalDB-->>Provider: Ch 1-50
    Provider-->>UI: Chapters
    UI-->>User: Display Chapters
    end
    
    rect rgb(230, 250, 230)
    Note over User,LocalDB: LOAD VERSES PHASE
    User->>UI: Select Chapter 1
    UI->>Provider: loadVerses(Genesis, 1)
    Provider->>LocalDB: SELECT * FROM verses
    LocalDB-->>Provider: Verses 1:1-31
    Provider-->>UI: Verse List
    UI-->>User: Display Verses
    end
    
    rect rgb(250, 220, 250)
    Note over User,LocalDB: SEARCH PHASE
    User->>UI: Enter Search Term
    UI->>Provider: searchVerses(keyword)
    Provider->>LocalDB: SELECT * FROM verses LIKE
    LocalDB-->>Provider: Results
    Provider-->>UI: Search Results
    UI-->>User: Display Results
    end
    
    rect rgb(250, 240, 200)
    Note over User,LocalDB: PLAYLIST ACTION
    User->>UI: Select Verse
    UI-->>User: Show Verse + Options
    alt Add to Playlist
        User->>UI: Click Add to Playlist
        UI->>Provider: addToPlaylist(verse_id)
        Provider->>LocalDB: INSERT INTO PLAYLIST_VERSE
        LocalDB-->>Provider: ✅ Success
        Provider-->>UI: Added
        UI-->>User: ✅ Confirmation
    end
    end
```

---

## 6.2 HOME & DASHBOARD NAVIGATION

### 6.2.1 Activity Diagram: Home Dashboard & Navigation

```mermaid
graph TD
    subgraph UserH[" 👤 USER "]
        UH1([Start])
        UH2["🏠 View<br/>Home Page"]
        UH3{"Navigate<br/>To?"}
        UH4["✅ Feature<br/>Loaded"]
    end
    
    subgraph AppH[" 📱 APP/FRONTEND "]
        AH1["Load User Info"]
        AH2["Display Menu<br/>Options"]
        AH3["Show Badges &<br/>Achievements"]
        AH4["Display Shortcuts"]
        AH5["Navigate to<br/>Selected Feature"]
    end
    
    subgraph ProviderH[" 📋 AUTH/BIBLE PROVIDERS "]
        PH1["getUserInfo()"]
        PH2["getQuickStats()"]
        PH3["getBadges()"]
        PH4["getNotifications()"]
    end
    
    subgraph DBH[" 💾 SQLITE DB "]
        DBH1[(User Table)]
        DBH2[(Quest Progress)]
    end
    
    UH1 --> UH2
    UH2 --> PH1
    PH1 --> DBH1
    DBH1 --> AH1
    AH1 --> PH2
    PH2 --> DBH2
    DBH2 --> AH2
    AH2 --> PH3
    PH3 --> AH3
    AH3 --> PH4
    PH4 --> AH4
    AH4 --> UH3
    UH3 -->|Bible| AH5
    UH3 -->|Quest| AH5
    UH3 -->|Profile| AH5
    UH3 -->|Admin| AH5
    AH5 --> UH4
    UH4 --> UH1
    
    style UserH fill:#E3F2FD,stroke:#1976D2
    style AppH fill:#F3E5F5,stroke:#7B1FA2
    style ProviderH fill:#E8F5E9,stroke:#388E3C
    style DBH fill:#FFF3E0,stroke:#F57C00
```

### 6.2.2 Sequence Diagram: Home Dashboard Navigation

```mermaid
sequenceDiagram
    autonumber
    actor User as 👤 User
    participant UI as 📱 App UI
    participant AuthProvider as 👤 Auth Provider
    participant BibleProvider as 📋 Bible Provider
    participant LocalDB as 💾 SQLite DB
    participant Navigator as 🧭 Navigation
    
    rect rgb(200, 230, 250)
    Note over User,LocalDB: LOAD HOME PAGE
    User->>UI: App Launches/Navigate Home
    UI->>AuthProvider: getUserInfo()
    AuthProvider->>LocalDB: SELECT * FROM USER
    LocalDB-->>AuthProvider: User Data
    AuthProvider-->>UI: User Info
    end
    
    rect rgb(220, 230, 250)
    Note over UI,LocalDB: LOAD STATISTICS
    UI->>BibleProvider: getQuickStats()
    BibleProvider->>LocalDB: SELECT FROM QUEST_PROGRESS
    LocalDB-->>BibleProvider: Quest Stats
    BibleProvider-->>UI: Daily Progress
    UI-->>User: Display Welcome + Stats
    end
    
    rect rgb(240, 250, 220)
    Note over UI,LocalDB: LOAD ACHIEVEMENTS
    UI->>AuthProvider: getBadges()
    AuthProvider->>LocalDB: SELECT BADGES
    LocalDB-->>AuthProvider: Badge List
    AuthProvider-->>UI: Badges
    UI-->>User: Display Achievements
    end
    
    rect rgb(250, 240, 230)
    Note over User,Navigator: NAVIGATION
    UI-->>User: Display Menu
    User->>UI: Select Feature
    UI->>Navigator: Navigate(feature)
    Navigator-->>UI: ✅ Navigated
    UI-->>User: Feature Loaded
    end
```

---

# 7. QUEST FEATURES

## 7.1 MARK QUEST COMPLETE

### 7.1.1 Activity Diagram: Quest Completion

```mermaid
graph TD
    subgraph User4[" 👤 USER "]
        U1([Start])
        U2["🎯 Open<br/>Quest Tab"]
        U3{"Check<br/>Status"}
        U4["Mark<br/>Complete"]
        U5["✅ Success"]
    end
    
    subgraph App4[" 📱 APP/FRONTEND "]
        A1["Display Quest<br/>Day X/365"]
        A2{"Today<br/>Done?"}
        A3["ℹ️ Already<br/>Completed"]
        A4["Show Mark<br/>Button"]
        A5["🔔 Celebration"]
        A6["🔄 Refresh UI"]
    end
    
    subgraph Provider4[" 🎯 QUEST PROVIDER "]
        P1["loadQuestData()"]
        P2["checkTodayCompleted()"]
        P3["calculateUpdates()"]
        P4["updateProgress()"]
    end
    
    subgraph DB4[" 💾 SQLITE DB "]
        D1[(Quest Progress<br/>day, streak, date)]
    end
    
    U1 --> U2
    U2 --> P1
    P1 --> D1
    D1 --> A1
    A1 --> P2
    P2 -->|Yes| A3
    A3 --> U1
    P2 -->|No| A4
    A4 --> U3
    U3 -->|No| U1
    U3 -->|Yes| U4
    U4 --> P3
    P3 --> P4
    P4 --> D1
    D1 --> A5
    A5 --> A6
    A6 --> U5
    U5 --> U1
    
    style User4 fill:#E3F2FD,stroke:#1976D2
    style App4 fill:#F3E5F5,stroke:#7B1FA2
    style Provider4 fill:#E8F5E9,stroke:#388E3C
    style DB4 fill:#FFF3E0,stroke:#F57C00
```

### 7.1.2 Sequence Diagram: Mark Quest Complete

```mermaid
sequenceDiagram
    autonumber
    actor User as 👤 User
    participant UI as 📱 App UI
    participant Provider as 🎯 Quest Provider
    participant Calculator as 🧮 Calculator
    participant LocalDB as 💾 SQLite DB
    participant Notif as 🔔 Notif Service
    
    rect rgb(220, 250, 250)
    Note over User,LocalDB: LOAD QUEST STATUS PHASE
    User->>UI: Open Quest Tab
    UI->>Provider: loadQuestData(user_id)
    Provider->>LocalDB: SELECT * FROM QUEST_PROGRESS
    LocalDB-->>Provider: Quest Record
    Provider-->>UI: Quest Data
    UI-->>User: Display Day 45/365 | Streak 3
    end
    
    rect rgb(250, 240, 220)
    Note over UI,Provider: CHECK TODAY STATUS PHASE
    UI->>Provider: checkTodayCompleted()
    Provider->>Calculator: isTodayCompleted(last_date)
    alt Today Already Done
        Calculator-->>Provider: ✅ Yes
        Provider-->>UI: Already Completed
        UI-->>User: ℹ️ Already Done Today
    else Not Done Yet
        Calculator-->>Provider: ❌ No
        Provider-->>UI: Can Mark Complete
        UI-->>User: Show Mark Button
    end
    end
    
    rect rgb(240, 250, 220)
    Note over User,LocalDB: MARK COMPLETE PHASE
    User->>UI: Click Mark Complete
    UI->>Calculator: Calculate Updates
    Calculator-->>UI: new_day=46, new_streak=4
    UI->>Provider: updateQuestProgress(values)
    Provider->>LocalDB: BEGIN TRANSACTION
    Provider->>LocalDB: UPDATE QUEST_PROGRESS
    LocalDB-->>Provider: ✅ Updated
    Provider->>LocalDB: COMMIT
    LocalDB-->>Provider: ✅ Committed
    end
    
    rect rgb(250, 230, 250)
    Note over UI,Notif: NOTIFICATION & REFRESH
    Provider-->>UI: Success
    UI->>Notif: showNotification(+1 Day!)
    Notif-->>UI: ✅ Displayed
    UI-->>User: ✅ Day 46/365 | Streak: 4
    end
```

---

## 7.2 VIEW QUEST PROGRESS

### 7.2.1 Activity Diagram: View Quest & Progress

```mermaid
graph TD
    subgraph UserQV[" 👤 USER "]
        UQV1([Start])
        UQV2["🎯 Open<br/>Quest Tab"]
        UQV3{"Action?"}
        UQV4["View Stats"]
        UQV5["✅ Done"]
    end
    
    subgraph AppQV[" 📱 APP/FRONTEND "]
        AQV1["Load Quest Data"]
        AQV2["Display Day X/365"]
        AQV3["Show Streak Count"]
        AQV4["Display Progress Bar"]
        AQV5["Show Statistics"]
    end
    
    subgraph ProviderQV[" 🎯 QUEST PROVIDER "]
        PQV1["loadQuestData()"]
        PQV2["calculateProgress()"]
        PQV3["getStreakStats()"]
        PQV4["getDailyVerse()"]
    end
    
    subgraph DBQV[" 💾 SQLITE DB "]
        DBQV1[(Quest Progress)]
        DBQV2[(Bible Verses)]
    end
    
    UQV1 --> UQV2
    UQV2 --> PQV1
    PQV1 --> DBQV1
    DBQV1 --> AQV1
    AQV1 --> PQV2
    PQV2 --> AQV2
    AQV2 --> PQV3
    PQV3 --> AQV3
    AQV3 --> PQV4
    PQV4 --> DBQV2
    DBQV2 --> AQV4
    AQV4 --> AQV5
    AQV5 --> UQV3
    UQV3 -->|View| UQV4
    UQV4 --> UQV5
    UQV5 --> UQV1
    
    style UserQV fill:#E3F2FD,stroke:#1976D2
    style AppQV fill:#F3E5F5,stroke:#7B1FA2
    style ProviderQV fill:#E8F5E9,stroke:#388E3C
    style DBQV fill:#FFF3E0,stroke:#F57C00
```

### 7.2.2 Sequence Diagram: View Quest & Progress

```mermaid
sequenceDiagram
    autonumber
    actor User as 👤 User
    participant UI as 📱 App UI
    participant Provider as 🎯 Quest Provider
    participant Calculator as 🧮 Calculator
    participant LocalDB as 💾 SQLite DB
    
    rect rgb(200, 230, 250)
    Note over User,LocalDB: LOAD QUEST DATA
    User->>UI: Navigate to Quest
    UI->>Provider: loadQuestData(user_id)
    Provider->>LocalDB: SELECT * FROM QUEST_PROGRESS
    LocalDB-->>Provider: Quest Record
    Provider-->>UI: Quest Data
    end
    
    rect rgb(220, 230, 250)
    Note over UI,Calculator: CALCULATE STATISTICS
    UI->>Calculator: calculateProgress()
    Calculator-->>UI: progress = 46/365 = 12.6%
    UI->>Calculator: getStreakStats()
    Calculator-->>UI: current_streak=4, max_streak=10
    end
    
    rect rgb(240, 250, 220)
    Note over UI,LocalDB: GET DAILY VERSE
    UI->>Provider: getDailyVerse()
    Provider->>LocalDB: SELECT VERSE FOR TODAY
    LocalDB-->>Provider: Verse Data
    Provider-->>UI: Today's Verse
    end
    
    rect rgb(250, 240, 230)
    Note over UI,User: DISPLAY UI
    UI-->>User: Show Day 46/365
    UI-->>User: Show Streak: 4 days
    UI-->>User: Show Progress Bar
    UI-->>User: Show Daily Verse
    end
```

---

# 8. DEVOTIONAL FEATURES

## 8.1 DEVOTIONAL MANAGEMENT

### 8.1.1 Activity Diagram: Devotional Management

```mermaid
graph TD
    subgraph User5[" 👤 USER "]
        U1([Start])
        U2["🙏 Open<br/>Devotional"]
        U3{"Action?"}
        U4["✅ Done"]
    end
    
    subgraph App5[" 📱 APP/FRONTEND "]
        A1["Display<br/>All Devotionals"]
        A2["Show<br/>Devotional Details"]
        A3["Create Form<br/>for New Dev"]
        A4["Display<br/>Verse Selection"]
        A5{"User<br/>Action?"}
    end
    
    subgraph Service5[" 🙏 DEVOTIONAL SERVICE "]
        S1["loadDevotionals()"]
        S2["createDevotional(data)"]
        S3["addVerse(dev,verse)"]
        S4["publishDevotional(id)"]
        S5["shareDevotional(id)"]
    end
    
    subgraph DB5[" 💾 SQLITE DB "]
        D1[(Devotional Table)]
        D2[(Devotional Verse Table)]
    end
    
    U1 --> U2
    U2 --> S1
    S1 --> D1
    D1 --> A1
    A1 --> U3
    U3 -->|View| A2
    U3 -->|Create| A3
    A3 --> A4
    A4 --> S2
    S2 --> D1
    D1 --> S3
    S3 --> D2
    D2 --> S4
    S4 --> A5
    A5 -->|Publish| S4
    A5 -->|Share| S5
    A5 -->|Back| U4
    U4 --> U1
    
    style User5 fill:#E3F2FD,stroke:#1976D2
    style App5 fill:#F3E5F5,stroke:#7B1FA2
    style Service5 fill:#E8F5E9,stroke:#388E3C
    style DB5 fill:#FFF3E0,stroke:#F57C00
```

### 8.1.2 Sequence Diagram: Create & Publish Devotional

```mermaid
sequenceDiagram
    autonumber
    actor User as 👤 User
    participant UI as 📱 App UI
    participant Service as 🙏 Devotional Service
    participant Validator as ✓ Validator
    participant LocalDB as 💾 SQLite DB
    
    rect rgb(200, 230, 250)
    Note over User,LocalDB: INPUT & VALIDATION PHASE
    User->>UI: Click Create New Devotional
    UI-->>User: Show Creation Form
    User->>UI: Enter Title & Content
    UI->>Validator: Validate Input
    alt Validation Failed
        Validator-->>UI: ❌ Errors
        UI-->>User: Show Errors
    else Validation Passed
        Validator-->>UI: ✅ Valid
    end
    end
    
    rect rgb(220, 230, 250)
    Note over UI,LocalDB: CREATE PHASE
    User->>UI: Select Verses to Add
    UI->>Service: createDevotional(title, content)
    Service->>LocalDB: BEGIN TRANSACTION
    Service->>LocalDB: INSERT INTO DEVOTIONAL
    LocalDB-->>Service: devotional_id
    end
    
    rect rgb(230, 250, 220)
    Note over UI,LocalDB: ADD VERSES PHASE
    User->>UI: Add Multiple Verses
    UI->>Service: addVerse(dev_id, verse_id)
    Service->>LocalDB: INSERT INTO DEVOTIONAL_VERSE
    LocalDB-->>Service: ✅ Verse Added
    end
    
    rect rgb(250, 240, 220)
    Note over User,LocalDB: PUBLISH PHASE
    User->>UI: Click Publish
    UI->>Service: publishDevotional(dev_id)
    Service->>LocalDB: UPDATE DEVOTIONAL
    LocalDB-->>Service: ✅ Published
    Service->>LocalDB: COMMIT
    LocalDB-->>Service: ✅ Committed
    Service-->>UI: Success
    UI-->>User: ✅ Devotional Published
    end
```

---

# 9. PLAYLIST FEATURES

## 9.1 PLAYLIST MANAGEMENT

### 9.1.1 Activity Diagram: Playlist Management

```mermaid
graph TD
    subgraph User6[" 👤 USER "]
        U1([Start])
        U2["📚 Open<br/>Playlist"]
        U3{"Action?"}
        U4["✅ Done"]
    end
    
    subgraph App6[" 📱 APP/FRONTEND "]
        A1["Display<br/>My Playlists"]
        A2["Show<br/>Playlist Details"]
        A3["Create<br/>Form"]
        A4["Show Verses<br/>in Playlist"]
        A5{"Edit<br/>Action?"}
    end
    
    subgraph Service6[" 📚 PLAYLIST SERVICE "]
        S1["loadPlaylists()"]
        S2["createPlaylist(name)"]
        S3["addVerse(playlist,verse)"]
        S4["reorderVerse(from,to)"]
        S5["deleteVerse(id)"]
        S6["deletePlaylist(id)"]
    end
    
    subgraph DB6[" 💾 SQLITE DB "]
        D1[(Playlist Table)]
        D2[(Playlist Verse Table)]
    end
    
    U1 --> U2
    U2 --> S1
    S1 --> D1
    D1 --> A1
    A1 --> U3
    U3 -->|View| A2
    A2 --> A4
    A4 --> A5
    U3 -->|Create| A3
    A3 --> S2
    S2 --> D1
    D1 --> U3
    A5 -->|Add Verse| S3
    S3 --> D2
    A5 -->|Reorder| S4
    S4 --> D2
    A5 -->|Delete Verse| S5
    S5 --> D2
    A5 -->|Delete Playlist| S6
    S6 --> D1
    D2 --> U4
    U4 --> U1
    
    style User6 fill:#E3F2FD,stroke:#1976D2
    style App6 fill:#F3E5F5,stroke:#7B1FA2
    style Service6 fill:#E8F5E9,stroke:#388E3C
    style DB6 fill:#FFF3E0,stroke:#F57C00
```

### 9.1.2 Sequence Diagram: Create & Manage Playlist

```mermaid
sequenceDiagram
    autonumber
    actor User as 👤 User
    participant UI as 📱 App UI
    participant Service as 📚 Playlist Service
    participant Validator as ✓ Validator
    participant LocalDB as 💾 SQLite DB
    
    rect rgb(200, 230, 250)
    Note over User,LocalDB: CREATE PHASE
    User->>UI: Click Create Playlist
    UI-->>User: Show Input Form
    User->>UI: Enter Playlist Name
    UI->>Validator: Validate Name
    alt Invalid
        Validator-->>UI: ❌ Error
        UI-->>User: Show Error
    else Valid
        Validator-->>UI: ✅ Valid
        UI->>Service: createPlaylist(name)
        Service->>LocalDB: BEGIN TRANSACTION
        Service->>LocalDB: INSERT INTO PLAYLIST
        LocalDB-->>Service: playlist_id
        Service->>LocalDB: COMMIT
        LocalDB-->>Service: ✅ Created
    end
    end
    
    rect rgb(220, 230, 250)
    Note over User,LocalDB: ADD VERSES PHASE
    UI-->>User: Show Created Playlist
    User->>UI: Select & Add Verses
    loop Multiple Verses
        UI->>Service: addVerse(playlist_id, verse)
        Service->>LocalDB: INSERT INTO PLAYLIST_VERSE
        LocalDB-->>Service: ✅ Added
    end
    end
    
    rect rgb(250, 240, 220)
    Note over User,LocalDB: REORDER PHASE
    User->>UI: Reorder Verses (Drag)
    UI->>Service: reorderVerse(from_index, to_index)
    Service->>LocalDB: UPDATE PLAYLIST_VERSE
    LocalDB-->>Service: ✅ Reordered
    UI-->>User: ✅ Order Updated
    end
    
    rect rgb(230, 250, 230)
    Note over User,LocalDB: DELETE VERSE PHASE
    User->>UI: Delete Single Verse
    UI->>Service: deleteVerse(playlist_verse_id)
    Service->>LocalDB: DELETE FROM PLAYLIST_VERSE
    LocalDB-->>Service: ✅ Deleted
    UI-->>User: ✅ Removed
    end
```

---

# 10. PROFILE FEATURES

## 10.1 PROFILE MANAGEMENT

### 10.1.1 Activity Diagram: Profile Management

```mermaid
graph TD
    subgraph User7[" 👤 USER "]
        U1([Start])
        U2["👤 Open<br/>Profile"]
        U3{"Action?"}
        U4["✅ Updated"]
    end
    
    subgraph App7[" 📱 APP/FRONTEND "]
        A1["Display<br/>User Info"]
        A2["Edit Form<br/>for Fields"]
        A3{"Validate<br/>Input?"}
        A4["Error<br/>Message"]
        A5["✅ Success<br/>Message"]
    end
    
    subgraph Provider7[" 👤 AUTH PROVIDER "]
        P1["loadUserProfile()"]
        P2["updateProfile(data)"]
        P3["validateInputs()"]
    end
    
    subgraph DB7[" 💾 SQLITE DB "]
        D1[(User Table)]
    end
    
    U1 --> U2
    U2 --> P1
    P1 --> D1
    D1 --> A1
    A1 --> U3
    U3 -->|View| U1
    U3 -->|Edit| A2
    A2 --> P3
    P3 --> A3
    A3 -->|No| A4
    A4 --> A2
    A3 -->|Yes| P2
    P2 --> D1
    D1 --> A5
    A5 --> U4
    U4 --> U1
    
    style User7 fill:#E3F2FD,stroke:#1976D2
    style App7 fill:#F3E5F5,stroke:#7B1FA2
    style Provider7 fill:#E8F5E9,stroke:#388E3C
    style DB7 fill:#FFF3E0,stroke:#F57C00
```

### 10.1.2 Sequence Diagram: Update Profile

```mermaid
sequenceDiagram
    autonumber
    actor User as 👤 User
    participant UI as 📱 App UI
    participant Provider as 👤 Auth Provider
    participant Validator as ✓ Validator
    participant LocalDB as 💾 SQLite DB
    
    rect rgb(200, 230, 250)
    Note over User,LocalDB: LOAD PROFILE PHASE
    User->>UI: Navigate to Profile
    UI->>Provider: loadUserProfile()
    Provider->>LocalDB: SELECT * FROM USER
    LocalDB-->>Provider: User Data
    Provider-->>UI: Profile Data
    UI-->>User: Display Profile
    end
    
    rect rgb(220, 230, 250)
    Note over User,LocalDB: EDIT PHASE
    User->>UI: Click Edit Profile
    UI-->>User: Show Edit Form
    User->>UI: Update Fields
    UI->>Validator: Validate All Fields
    alt Validation Failed
        Validator-->>UI: ❌ Errors
        UI-->>User: Show Errors
    else Validation Passed
        Validator-->>UI: ✅ Valid
    end
    end
    
    rect rgb(240, 250, 220)
    Note over User,LocalDB: UPDATE PHASE
    UI->>Provider: updateProfile(updated_data)
    Provider->>LocalDB: BEGIN TRANSACTION
    Provider->>LocalDB: UPDATE USER
    LocalDB-->>Provider: ✅ Updated
    Provider->>LocalDB: COMMIT
    LocalDB-->>Provider: ✅ Committed
    Provider-->>UI: Success
    UI-->>User: ✅ Profile Updated
    end
```

---

## 10.2 MEMBER CARD GENERATION

### 10.2.1 Activity Diagram: Member Card Generation

```mermaid
graph TD
    subgraph User8[" 👤 USER "]
        U1([Start])
        U2["🎫 Request<br/>Member Card"]
        U3["✅ Card<br/>Generated"]
    end
    
    subgraph App8[" 📱 APP/FRONTEND "]
        A1["Show Request<br/>Button"]
        A2{"Card<br/>Exists?"}
        A3["ℹ️ Show<br/>Existing"]
        A4["Generate New"]
        A5["Display Card<br/>with QR"]
        A6["Option to<br/>Download"]
    end
    
    subgraph Service8[" 🎫 CARD SERVICE "]
        S1["checkExistingCard()"]
        S2["generateCardNumber()"]
        S3["generateQRCode()"]
        S4["createCardRecord()"]
    end
    
    subgraph DB8[" 💾 SQLITE DB "]
        D1[(Member Card Table)]
    end
    
    U1 --> U2
    U2 --> S1
    S1 --> D1
    D1 --> A2
    A2 -->|Yes| A3
    A2 -->|No| S2
    S2 --> S3
    S3 --> S4
    S4 --> D1
    D1 --> A4
    A4 --> A5
    A5 --> A6
    A6 --> U3
    A3 --> U3
    U3 --> U1
    
    style User8 fill:#E3F2FD,stroke:#1976D2
    style App8 fill:#F3E5F5,stroke:#7B1FA2
    style Service8 fill:#E8F5E9,stroke:#388E3C
    style DB8 fill:#FFF3E0,stroke:#F57C00
```

### 10.2.2 Sequence Diagram: Generate Member Card

```mermaid
sequenceDiagram
    autonumber
    actor User as 👤 User
    participant UI as 📱 App UI
    participant Service as 🎫 Card Service
    participant Generator as 🔧 Generator
    participant LocalDB as 💾 SQLite DB
    
    rect rgb(200, 230, 250)
    Note over User,LocalDB: CHECK EXISTING PHASE
    User->>UI: Request Member Card
    UI->>Service: checkExistingCard(user_id)
    Service->>LocalDB: SELECT * FROM MEMBER_CARD
    alt Card Exists
        LocalDB-->>Service: Card Record
        Service-->>UI: Card Exists
        UI-->>User: Display Existing Card
    else No Card
        LocalDB-->>Service: ❌ Not Found
        Service-->>UI: Generate New
    end
    end
    
    rect rgb(220, 230, 250)
    Note over Service,LocalDB: GENERATION PHASE
    Service->>Generator: generateCardNumber()
    Generator-->>Service: Card: MEM-XXXXX
    Service->>Generator: generateQRCode(card_number)
    Generator-->>Service: QR Code Image
    Service->>LocalDB: BEGIN TRANSACTION
    Service->>LocalDB: INSERT INTO MEMBER_CARD
    LocalDB-->>Service: ✅ Record Created
    Service->>LocalDB: COMMIT
    LocalDB-->>Service: ✅ Committed
    end
    
    rect rgb(240, 250, 220)
    Note over Service,UI: DISPLAY & DOWNLOAD PHASE
    Service-->>UI: Card Generated
    UI-->>User: Display Card
    User->>UI: Download/Share Card
    UI-->>User: ✅ Card Ready
    end
```

---

# 11. ATTENDANCE FEATURES

## 11.1 QR SCAN & ATTENDANCE

### 11.1.1 Activity Diagram: QR Scanner & Attendance

```mermaid
graph TD
    subgraph User9[" 📷 USER "]
        U1([Start])
        U2["📷 Open<br/>Scanner"]
        U3["Scan QR<br/>Code"]
        U4{"Valid<br/>Code?"}
        U5["✅ Attendance<br/>Recorded"]
    end
    
    subgraph App9[" 📱 APP/FRONTEND "]
        A1["Show Camera<br/>Stream"]
        A2["Capture<br/>QR"]
        A3["Extract<br/>Data"]
        A4{"QR<br/>Valid?"}
        A5["❌ Error<br/>Message"]
        A6["✅ Success<br/>Message"]
    end
    
    subgraph Service9[" 📷 SCAN SERVICE "]
        S1["initializeCamera()"]
        S2["captureQRCode()"]
        S3["decodeQR()"]
        S4["validateQRCode()"]
        S5["recordAttendance()"]
    end
    
    subgraph DB9[" 💾 SQLITE DB "]
        D1[(Attendance Table)]
    end
    
    U1 --> U2
    U2 --> S1
    S1 --> A1
    A1 --> U3
    U3 --> S2
    S2 --> S3
    S3 --> A3
    A3 --> S4
    S4 --> A4
    A4 -->|No| A5
    A5 --> U1
    A4 -->|Yes| S5
    S5 --> D1
    D1 --> A6
    A6 --> U5
    U5 --> U1
    
    style User9 fill:#E3F2FD,stroke:#1976D2
    style App9 fill:#F3E5F5,stroke:#7B1FA2
    style Service9 fill:#E8F5E9,stroke:#388E3C
    style DB9 fill:#FFF3E0,stroke:#F57C00
```

### 11.1.2 Sequence Diagram: Scan & Record Attendance

```mermaid
sequenceDiagram
    autonumber
    actor User as 📷 User
    participant UI as 📱 App UI
    participant Scanner as 🔍 Scanner Service
    participant Validator as ✓ Validator
    participant LocalDB as 💾 SQLite DB
    participant Notif as 📧 Notification
    
    rect rgb(200, 230, 250)
    Note over User,LocalDB: CAMERA INITIALIZATION
    User->>UI: Click Attendance Tab
    UI->>Scanner: initializeCamera()
    Scanner-->>UI: ✅ Camera Ready
    UI-->>User: Show Live Stream
    end
    
    rect rgb(220, 230, 250)
    Note over User,LocalDB: QR SCANNING PHASE
    User->>UI: Point at QR Code
    UI->>Scanner: captureQRCode()
    Scanner-->>UI: QR Image
    UI->>Scanner: decodeQRCode(image)
    Scanner-->>UI: Decoded Data
    UI->>Validator: validateQRCode(qr_data)
    alt Invalid QR
        Validator-->>UI: ❌ Invalid
        UI-->>User: ❌ Invalid Code
    else Valid QR
        Validator-->>UI: ✅ Valid
        Validator-->>UI: card_number extracted
    end
    end
    
    rect rgb(240, 250, 220)
    Note over User,LocalDB: RECORD ATTENDANCE PHASE
    UI->>Scanner: recordAttendance(card_number)
    Scanner->>LocalDB: BEGIN TRANSACTION
    Scanner->>LocalDB: INSERT INTO ATTENDANCE_RECORD
    LocalDB-->>Scanner: ✅ Recorded
    Scanner->>LocalDB: COMMIT
    LocalDB-->>Scanner: ✅ Committed
    Scanner->>Notif: sendNotification(user_id)
    Notif-->>Scanner: ✅ Sent
    Scanner-->>UI: Success
    UI-->>User: ✅ Attendance Recorded
    end
```

---

# 12. ADMIN FEATURES

## 12.1 USER VERIFICATION

### 12.1.1 Activity Diagram: User Verification Process

```mermaid
graph TD
    subgraph Admin[" 👨‍💼 ADMIN "]
        A1([Start])
        A2["Login as<br/>Admin"]
        A3["Select<br/>User"]
        A4["Review<br/>Documents"]
        A5{"Decision"}
        A6["✅ Approved"]
        A7["❌ Rejected"]
    end
    
    subgraph AppAdmin[" 📱 ADMIN PANEL "]
        AA1["Display Pending<br/>Users List"]
        AA2["Show User<br/>Details & Docs"]
        AA3{"Approve or<br/>Reject?"}
        AA4["Approval<br/>Action"]
        AA5["Rejection<br/>Action"]
        AA6["Refresh<br/>List"]
    end
    
    subgraph ServiceAdmin[" 🔑 ADMIN SERVICE "]
        SA1["verifyAdminRole()"]
        SA2["loadPendingUsers()"]
        SA3["approveUser(userId)"]
        SA4["generateCardNumber()"]
        SA5["rejectUser(userId)"]
        SA6["sendNotification()"]
    end
    
    subgraph DBAdmin[" 💾 DATABASE "]
        DA1[(Users Table<br/>pending→approved)]
        DA2[(Member Card Table)]
    end
    
    A1 --> A2
    A2 --> SA1
    SA1 --> AA1
    AA1 --> A3
    A3 --> AA2
    AA2 --> A4
    A4 --> A5
    A5 -->|Approve| SA3
    SA3 --> SA4
    SA4 --> DA2
    DA2 --> AA4
    AA4 --> SA6
    SA6 --> AA6
    A5 -->|Reject| SA5
    SA5 --> DA1
    DA1 --> SA6
    SA6 --> AA6
    AA6 --> AA1
    AA1 --> A5
    A5 -->|Done| A6
    A5 -->|Done| A7
    A6 --> A1
    A7 --> A1
    
    style Admin fill:#E3F2FD,stroke:#1976D2
    style AppAdmin fill:#F3E5F5,stroke:#7B1FA2
    style ServiceAdmin fill:#E8F5E9,stroke:#388E3C
    style DBAdmin fill:#FFF3E0,stroke:#F57C00
```

### 12.1.2 Sequence Diagram: Admin Verification Process

```mermaid
sequenceDiagram
    autonumber
    actor Admin as 👨‍💼 Admin
    participant UI as 📱 Admin Panel
    participant Service as 🔑 Admin Service
    participant Authenticator as ✓ Authenticator
    participant LocalDB as 💾 SQLite DB
    participant CardGen as 🎫 Card Generator
    participant Notif as 📧 Notification
    
    rect rgb(230, 240, 250)
    Note over Admin,LocalDB: ADMIN AUTHENTICATION PHASE
    Admin->>UI: Enter Admin Credentials
    UI->>Service: verifyAdminRole(email, password)
    Service->>Authenticator: authenticate(email, password)
    Authenticator->>LocalDB: SELECT * FROM USER<br/>WHERE email=? AND role='admin'
    alt Not Admin
        LocalDB-->>Authenticator: ❌ Not Found
        Authenticator-->>Service: ❌ Denied
        Service-->>UI: ❌ Access Denied
    else Is Admin
        LocalDB-->>Authenticator: ✅ Found
        Authenticator-->>Service: ✅ Verified
        Service-->>UI: ✅ Access Granted
    end
    end
    
    rect rgb(240, 230, 250)
    Note over Admin,LocalDB: LOAD PENDING USERS PHASE
    UI-->>Admin: Show Admin Panel
    Admin->>UI: View Pending Users
    UI->>Service: fetchPendingUsers()
    Service->>LocalDB: SELECT * FROM USER<br/>WHERE status='pending'
    LocalDB-->>Service: Pending Users List
    Service-->>UI: Users Data
    UI-->>Admin: Display Users Table
    end
    
    rect rgb(250, 250, 220)
    Note over Admin,LocalDB: USER REVIEW PHASE
    Admin->>UI: Select User (John Doe)
    UI-->>Admin: Show Details & Documents
    Admin->>Admin: Review ID & Info
    end
    
    rect rgb(220, 250, 220)
    Note over Admin,LocalDB: APPROVAL DECISION PHASE
    alt Reject User
        Admin->>UI: Click Reject
        UI->>Service: rejectUser(user_id)
        Service->>LocalDB: UPDATE USER SET status='rejected'
        LocalDB-->>Service: ✅ Updated
        Service->>Notif: sendNotification(rejected)
    else Approve User
        Admin->>UI: Click Approve
        UI->>Service: approveUser(user_id)
        Service->>LocalDB: BEGIN TRANSACTION
        Service->>LocalDB: UPDATE USER SET status='approved'
        LocalDB-->>Service: ✅ Updated
        Service->>CardGen: generateCardNumber()
        CardGen-->>Service: Card: MEM-XXXXX
        Service->>LocalDB: INSERT INTO MEMBER_CARD
        LocalDB-->>Service: ✅ Card Created
        Service->>LocalDB: COMMIT
        LocalDB-->>Service: ✅ Committed
        Service->>Notif: sendNotification(approved)
    end
    end
    
    rect rgb(250, 240, 230)
    Note over Service,Notif: NOTIFICATION & REFRESH PHASE
    Notif-->>Service: ✅ Sent
    Service-->>UI: Success
    UI-->>Admin: Show Success Message
    UI->>Service: refreshPendingList()
    Service->>LocalDB: SELECT * FROM USER<br/>WHERE status='pending'
    LocalDB-->>Service: Updated List
    Service-->>UI: New List
    UI-->>Admin: Update Display
    end
```

---

## 12.2 ADMIN REPORTS

### 12.2.1 Activity Diagram: View Admin Reports

```mermaid
graph TD
    subgraph AdminR[" 👨‍💼 ADMIN "]
        AR1([Start])
        AR2["📊 Open<br/>Reports"]
        AR3{"Report<br/>Type?"}
        AR4["✅ Report<br/>Generated"]
    end
    
    subgraph AppR[" 📱 ADMIN PANEL "]
        AAR1["Load Report<br/>Options"]
        AAR2["Select<br/>Date Range"]
        AAR3["Generate<br/>Report"]
        AAR4["Display<br/>Statistics"]
        AAR5["Export<br/>Option"]
    end
    
    subgraph ServiceR[" 📊 REPORT SERVICE "]
        SR1["getUserStats()"]
        SR2["getAttendanceStats()"]
        SR3["getVerificationStats()"]
        SR4["calculateMetrics()"]
        SR5["generatePDF()"]
    end
    
    subgraph DBR[" 💾 DATABASE "]
        DBR1[(Attendance Table)]
        DBR2[(User Table)]
        DBR3[(Quest Progress)]
    end
    
    AR1 --> AR2
    AR2 --> AAR1
    AAR1 --> AR3
    AR3 -->|Users| SR1
    AR3 -->|Attendance| SR2
    AR3 -->|Verification| SR3
    SR1 --> DBR2
    SR2 --> DBR1
    SR3 --> DBR2
    DBR2 --> AAR2
    DBR1 --> AAR2
    AAR2 --> SR4
    SR4 --> AAR3
    AAR3 --> AAR4
    AAR4 --> AAR5
    AAR5 --> AR3
    AR3 -->|Export| SR5
    SR5 --> AR4
    AR4 --> AR1
    
    style AdminR fill:#E3F2FD,stroke:#1976D2
    style AppR fill:#F3E5F5,stroke:#7B1FA2
    style ServiceR fill:#E8F5E9,stroke:#388E3C
    style DBR fill:#FFF3E0,stroke:#F57C00
```

### 12.2.2 Sequence Diagram: Generate Admin Report

```mermaid
sequenceDiagram
    autonumber
    actor Admin as 👨‍💼 Admin
    participant UI as 📱 Admin Panel
    participant Service as 📊 Report Service
    participant Calculator as 🧮 Calculator
    participant LocalDB as 💾 SQLite DB
    participant PDFGen as 📄 PDF Generator
    
    rect rgb(200, 230, 250)
    Note over Admin,LocalDB: REPORT SELECTION
    Admin->>UI: Click Reports
    UI-->>Admin: Show Report Options
    Admin->>UI: Select Report Type & Date
    UI->>Service: generateReport(type, date_range)
    end
    
    rect rgb(220, 230, 250)
    Note over Service,LocalDB: GATHER DATA
    alt User Statistics
        Service->>LocalDB: SELECT COUNT(*) FROM USER
        LocalDB-->>Service: Total Users
        Service->>LocalDB: SELECT * WHERE status='approved'
        LocalDB-->>Service: Approved Users
    else Attendance Statistics
        Service->>LocalDB: SELECT * FROM ATTENDANCE_RECORD
        LocalDB-->>Service: All Records
    else Verification Statistics
        Service->>LocalDB: SELECT status, COUNT(*) FROM USER
        LocalDB-->>Service: Status Breakdown
    end
    end
    
    rect rgb(240, 250, 220)
    Note over Service,Calculator: CALCULATE METRICS
    Service->>Calculator: calculateMetrics(data)
    Calculator-->>Service: Percentages, Averages
    Service->>Calculator: generateCharts(data)
    Calculator-->>Service: Chart Data
    Service-->>UI: Report Data
    end
    
    rect rgb(250, 240, 230)
    Note over UI,PDFGen: DISPLAY & EXPORT
    UI-->>Admin: Display Report
    Admin->>UI: Download Report
    UI->>PDFGen: generatePDF(report_data)
    PDFGen-->>UI: PDF File
    UI-->>Admin: ✅ Report Downloaded
    end
```

---

# END OF DIAGRAMS

**Total Diagrams: 36**
- Main System Diagrams: 4 (Flowchart, UseCase, Class, ERD) - Setiap satu menjelaskan keseluruhan sistem
- Feature-Specific Diagrams: 32 (16 features × 2 diagrams each)

**Format Standards:**
- Main System: 1 comprehensive architecture diagram (integrates Flowchart, UseCase, Class, ERD)
- Activity Diagrams: Swimlane format (4 actors/layers)
- Sequence Diagrams: UML template format with autonumber, phases
- All diagrams follow professional thesis standards

**Ready for thesis submission!** ✅
