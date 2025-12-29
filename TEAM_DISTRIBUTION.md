# 🇳🇵 Connect Well Nepal - Team Work Distribution

**Project Type:** Telehealth Application (Similar to Timely Care)  
**Team Size:** 4 Members  
**Timeline:** Semester Project  
**Tech Stack:** Flutter, Firebase (future), Material Design 3, Provider (State Management)

---

## 📱 Current Application Features

### ✅ **Implemented Features:**

#### **Core App Structure**
- ✅ Splash Screen with animated branding
- ✅ Material Design 3 theming with **Dark Mode support**
- ✅ Bottom navigation (4 tabs - role-based labels)
- ✅ Clean architecture with proper folder structure
- ✅ Provider state management setup

#### **Authentication & User Management**
- ✅ **Login Screen** with email/password
- ✅ **Signup Screen** with role selection (Patient/Doctor/Care Provider)
- ✅ **Google Sign-In** integration
- ✅ **Email Verification** with 6-digit OTP code
- ✅ **Doctor Registration** screen (specialty, license, qualification)
- ✅ Guest mode access
- ✅ User model with role-based fields
- ✅ Logout functionality

#### **Patient Features**
- ✅ Home Screen with personalized greeting
- ✅ Profile avatar with initials
- ✅ **Self-Care Hub** button with bottom sheet options
- ✅ Quick Self-Care cards (4 options: Meditation, Exercise, Nutrition, Mental Health)
- ✅ Available Doctors section with ratings
- ✅ **Nearby Healthcare** section (combined clinics & hospitals with distance & ratings)
- ✅ Location service integration (Google Places API ready)
- ✅ Profile management with medical history

#### **Doctor/Care Provider Features**
- ✅ **Doctor Dashboard** (separate home screen)
- ✅ Verification status banner
- ✅ Quick stats (appointments, requests, patients)
- ✅ Today's schedule with appointment cards
- ✅ Patient request cards (accept/decline)
- ✅ Quick actions (Schedule, Video Consultation, Prescription)
- ✅ Earnings summary card
- ✅ Professional profile with credentials display
- ✅ Role-specific bottom navigation labels

#### **Settings & Preferences**
- ✅ **Dark Mode toggle**
- ✅ Push notification toggle
- ✅ Reminder time picker
- ✅ Language selection (English/Nepali)
- ✅ Privacy & Security options
- ✅ About section
- ✅ Help & Support

#### **Screens (Skeleton/Basic)**
- ✅ Appointments Screen (skeleton)
- ✅ Consultation types Screen (Video/Voice/Chat options)
- ✅ Health Resources Screen (skeleton)

---

## 👥 Team Member Assignments

### 🔵 **TEAM MEMBER 1: Appointments & Booking System**
**Focus Area:** `lib/screens/appointments_screen.dart`

**Primary Tasks:**
1. **Appointment Booking Flow** (Week 1-2)
   - Create `booking_screen.dart` with date/time picker
   - Add doctor selection interface
   - Implement appointment reason/symptoms form
   - Add confirmation screen

2. **Appointment Management** (Week 3-4)
   - Display upcoming appointments list
   - Display past appointments with details
   - Add cancel/reschedule functionality
   - Implement appointment notifications (local notifications)

3. **Doctor Profile Screen** (Week 5)
   - Create `doctor_profile_screen.dart`
   - Show doctor details (specialization, experience, rating)
   - Show available time slots
   - Add reviews/ratings display

**Files to Create:**
- `lib/screens/booking_screen.dart`
- `lib/screens/doctor_profile_screen.dart`
- `lib/models/appointment_model.dart`
- `lib/models/doctor_model.dart`
- `lib/widgets/appointment_card.dart`
- `lib/widgets/time_slot_selector.dart`

**Packages to Add:**
```yaml
table_calendar: ^3.0.9  # For calendar view
flutter_local_notifications: ^17.0.0  # For appointment reminders
```

**Integration Points:**
- Connect with Team Member 4 for Firebase database
- Work with Team Member 2 for consultation flow
- Use existing `PlaceModel` for clinic integration

---

### 🔴 **TEAM MEMBER 2: Video/Voice Consultation**
**Focus Area:** `lib/screens/consultation_screen.dart`

**Primary Tasks:**
1. **Video Call Integration** (Week 1-3)
   - Research and integrate video SDK (Agora/Jitsi/100ms)
   - Create `video_call_screen.dart`
   - Implement video controls (mute, video on/off, flip camera)
   - Add in-call UI (timer, participant info)

2. **Voice Call Integration** (Week 3-4)
   - Create `voice_call_screen.dart`
   - Add audio-only controls
   - Implement call quality indicators

3. **Chat Consultation** (Week 4-5)
   - Create `chat_screen.dart`
   - Implement real-time messaging UI
   - Add message types (text, image, file)
   - Add typing indicators

4. **Call History & Recordings** (Week 6)
   - Add consultation history
   - Store call metadata
   - Add prescription sharing post-call

**Files to Create:**
- `lib/screens/video_call_screen.dart`
- `lib/screens/voice_call_screen.dart`
- `lib/screens/chat_screen.dart`
- `lib/models/message_model.dart`
- `lib/services/video_call_service.dart`
- `lib/widgets/message_bubble.dart`

**Packages to Add:**
```yaml
agora_rtc_engine: ^6.3.0  # Video/Voice calling
# OR
jitsi_meet_flutter_sdk: ^9.0.0  # Alternative
image_picker: ^1.0.7  # For sending images in chat
file_picker: ^8.0.0  # For sending files
```

**Integration Points:**
- Connect with Team Member 1 for appointment-to-call flow
- Work with Team Member 4 for Firebase Realtime Database (chat)
- Integrate with Doctor Dashboard "Start Video Consultation" button

---

### 🟢 **TEAM MEMBER 3: Health Resources & Content**
**Focus Area:** `lib/screens/resources_screen.dart`

**Primary Tasks:**
1. **Content Management** (Week 1-2)
   - Design article detail page `article_detail_screen.dart`
   - Create category pages for each health topic
   - Add search functionality
   - Implement bookmarking/favorites

2. **Mental Health & Self-Care** (Week 3-4)
   - Enhance existing Self-Care Hub with detailed content
   - Create mental wellness section
   - Add mood tracker widget
   - Implement self-assessment tools
   - Expand meditation/breathing exercises (4-7-8 technique exists)

3. **COVID-19 & Emergency Info** (Week 4-5)
   - Create COVID info dashboard
   - Add symptom checker
   - Emergency contacts quick dial
   - Vaccination tracking

4. **Video Content** (Week 5-6)
   - Add health education videos
   - Create video player screen
   - Add video categories
   - Implement video progress tracking

**Files to Create:**
- `lib/screens/article_detail_screen.dart`
- `lib/screens/category_screen.dart`
- `lib/screens/mood_tracker_screen.dart`
- `lib/screens/video_player_screen.dart`
- `lib/models/article_model.dart`
- `lib/models/video_model.dart`
- `lib/widgets/article_card.dart`
- `lib/widgets/mood_selector.dart`

**Packages to Add:**
```yaml
youtube_player_flutter: ^9.0.0  # For video playback
webview_flutter: ^4.7.0  # For web content
share_plus: ^7.2.2  # For sharing articles
url_launcher: ^6.2.5  # For opening external links
```

**Integration Points:**
- Work with Team Member 4 for Firebase Storage (videos/images)
- Coordinate with existing Self-Care bottom sheet options
- Use existing dark mode support

---

### 🟡 **TEAM MEMBER 4: Backend, Authentication & Profile** ✅ COMPLETE
**Focus Area:** `lib/services/` and `lib/screens/profile_screen.dart`

**✅ FULLY COMPLETE - All Services Created:**

**What's Already Done:**
- ✅ User model with roles (patient/doctor/careProvider/guest)
- ✅ App Provider with auth state management
- ✅ Login/Signup screens with role selection
- ✅ Google Sign-In integration (needs Firebase config)
- ✅ Email verification flow (needs real email service)
- ✅ Profile screen with role-based fields
- ✅ Settings screen with preferences
- ✅ **All Firebase service files created**
- ✅ **Form validators created**
- ✅ **Firebase packages added to pubspec.yaml**

**✅ Completed Tasks:**

1. **✅ Firebase Packages Added**
   - `firebase_core: ^3.8.0`
   - `firebase_auth: ^5.3.3`
   - `cloud_firestore: ^5.5.0`
   - `firebase_storage: ^12.3.6`
   - `firebase_messaging: ^15.1.6`
   - `shared_preferences: ^2.3.3`

2. **✅ Auth Service Created** (`lib/services/auth_service.dart`)
   - Email/password sign up and sign in
   - Google Sign-In with role selection
   - Phone OTP verification
   - Password reset
   - Email verification
   - Session management
   - User-friendly error messages

3. **✅ Database Service Created** (`lib/services/database_service.dart`)
   - User CRUD operations
   - Doctor verification queries
   - Appointment management
   - Consultation history
   - Review/rating system
   - Doctor search functionality

4. **✅ Storage Service Created** (`lib/services/storage_service.dart`)
   - Profile image upload with progress
   - Medical document upload
   - Prescription upload
   - Chat attachment upload
   - File deletion
   - Content type detection

5. **✅ Notification Service Created** (`lib/services/notification_service.dart`)
   - FCM initialization
   - Push notification permissions
   - Topic subscriptions (patients, doctors, health tips, emergency)
   - Token management
   - Foreground/background message handling
   - Notification tap handling

6. **✅ Validators Created** (`lib/utils/validators.dart`)
   - Email validation
   - Password validation (basic and strong)
   - Nepal phone number validation with formatting
   - Name and full name validation
   - Medical license number validation (NMC format)
   - Age, experience, date validation
   - URL validation
   - General required/min/max length validators

**Remaining Setup (Requires Firebase Console):**
- ⏳ Create Firebase project at console.firebase.google.com
- ⏳ Download `google-services.json` (Android)
- ⏳ Download `GoogleService-Info.plist` (iOS)
- ⏳ Add SHA-1 key for Google Sign-In
- ⏳ Enable Authentication providers in Firebase Console
- ⏳ Set up Firestore security rules

**Files Created:**
- ✅ `lib/services/auth_service.dart`
- ✅ `lib/services/database_service.dart`
- ✅ `lib/services/storage_service.dart`
- ✅ `lib/services/notification_service.dart`
- ✅ `lib/utils/validators.dart`

**Integration Points:**
- Ready to support ALL team members with backend integration
- Services follow singleton pattern for easy access
- Comprehensive error handling included
- Real-time listeners available for Firestore data

---

## 📋 Shared Responsibilities

### **All Team Members:**
- Follow existing code style and comments
- Use existing `AppColors` from `lib/utils/colors.dart`
- Support both light and dark themes
- Test your features thoroughly
- Use Git branches for development
- Regular code reviews
- Update documentation

### **Weekly Meetings:**
- **Monday:** Sprint planning & task review
- **Wednesday:** Progress check-in
- **Friday:** Code review & integration

---

## 🗂️ Current Folder Structure

```
lib/
├── main.dart ✅
├── models/
│   ├── clinic_model.dart ✅
│   ├── place_model.dart ✅ (for nearby clinics/hospitals)
│   ├── user_model.dart ✅ (with roles: patient/doctor/careProvider)
│   ├── appointment_model.dart [Member 1]
│   ├── doctor_model.dart [Member 1]
│   ├── message_model.dart [Member 2]
│   ├── article_model.dart [Member 3]
│   └── video_model.dart [Member 3]
├── providers/
│   └── app_provider.dart ✅ (auth, theme, user state)
├── screens/
│   ├── splash_screen.dart ✅
│   ├── auth_screen.dart ✅ (login/signup with roles)
│   ├── verification_screen.dart ✅ (email OTP)
│   ├── doctor_registration_screen.dart ✅ (professional info)
│   ├── main_screen.dart ✅ (role-based navigation)
│   ├── doctor_dashboard_screen.dart ✅ (doctor home)
│   ├── profile_screen.dart ✅ (role-based fields)
│   ├── settings_screen.dart ✅ (dark mode, logout, etc.)
│   ├── appointments_screen.dart ✅ (skeleton) [Member 1]
│   ├── consultation_screen.dart ✅ (skeleton) [Member 2]
│   ├── resources_screen.dart ✅ (skeleton) [Member 3]
│   ├── booking_screen.dart [Member 1]
│   ├── doctor_profile_screen.dart [Member 1]
│   ├── video_call_screen.dart [Member 2]
│   ├── voice_call_screen.dart [Member 2]
│   ├── chat_screen.dart [Member 2]
│   ├── article_detail_screen.dart [Member 3]
│   └── mood_tracker_screen.dart [Member 3]
├── services/
│   ├── location_service.dart ✅ (GPS location)
│   ├── places_service.dart ✅ (Google Places API)
│   ├── auth_service.dart ✅ [Member 4 - COMPLETE]
│   ├── database_service.dart ✅ [Member 4 - COMPLETE]
│   ├── storage_service.dart ✅ [Member 4 - COMPLETE]
│   ├── notification_service.dart ✅ [Member 4 - COMPLETE]
│   └── video_call_service.dart [Member 2]
├── widgets/
│   └── clinic_card.dart ✅
└── utils/
    ├── colors.dart ✅
    ├── validators.dart ✅ [Member 4 - COMPLETE]
    └── constants.dart [All]
```

---

## 📦 Current Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  provider: ^6.1.2          # State management ✅
  geolocator: ^13.0.2       # Location services ✅
  http: ^1.2.2              # API calls ✅
  google_sign_in: ^6.2.1    # Google auth ✅
  
  # Firebase (Member 4 - ADDED) ✅
  firebase_core: ^3.8.0
  firebase_auth: ^5.3.3
  cloud_firestore: ^5.5.0
  firebase_storage: ^12.3.6
  firebase_messaging: ^15.1.6
  shared_preferences: ^2.3.3
```

---

## 🎯 Milestones & Timeline

### **Week 1-2: Foundation**
- ✅ Base app structure complete
- ✅ Authentication flow complete
- ✅ Role-based UI complete
- Member 1: Booking UI skeleton
- Member 2: Research video SDK, basic integration
- Member 3: Content structure & article pages
- ✅ Member 4: Firebase packages added & all services created

### **Week 3-4: Core Features**
- Member 1: Full appointment booking flow
- Member 2: Video call working prototype
- Member 3: Resource categories & mood tracker
- Member 4: User profiles with Firebase, doctor verification

### **Week 5-6: Integration & Polish**
- All: Integrate features together
- All: Bug fixes and testing
- All: UI/UX improvements
- All: Documentation

### **Week 7: Final Delivery**
- Code review and cleanup
- Final testing
- Presentation preparation
- Demo video

---

## 🚀 Getting Started (For Each Member)

### **Step 1: Setup**
```bash
# Pull latest code
git pull origin main

# Install dependencies
flutter pub get

# Create your feature branch
git checkout -b feature/[your-name]-[feature]

# Example:
# git checkout -b feature/member1-appointments
```

### **Step 2: Run the App**
```bash
# Run on device/emulator
flutter run

# For hot reload during development, press 'r'
# For full restart, press 'R'
```

### **Step 3: Test User Roles**
- **Patient:** Sign up with "Patient" role selected
- **Doctor:** Sign up with "Doctor" role, fill professional info
- **Guest:** Use "Continue as Guest" button

### **Step 4: Development**
- Create your screens/services in the appropriate folders
- Follow existing patterns (check `doctor_dashboard_screen.dart` for reference)
- Use `context.watch<AppProvider>()` for reactive state
- Support dark mode using `Theme.of(context).brightness`

### **Step 5: Testing**
```bash
# Run tests
flutter test

# Check for errors
flutter analyze
```

### **Step 6: Merge**
- Create Pull Request
- Get code review from team
- Merge after approval

---

## 📞 Communication

**Group Chat:** [Your preferred platform]  
**Code Repository:** GitHub  
**Documentation:** This file + code comments  
**Issues:** Use GitHub Issues for bug tracking

---

## 💡 Tips for Success

1. **Use Existing Patterns:** Check `doctor_dashboard_screen.dart` and `auth_screen.dart` for UI patterns
2. **Dark Mode:** Always test in both light and dark modes
3. **Role-Based Logic:** Use `appProvider.isPatient`, `appProvider.isDoctor` for conditional rendering
4. **Commit Often:** Small, meaningful commits
5. **Ask for Help:** Don't get stuck for hours
6. **Code Reviews:** Learn from each other's code
7. **Testing:** Test on real devices, not just emulator

---

## 📝 Key Code Patterns

### **Accessing User State:**
```dart
final appProvider = context.watch<AppProvider>();

// Check role
if (appProvider.isDoctor) {
  // Doctor-specific UI
}

// Get user info
final user = appProvider.currentUser;
print(user?.name);
print(user?.specialty);
```

### **Dark Mode Support:**
```dart
final isDark = Theme.of(context).brightness == Brightness.dark;

Container(
  color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
  child: Text(
    'Hello',
    style: TextStyle(
      color: isDark ? Colors.white : AppColors.textPrimary,
    ),
  ),
)
```

### **Navigation:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const YourScreen()),
);
```

---

## ✅ Definition of Done

A feature is complete when:
- ✅ Code is written and working
- ✅ No linter errors (`flutter analyze`)
- ✅ Tested on Android (iOS if available)
- ✅ Works in both light and dark mode
- ✅ Role-appropriate (patient vs doctor)
- ✅ Properly commented
- ✅ Integrated with backend (if applicable)
- ✅ Reviewed by at least 1 team member
- ✅ Merged to main branch

---

**Created:** December 25, 2025  
**Last Updated:** December 29, 2025  
**Version:** 2.1 (Team Member 4 - Complete)

**Good luck, team! Let's build something amazing! 🚀🇳🇵**
