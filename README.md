# VegaVision

AI-powered image editing application built with Flutter, following MVVM architecture.

## Features

### Image Capture
- Camera integration with real-time preview
- Image selection from gallery
- Platform-specific camera implementations
- Permission handling for camera and storage

### Image Editor
- AI-powered image editing suggestions
- Custom marker placement
- Real-time preview
- Undo/redo support
- Save and share functionality

### Result View
- Before/after comparison
- Edit history
- Share functionality
- Save to gallery

## Project Structure

```
lib/
├── core/                 # Core functionality
│   ├── base/            # Base classes (MVVM)
│   ├── di/             # Dependency injection
│   ├── error/          # Error handling
│   ├── logging/        # Logging system
│   ├── navigation/     # Navigation service
│   ├── permissions/    # Permission handling
│   ├── theme/         # Theme management
│   └── utils/         # Utilities
├── features/           # Feature modules
│   ├── image_capture/
│   │   ├── models/
│   │   ├── services/
│   │   ├── view_models/
│   │   └── views/
│   ├── image_editor/
│   └── result/
└── shared/            # Shared components
    ├── models/
    ├── repositories/
    └── services/
```

## Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/vegavision.git
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Setup Firebase:
   - Add `google-services.json` for Android
   - Add `GoogleService-Info.plist` for iOS

4. Run the app:
   ```bash
   flutter run
   ```

## Development

### Code Generation
```bash
# Generate all files
flutter pub run build_runner build

# Watch for changes
flutter pub run build_runner watch
```

### Testing
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
```

### Code Quality
```bash
# Format code
dart format lib test

# Analyze code
flutter analyze

# Check all
flutter pub run scripts:check_all
```

## Architecture

### MVVM Implementation
- **Models**: Data structures and business logic
- **Views**: UI components only
- **ViewModels**: Business logic and state management
- **Services**: Platform and business services

### Dependency Injection
Using GetIt for service location and dependency injection.

### State Management
Using Provider/ChangeNotifier with MVVM pattern.

## Tools & Libraries

### Core
- `get_it`: Dependency injection
- `provider`: State management
- `hive`: Local storage
- `firebase_core`: Firebase integration

### Image Processing
- `camera`: Camera access
- `image_picker`: Image selection
- `flutter_image_compress`: Image optimization

### UI Components
- Material Design & Cupertino widgets
- Custom MVVM widgets
- Adaptive UI components

### Testing
- `mockito`: Mocking for tests
- `golden_toolkit`: Golden tests
- Integration tests
- Widget tests

## Best Practices

See [GUIDELINES.md](docs/GUIDELINES.md) for detailed development guidelines covering:
- Code organization
- Error handling
- Testing requirements
- Performance optimization
- Firebase integration
- Platform-specific development

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.