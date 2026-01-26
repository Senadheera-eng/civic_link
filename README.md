# CivicLink

**Report. Track. Resolve.**

A cross-platform mobile application that bridges the gap between citizens and government departments, enabling efficient reporting and resolution of civic issues.

![Flutter](https://img.shields.io/badge/Flutter-3.7+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.7+-0175C2?logo=dart)
![Firebase](https://img.shields.io/badge/Firebase-Backend-FFCA28?logo=firebase)
![License](https://img.shields.io/badge/License-MIT-green)

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Screenshots](#screenshots)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Firebase Setup](#firebase-setup)
- [Configuration](#configuration)
- [Usage](#usage)
- [API & Services](#api--services)
- [Database Schema](#database-schema)
- [Localization](#localization)
- [Contributing](#contributing)
- [License](#license)

## Overview

CivicLink is a civic engagement platform designed to streamline the process of reporting and resolving municipal issues. Citizens can report problems like road damage, water leaks, power outages, and more, while government officials can efficiently manage and track issue resolution through dedicated dashboards.

### Key Benefits

- **For Citizens**: Easy issue reporting with location tagging and photo uploads, real-time status tracking, and notifications
- **For Government Officials**: Department-specific dashboards, performance analytics, and efficient issue management
- **For Municipalities**: Improved response times, data-driven insights, and better citizen engagement

## Features

### Citizen Features

- User registration and authentication (Email/Password, Google Sign-In)
- Issue reporting with GPS location tagging
- Photo attachments (up to 5 images per issue)
- Real-time issue status tracking
- Personal issue history and statistics
- Interactive map view of reported issues
- Push notifications for status updates
- Multi-language support (English, Sinhala)
- Dark/Light theme options

### Government Official Features

- Department-specific dashboard
- Issue filtering by status, priority, and date range
- Performance metrics and analytics
- Weekly resolution reports
- Issue assignment and management
- Quick actions for common tasks
- Working hours configuration
- Auto-assignment settings
- Verification badge system

### Issue Categories

| Department | Description | SLA |
|------------|-------------|-----|
| Public Safety | Police, Fire, Emergency Services | 1 hour |
| Electricity & Power | Power outages, electrical hazards | 4 hours |
| Water & Sewage | Water leaks, sewage problems | 6 hours |
| Road & Transportation | Potholes, traffic signals, road damage | 24 hours |
| Environmental | Garbage, pollution, illegal dumping | 72 hours |

### Issue Priorities

- **Critical** - Immediate attention required
- **High** - Urgent but not critical
- **Medium** - Standard priority
- **Low** - Non-urgent issues

## Tech Stack

### Frontend
- **Framework**: Flutter (Cross-platform)
- **Language**: Dart 3.7+
- **State Management**: Provider
- **UI**: Material Design 3

### Backend & Services
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage
- **Push Notifications**: Firebase Cloud Messaging
- **Maps**: Google Maps Flutter

### Key Dependencies

```yaml
dependencies:
  firebase_core: ^3.13.0
  firebase_auth: ^5.6.0
  cloud_firestore: ^5.6.9
  firebase_storage: ^12.4.7
  firebase_messaging: ^15.2.7
  google_sign_in: ^6.3.0
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  geocoding: ^2.1.1
  image_picker: ^1.0.4
  provider: ^6.1.1
  fl_chart: ^0.69.0
  flutter_local_notifications: ^19.3.0
```

## Project Structure

```
civic_link/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── firebase_options.dart     # Firebase configuration
│   ├── models/                   # Data models
│   │   ├── user_model.dart
│   │   ├── issue_model.dart
│   │   └── notification_model.dart
│   ├── screens/                  # UI screens
│   │   ├── auth/                 # Authentication screens
│   │   ├── citizen/              # Citizen-specific screens
│   │   └── official/             # Official dashboard screens
│   ├── services/                 # Business logic
│   │   ├── auth_service.dart
│   │   ├── issue_service.dart
│   │   ├── notification_service.dart
│   │   └── settings_service.dart
│   ├── theme/                    # App theming
│   │   └── modern_theme.dart
│   ├── widgets/                  # Reusable components
│   │   ├── custom_widgets.dart
│   │   └── department/           # Department-specific widgets
│   ├── utils/                    # Utilities
│   │   ├── constants.dart
│   │   ├── helpers.dart
│   │   └── validators.dart
│   └── l10n/                     # Localization files
├── assets/                       # Static assets
├── android/                      # Android configuration
├── ios/                          # iOS configuration
├── pubspec.yaml                  # Dependencies
└── README.md
```

## Getting Started

### Prerequisites

- Flutter SDK 3.7.0 or higher
- Dart SDK 3.7.0 or higher
- Android Studio / VS Code with Flutter extensions
- Firebase account
- Google Maps API key

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/civic_link.git
   cd civic_link
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate localization files**
   ```bash
   flutter gen-l10n
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Firebase Setup

1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)

2. Enable the following services:
   - **Authentication**: Enable Email/Password and Google Sign-In
   - **Cloud Firestore**: Create database in production mode
   - **Storage**: Set up storage bucket for image uploads
   - **Cloud Messaging**: Enable for push notifications

3. Add your app to Firebase:
   - **Android**: Download `google-services.json` and place in `android/app/`
   - **iOS**: Download `GoogleService-Info.plist` and add to Xcode project

4. Update `lib/firebase_options.dart` with your Firebase credentials:
   ```dart
   static const FirebaseOptions android = FirebaseOptions(
     apiKey: 'YOUR_API_KEY',
     appId: 'YOUR_APP_ID',
     messagingSenderId: 'YOUR_SENDER_ID',
     projectId: 'YOUR_PROJECT_ID',
     storageBucket: 'YOUR_STORAGE_BUCKET',
   );
   ```

5. Set up Firestore security rules:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
       match /issues/{issueId} {
         allow read: if request.auth != null;
         allow create: if request.auth != null;
         allow update: if request.auth != null;
       }
       match /notifications/{notificationId} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

## Configuration

### Google Maps API

1. Get an API key from [Google Cloud Console](https://console.cloud.google.com/)
2. Enable Maps SDK for Android and iOS

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

**iOS** (`ios/Runner/AppDelegate.swift`):
```swift
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
```

### Environment Variables

Create a `.env` file (optional) for environment-specific configurations:
```
FIREBASE_API_KEY=your_api_key
GOOGLE_MAPS_API_KEY=your_maps_key
```

## Usage

### For Citizens

1. **Register/Login**: Create an account or sign in with Google
2. **Report Issue**: Tap the + button to report a new issue
   - Select category and priority
   - Add description and photos
   - Location is automatically detected
3. **Track Issues**: View your reported issues in "My Issues"
4. **Get Updates**: Receive notifications when status changes

### For Government Officials

1. **Register as Official**: Select "Official" during registration
2. **Choose Department**: Select your assigned department
3. **Access Dashboard**: View department-specific issues
4. **Manage Issues**: Update status, add notes, assign issues
5. **View Analytics**: Monitor performance metrics

## API & Services

### AuthService

```dart
// Sign in with email
await authService.signInWithEmail(email, password);

// Register new user
await authService.signUpWithEmail(email, password, fullName, userType);

// Sign out
await authService.signOut();
```

### IssueService

```dart
// Submit new issue
await issueService.submitIssue(
  title: title,
  description: description,
  category: category,
  priority: priority,
  images: imageFiles,
);

// Get user's issues
Stream<List<IssueModel>> issues = issueService.getUserIssues(userId);

// Update issue status
await issueService.updateIssueStatus(issueId, newStatus);
```

### NotificationService

```dart
// Initialize notifications
await notificationService.initialize();

// Send notification
await notificationService.sendNotification(
  userId: userId,
  title: title,
  body: body,
);
```

## Database Schema

### Users Collection

```javascript
users/{userId} {
  uid: string,
  email: string,
  fullName: string,
  userType: 'citizen' | 'official',
  department: string?,        // Only for officials
  employeeId: string?,        // Only for officials
  profilePicture: string,
  createdAt: timestamp,
  isVerified: boolean,
  isActive: boolean,
  verifiedAt: timestamp?,
  verifiedBy: string?
}
```

### Issues Collection

```javascript
issues/{issueId} {
  id: string,
  title: string,
  description: string,
  category: string,
  status: 'pending' | 'in_progress' | 'resolved' | 'rejected',
  priority: 'Low' | 'Medium' | 'High' | 'Critical',
  userId: string,
  userEmail: string,
  userName: string,
  latitude: number,
  longitude: number,
  address: string,
  imageUrls: string[],
  createdAt: timestamp,
  updatedAt: timestamp?,
  adminNotes: string?,
  assignedTo: string?
}
```

### Notifications Collection

```javascript
notifications/{notificationId} {
  id: string,
  userId: string,
  title: string,
  body: string,
  data: map,
  imageUrl: string?,
  isRead: boolean,
  createdAt: timestamp,
  readAt: timestamp?
}
```

## Localization

CivicLink supports multiple languages:

- **English** (en_US) - Default
- **Sinhala** (si_LK)

### Adding New Languages

1. Create a new ARB file in `lib/l10n/`:
   ```
   lib/l10n/app_[locale].arb
   ```

2. Add translations following the template in `app_en.arb`

3. Run localization generation:
   ```bash
   flutter gen-l10n
   ```

## Build Commands

```bash
# Development
flutter run

# Build APK (Android)
flutter build apk

# Build App Bundle (Android)
flutter build appbundle

# Build iOS
flutter build ios

# Run tests
flutter test

# Analyze code
flutter analyze
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Run `flutter analyze` before committing
- Write meaningful commit messages

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- All contributors who helped build this project

---

**CivicLink** - Empowering citizens, enabling governments, building better communities.
