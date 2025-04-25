# VegaVision

AI-powered image editing application for iOS and Android.

## Project Overview

VegaVision is a Flutter application that provides AI-powered image editing capabilities specifically optimized for iOS and Android platforms. The app allows users to capture images, edit them using AI-powered tools, and save the results with a mobile-first approach.

## Getting Started

### Prerequisites

- Flutter SDK v3.7.2 or later
- Dart SDK
- Android Studio or VS Code with Flutter plugins
- Xcode 14.0+ (for iOS development)
- CocoaPods (for iOS dependency management)
- Firebase account (for cloud storage and functions)

### Installation

1. Clone the repository:

```bash
git clone [repository-url]
cd vegavision
```

2. Install dependencies:

```bash
flutter pub get
```

3. Configure Firebase for mobile platforms:

```bash
flutter pub add firebase_core
flutter pub add flutterfire_cli
flutter pub exec flutterfire configure
```

4. Generate model files:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

5. Initialize Hive database:

```bash
flutter pub run hive_generator:init
```

6. Generate splash screens:

```bash
flutter pub run flutter_native_splash:create
```

7. Run the app on a mobile device:

```bash
flutter run
```

## Mobile Platform Development Setup

### iOS Setup

1. Install CocoaPods if not already installed:

```bash
sudo gem install cocoapods
```

2. Navigate to iOS directory and install pods:

```bash
cd ios
pod install
cd ..
```

3. Open the project in Xcode:

```bash
open ios/Runner.xcworkspace
```

4. Configure app capabilities, signing, and permissions in Xcode.

### Android Setup

1. Make sure you have Android SDK installed.

2. Configure your app in the Android directory:
   - Update `android/app/src/main/AndroidManifest.xml` with required permissions
   - Configure Gradle settings if needed

3. Build the Android app:

```bash
flutter build apk --release
```

## Project Structure

The app follows a clean architecture approach:

- **core/**: Contains constants, dependency injection, and utilities
- **models/**: Data classes
- **repositories/**: Data access layer
- **services/**: Business logic and services
- **viewmodels/**: State management for views
- **views/**: UI components organized by feature

### Available Scripts

The following scripts are available for development:

- Format code:

```bash
dart run scripts:format
```

- Fix common issues:

```bash
dart run scripts:fix
```

- Analyze code:

```bash
dart run scripts:analyze
```

- Run custom lint:

```bash
dart run scripts:lint
```

- Run all checks:

```bash
dart run scripts:check_all
```

- Build Android release:

```bash
dart run scripts:build_android
```

- Build iOS release:

```bash
dart run scripts:build_ios
```

- Generate splash screens:

```bash
dart run scripts:generate_splash
```

### Pre-commit Hooks and Lint-staged

This project uses pre-commit hooks with lint-staged to ensure code quality before pushing to GitHub. Follow these steps to set up:

1. Install dependencies:

```bash
flutter pub get
dart pub add --dev lint_staged husky
```

2. Initialize husky:

```bash
dart run husky install
```

3. Create a pre-commit hook:

```bash
dart run husky set .husky/pre-commit "dart run lint_staged"
```

## Testing

### Running Tests

Run unit and widget tests:

```bash
flutter test
```

Run integration tests on a connected device:

```bash
flutter test integration_test/app_test.dart
```

## Mobile-Specific Features

- **Adaptive UI**: Follows both Material Design and Cupertino design patterns
- **Camera Integration**: Optimized for iOS and Android camera hardware
- **Local Storage**: Efficient local caching with Hive
- **Push Notifications**: Integration with Firebase Cloud Messaging
- **Device-specific optimizations**: Adapts to different screen sizes and capabilities
- **Permissions Handling**: Smart permission requests for camera, storage, etc.
- **Offline Support**: Works offline with data synchronization when online

## Future Web Support

Web support is planned for future releases. The architecture has been designed to accommodate web platform expansion when needed.

## Dependencies

Key dependencies include:

- **UI Components**: Cupertino_icons, flutter_spinkit
- **State Management**: Provider, GetIt
- **Firebase/Google Cloud**: Firebase Storage, Cloud Functions
- **Storage & Security**: Flutter Secure Storage, Hive
- **Image Processing**: Camera, Flutter Image Compress
- **Mobile-specific**: Device Info Plus, Connectivity Plus, Permission Handler
- **Mobile UI/UX**: Modal Bottom Sheet, Pull to Refresh

For a complete list of dependencies, see the `pubspec.yaml` file.
