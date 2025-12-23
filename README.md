# Connect Well Nepal

A Flutter application for Connect Well Nepal.

## Platforms

This project supports:
- ✅ Android
- ✅ Web
- ✅ iOS (setup required)
- ✅ macOS (setup required)
- ✅ Linux
- ✅ Windows

## Prerequisites

- Flutter SDK (v3.38.5 or higher)
- Dart SDK
- For Android development:
  - Android Studio
  - Android SDK
  - Android SDK Command-line Tools
- For Web development:
  - Google Chrome

## Getting Started

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Run the App

For Android:
```bash
flutter run -d android
```

For Web:
```bash
flutter run -d chrome
```

For other platforms:
```bash
flutter devices  # List available devices
flutter run      # Run on default device
```

## Project Structure

```
lib/
  └── main.dart          # Main application entry point
test/
  └── widget_test.dart   # Widget tests
android/                 # Android-specific code
ios/                     # iOS-specific code
web/                     # Web-specific code
macos/                   # macOS-specific code
linux/                   # Linux-specific code
windows/                 # Windows-specific code
```

## Development

### Running Tests

```bash
flutter test
```

### Building for Production

Android:
```bash
flutter build apk --release
```

Web:
```bash
flutter build web --release
```

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
- [Dart Documentation](https://dart.dev/guides)
