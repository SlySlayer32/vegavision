# VegaVision Project Guidelines

## Project Architecture

- Use MVVM (Model-View-ViewModel) architecture throughout the project
- Views should only handle UI rendering and user interactions
- ViewModels handle business logic and state management
- Models represent data structures
- Use GetIt for dependency injection and service location
- Organize code by feature, not by type
- Import paths must be consistent (e.g., 'package:vegavision/views/...')
- Never reference UI elements in models or repositories

## Flutter Coding Standards

- Follow Flutter style guide and Effective Dart principles
- Use named parameters for widget constructors
- Always prefer const constructors when possible
- Use Dart null safety features consistently throughout the codebase
- Extract reusable widgets to separate files
- Keep widget methods short and focused (maximum 30 lines)
- Always implement proper dispose methods to prevent memory leaks
- Avoid direct service instantiation - use GetIt instead

## Platform-Specific Development

- Create platform-specific implementations for cameras and storage
- Use platform checks with `if (Platform.isIOS)` or `if (Platform.isAndroid)`
- Implement proper permissions handling for both platforms
- Test on both platforms before submitting code
- Use Material Design for Android and Cupertino for iOS
- Handle safe area and notches consistently across platforms
- Implement adaptive screen sizing for different devices

## Package Management

- Specify exact version constraints in pubspec.yaml
- Document why each package is included
- Minimize transitive dependencies
- Check compatibility with both iOS and Android
- Run `flutter pub get` after changing pubspec.yaml
- Use `flutter_secure_storage` for sensitive information
- Organize Firebase packages properly

## Error Handling

- Implement try/catch for all async operations
- Log all errors with context information
- Provide user-friendly error messages in UI
- Never silently catch exceptions without handling
- Use typed exceptions for specific error cases
- Implement error boundaries in UI components
- Handle network and permission errors gracefully

## Firebase Integration

- Generate and properly store Firebase configuration files for all platforms
- Keep Firebase secrets out of version control
- Initialize Firebase before using any Firebase services
- Handle Firebase errors and authentication failures
- Use Cloud Functions for heavy processing
- Implement proper security rules for Firebase services
- Test Firebase functionality in both online and offline modes

## Testing Guidelines

- Write unit tests for all repositories and services
- Create widget tests for complex UI components
- Use MockDatabase and MockServices in tests
- Test happy paths and error handling scenarios
- Aim for at least 70% code coverage
- Implement widget testing for UI components
- Test platform-specific functionality

## Performance Optimization

- Use const widgets to minimize rebuilds
- Implement proper image compression and caching
- Optimize list views with lazy loading
- Use background processing for heavy operations
- Profile and optimize main thread operations
- Implement efficient local storage with Hive
- Optimize Firebase operations with caching

## Naming Conventions

- Use PascalCase for classes and enum types
- Use camelCase for variables, methods, and functions
- Use snake_case for file names
- Use ALL_CAPS for constants
- Prefix private variables with underscore (_)
- Name files according to their primary class
- Keep naming consistent across similar components
