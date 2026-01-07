# 🇳🇵 Connect Well Nepal

<div align="center">
  
  ### Your Telehealth Partner in Nepal
  
  A comprehensive telehealth application connecting patients with healthcare providers across Nepal.
  
  ![Flutter](https://img.shields.io/badge/Flutter-3.27+-blue.svg)
  ![Firebase](https://img.shields.io/badge/Firebase-Integrated-green.svg)
  ![License](https://img.shields.io/badge/License-MIT-green.svg)
</div>

---

## 📱 About

**Connect Well Nepal** is a student-developed telehealth platform designed to:
- Connect patients with doctors via video/voice/chat consultations
- Provide easy appointment booking and management
- Offer health education resources and self-care tools
- Enable remote healthcare access across Nepal

**Inspired by:** Timely Care and similar telehealth platforms

---

## ✨ Features

### ✅ Implemented Features:

#### **Authentication & User Management**
✅ **Email/Password Authentication** - Complete signup and login flow  
✅ **Google Sign-In** - One-tap authentication with Google  
✅ **Email Verification** - OTP-based email verification  
✅ **Role-Based Access** - Patient, Doctor, Care Provider, and Guest roles  
✅ **Doctor Registration** - Professional details collection (specialty, license, qualification)  
✅ **Password Reset** - Forgot password functionality  
✅ **Password Change** - Change password from settings  
✅ **Profile Management** - Edit profile with medical history  
✅ **Profile Picture Upload** - Change profile picture from gallery/camera  

#### **Core App Features**
✅ **Splash Screen** - Beautiful branded launch screen  
✅ **Home Dashboard** - Personalized greeting with user name and avatar  
✅ **Self-Care Hub** - Quick access to meditation, exercise, nutrition, and mental health resources  
✅ **Available Doctors** - Browse doctors with ratings and specialties  
✅ **Nearby Healthcare** - Find clinics and hospitals with distance and ratings (global support via OpenStreetMap)  
✅ **AI Assistant** - Chatbot to help users with app features  
✅ **Dark Mode** - Full light/dark theme support  
✅ **Settings Screen** - Preferences, notifications, language selection  

#### **Communication Features**
✅ **Real-Time Chat** - Chat between patients and doctors  
✅ **Chat List** - View all conversations  
✅ **Message Types** - Text, images, and file attachments  
✅ **Typing Indicators** - Real-time typing status  

#### **Health Resources**
✅ **Article System** - Health articles with categories  
✅ **Article Details** - Full article reading experience  
✅ **Category Browsing** - Browse articles by health topics  
✅ **Search Functionality** - Search articles and content  

#### **Backend & Services**
✅ **Firebase Integration** - Fully configured and connected  
✅ **Firestore Database** - User data, appointments, consultations, reviews  
✅ **Firebase Authentication** - Complete auth system  
✅ **Firebase Storage** - Profile images and file uploads  
✅ **Location Services** - Real-time GPS location  
✅ **Places API** - OpenStreetMap integration for global healthcare facilities  

#### **Appointment Management**
✅ **Booking Screen** - Complete date/time selection with calendar  
✅ **Appointment Management** - View, cancel, reschedule appointments  
✅ **Doctor Profile** - Detailed doctor information with ratings  
✅ **Schedule Management** - Doctor availability management  
✅ **Local Notifications** - Appointment reminders  
✅ **Time Slot Selection** - Interactive time picker widget

#### **Consultation Features**
✅ **Video Calls** - Agora RTC integration for video consultations  
✅ **Chat Consultation** - Real-time text messaging with doctors  
✅ **Chat List** - View all conversations  
✅ **Call Controls** - Mute, video toggle, camera switch, speaker  
✅ **Call Timer** - Track consultation duration

#### **Additional Features**
✅ **AI Assistant** - Chatbot for app navigation and help  
✅ **Doctor Browsing** - Browse all available doctors  
✅ **Healthcare Facilities** - Nearby clinics and hospitals  
✅ **Admin Verification** - Doctor verification system  
✅ **Article Bookmarking** - Save favorite health articles

### 🔄 In Progress / Planned:
🔄 Push notifications (FCM ready, needs server setup)  
🔄 Prescription sharing  
🔄 Multi-language support (Nepali/English)  
🔄 Payment integration  
🔄 Analytics dashboard  

---

## 🏗️ Architecture

```
lib/
├── main.dart                    # App entry point with Firebase init
├── models/                      # Data models
│   ├── user_model.dart         ✅ User with roles
│   ├── place_model.dart        ✅ Healthcare facilities
│   ├── clinic_model.dart       ✅ Clinic data
│   ├── article_model.dart      ✅ Health articles
│   ├── chat_model.dart         ✅ Messages & conversations
│   ├── appointment_model.dart  ✅ Appointments
│   └── doctor_model.dart       ✅ Doctor information
├── providers/                   # State management
│   └── app_provider.dart       ✅ Auth, theme, user state
├── screens/                     # Full-page screens
│   ├── splash_screen.dart      ✅ Branded launch
│   ├── auth_screen.dart        ✅ Login/Signup
│   ├── verification_screen.dart ✅ Email OTP
│   ├── doctor_registration_screen.dart ✅ Professional info
│   ├── main_screen.dart        ✅ Role-based navigation
│   ├── doctor_dashboard_screen.dart ✅ Doctor home
│   ├── profile_screen.dart     ✅ Profile management
│   ├── settings_screen.dart    ✅ App settings
│   ├── appointment_screen.dart ✅ Complete appointment management
│   ├── booking_screen.dart     ✅ Full booking flow with calendar
│   ├── consultation_screen.dart ✅ Consultation type selection
│   ├── video_call_screen.dart  ✅ Agora RTC video calls
│   ├── resources_screen.dart   ✅ Health content
│   ├── article_detail_screen.dart ✅ Article reader with bookmarks
│   ├── category_screen.dart    ✅ Category browsing
│   ├── chat_screen.dart        ✅ Real-time chat messaging
│   ├── chat_list_screen.dart   ✅ Conversation list
│   ├── ai_assistant_screen.dart ✅ AI chatbot
│   ├── all_doctors_screen.dart  ✅ Doctor browsing
│   ├── all_healthcare_screen.dart ✅ Healthcare facilities
│   ├── doctor_profile_screen.dart ✅ Doctor details & ratings
│   ├── schedule_management_screen.dart ✅ Doctor schedule management
│   └── admin_verification_screen.dart ✅ Admin doctor verification
├── widgets/                     # Reusable components
│   ├── clinic_card.dart        ✅ Clinic display
│   ├── article_card.dart       ✅ Article display
│   ├── appointment_card.dart   ✅ Appointment display card
│   └── time_selector.dart      ✅ Time slot selector widget
├── services/                    # Backend services
│   ├── auth_service.dart       ✅ Firebase Auth
│   ├── database_service.dart   ✅ Firestore operations
│   ├── storage_service.dart    ✅ Firebase Storage
│   ├── notification_service.dart ✅ FCM setup
│   ├── local_notification_service.dart ✅ Local appointment reminders
│   ├── chat_service.dart       ✅ Real-time messaging
│   ├── video_call_service.dart ✅ Video call management
│   ├── video_call_service_base.dart ✅ Video call base interface
│   ├── video_call_service_mobile.dart ✅ Mobile video call implementation
│   ├── location_service.dart   ✅ GPS location
│   ├── places_service.dart     ✅ Google Places (ready)
│   ├── osm_places_service.dart ✅ OpenStreetMap places
│   └── article_service.dart    ✅ Article management
└── utils/                       # Constants, themes, helpers
    ├── colors.dart             ✅ App color scheme
    └── validators.dart         ✅ Form validation
```

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.27 or higher
- Dart 3.10.4 or higher
- Android Studio / VS Code
- iOS Simulator (Mac) or Android Emulator

### Installation

```bash
# Clone the repository
git clone [your-repo-url]
cd connect-well-nepal

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### First Time Setup

1. **Add the Logo:**
   - Save your logo to `assets/logos/logo.png`
   - Save icon to `assets/logos/logo_icon.png`
   - See `LOGO_INTEGRATION_GUIDE.md` for details

2. **Firebase Setup** ✅ (Already Configured):
   - Firebase project: `connect-well-nepal`
   - `google-services.json` configured for Android
   - Firestore security rules deployed
   - Authentication providers enabled
   - See `GETTING_STARTED.md` for Firebase console setup details

---

## 👥 Team

This project is developed by a team of 4 students:

| Member | Focus Area | Status |
|--------|-----------|--------|
| **Member 1** | Appointments & Booking | ✅ **COMPLETE** - Full booking flow implemented |
| **Member 2** | Video/Voice Calls & Chat | ✅ **COMPLETE** - Agora RTC & real-time chat ready |
| **Member 3** | Health Resources | ✅ **COMPLETE** - Articles, categories, bookmarks implemented |
| **Member 4** | Backend & Auth | ✅ **COMPLETE** - All Firebase services implemented |

**See `TEAM_DISTRIBUTION.md` for detailed task assignments and implementation status.**

---

## 📚 Documentation

- **[TEAM_DISTRIBUTION.md](TEAM_DISTRIBUTION.md)** - Complete work distribution for 4 members
- **[PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)** - Architecture and code organization
- **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** - Current project status and progress
- **[LOGO_INTEGRATION_GUIDE.md](LOGO_INTEGRATION_GUIDE.md)** - How to add your logo
- **[GETTING_STARTED.md](GETTING_STARTED.md)** - Development workflow guide

---

## 🎨 Design System

### Colors
- **Primary (Navy Blue):** `#1A2F5A` - Trust, professionalism
- **Secondary (Crimson Red):** `#DC143C` - Nepal's national color
- **Background:** `#FFFFFF` / `#F8F9FA` - Clean, accessible

### Typography
- Material Design 3 default fonts
- Clear hierarchy and readability

### Components
- Cards with 12px border radius
- Elevated buttons with rounded corners
- Consistent spacing (8px grid system)

---

## 🛠️ Tech Stack

| Technology | Purpose | Status |
|------------|---------|--------|
| **Flutter** | Cross-platform mobile framework | ✅ Active |
| **Dart** | Programming language | ✅ Active |
| **Material Design 3** | UI/UX design system | ✅ Implemented |
| **Provider** | State management | ✅ Implemented |
| **Firebase Core** | Firebase initialization | ✅ Integrated |
| **Firebase Auth** | Authentication | ✅ Integrated |
| **Cloud Firestore** | NoSQL database | ✅ Integrated |
| **Firebase Storage** | File storage | ✅ Integrated |
| **Firebase Messaging** | Push notifications | ✅ Ready |
| **Google Sign-In** | Social authentication | ✅ Integrated |
| **Geolocator** | Location services | ✅ Integrated |
| **OpenStreetMap** | Places API (free alternative) | ✅ Integrated |
| **Agora RTC Engine** | Video calling | ✅ Integrated |
| **Table Calendar** | Appointment booking calendar | ✅ Integrated |
| **Local Notifications** | Appointment reminders | ✅ Integrated |

---

## 📱 Supported Platforms

- ✅ **Android** (Primary target)
- ✅ **Web** (Primary target)

*Note: iOS, macOS, Linux, and Windows support can be added later if needed.*

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Analyze code
flutter analyze
```

---

## 🤝 Contributing

This is a student project. Contributions from team members:

1. Create feature branch: `git checkout -b feature/your-feature`
2. Commit changes: `git commit -am 'Add feature'`
3. Push branch: `git push origin feature/your-feature`
4. Create Pull Request
5. Wait for review & approval

### Code Standards
- ✅ Follow existing code style
- ✅ Add comments for complex logic
- ✅ No linter errors
- ✅ Test your changes
- ✅ Update documentation

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 🙏 Acknowledgments

- Inspired by **Timely Care** and modern telehealth platforms
- Built with ❤️ for improving healthcare access in Nepal
- Thanks to our instructors and mentors

---

## 📞 Contact

**Project Repository:** [GitHub Link]  
**Team Lead:** Sachin Shrestha  
**Email:** [Your Email]

---

## 🗺️ Roadmap

### Phase 1 - Base Application ✅ **COMPLETE**
- [x] Project structure
- [x] Basic UI screens
- [x] Navigation system
- [x] Design system
- [x] Material Design 3 theming
- [x] Dark mode support

### Phase 2 - Core Features ✅ **COMPLETE**
- [x] Firebase integration
- [x] User authentication (Email, Google)
- [x] Email verification
- [x] Role-based access (Patient, Doctor, Guest)
- [x] Profile management
- [x] Real-time chat
- [x] Health resources & articles
- [x] Nearby healthcare facilities
- [x] AI assistant
- [x] Settings & preferences
- [x] Appointment booking (Complete with calendar & notifications)
- [x] Video consultations (Agora RTC integrated)
- [x] Chat consultations
- [x] Doctor profile & browsing
- [x] Schedule management
- [x] Article bookmarking

### Phase 3 - Advanced Features 🔄 **PARTIALLY COMPLETE**
- [x] Complete appointment booking flow
- [x] Video call integration (Agora RTC)
- [x] Chat consultation
- [x] Local notifications (appointment reminders)
- [ ] Push notifications (FCM ready, needs server configuration)
- [ ] Prescription management
- [ ] Payment integration
- [ ] Analytics dashboard
- [ ] Multi-language support (Nepali/English)

### Phase 4 - Launch
- [ ] Beta testing
- [ ] Bug fixes & optimization
- [ ] App store deployment
- [ ] Marketing materials

---

<div align="center">
  <p><strong>Made with ❤️ in Nepal 🇳🇵</strong></p>
  <p>Connect Well Nepal - Bridging Healthcare Gaps Through Technology</p>
</div>
