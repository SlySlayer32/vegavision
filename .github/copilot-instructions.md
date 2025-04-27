# Copilot Instructions for VegaVision Project

This document provides comprehensive guidelines for generating high-quality code with GitHub Copilot that aligns with the VegaVision project's architecture, patterns, and best practices.

---

## Project Overview

VegaVision is an AI-powered image editing application for iOS and Android built with Flutter. The app allows users to capture, edit, and enhance images using AI. Key features include:

- Image capture and selection from gallery
- AI-assisted image editing with markers for areas to modify
- Offline capability with synchronized uploads when online
- Cross-platform support (iOS and Android)

---

## Architecture Foundation

### MVVM Architecture & Feature-First Organization

VegaVision strictly follows an MVVM (Model-View-ViewModel) architecture organized by features:

1. **Models** (`/models`): Data structures only with minimal logic
2. **Views** (`/views`, `/features/*/views`): UI components that render data and handle user interactions
3. **ViewModels** (`/viewmodels`, `/features/*/view_models`): Business logic and state management
4. **Repositories** (`/repositories`): Data access and persistence
5. **Services** (`/services`): Platform or technical capabilities

Features are organized in a modular structure:
```
/features
  /image_capture
    /models
    /services
    /views
    /view_models
  /image_editor
    /models
    /services
    /views
    /view_models
  /result
    ...
```

---

## Code Generation Guidelines

### Base Classes & Patterns

When generating code, extend or implement these base classes:

1. **BaseViewModel**:
   ```dart
   class YourViewModel extends BaseViewModel {
     YourViewModel(this._someService, this._someRepository);
     
     // Services and repositories should be private final fields
     final SomeService _someService;
     final SomeRepository _someRepository;
     
     // Use handleApiRequest for all API calls
     Future<void> loadData() async {
       await handleApiRequest(() => _someRepository.getData());
     }
   }
   ```

2. **BaseView**:
   ```dart
   class YourView extends BaseView<YourViewModel> {
     @override
     YourViewModel createViewModel(BuildContext context) {
       return getIt<YourViewModel>();
     }
     
     @override
     Widget buildView(BuildContext context, YourViewModel viewModel) {
       return // Your UI code here
     }
   }
   ```

3. **BaseRepository**:
   ```dart
   class YourRepository extends BaseRepository {
     YourRepository(this._apiService, this._storageService);
     
     final ApiService _apiService;
     final StorageService _storageService;
     
     // Implement methods with proper error handling
   }
   ```

### Dependency Injection

Always use GetIt for dependency injection:

```dart
// Registering dependencies
getIt.registerLazySingleton<YourService>(() => YourService());
getIt.registerFactory<YourViewModel>(() => YourViewModel(
  getIt<ServiceA>(),
  getIt<RepositoryB>(),
));

// Using dependencies
final service = getIt<YourService>();
```

Never directly instantiate services, repositories, or ViewModels.

---

## State Management

### ViewModels & Reactive Programming

1. **State Management**:
   - Use the ViewState enum (`idle`, `loading`, `error`, `success`) from BaseViewModel
   - Update state using setState(), setError(), and resetState() methods
   - Use notifyListeners() sparingly

2. **Error Handling**:
   - Use handleApiRequest for all API calls to get consistent error handling
   - Include retry capability for recoverable errors
   - Provide clear user-facing error messages

3. **Lifecycle Management**:
   - Initialize data in createViewModel or initState
   - Clean up resources in dispose methods
   - Handle streaming data properly with subscription cancellation

Example:
```dart
// In your ViewModel
@override
void dispose() {
  _dataStream?.cancel();
  super.dispose();
}
```

---

## UI Implementation

### Widget Best Practices

1. **Widget Structure**:
   - Use `const` constructors whenever possible
   - Keep widget methods under 30 lines
   - Extract reusable widgets into separate files
   - Use named parameters for all widget constructors

2. **Performance Optimization**:
   - Use RepaintBoundary to isolate expensive UI updates
   - Implement pagination for large data sets
   - Use const widgets to minimize rebuilds
   - Cache expensive computations

3. **UI State Handling**:
   - Use Consumer pattern for precise rebuilds
   - Handle loading, error, and empty states explicitly
   - Implement proper form validation with clear error messages

Example:
```dart
@override
Widget build(BuildContext context) {
  return Consumer<YourViewModel>(
    builder: (context, viewModel, _) {
      if (viewModel.isLoading) {
        return const Center(child: CircularProgressIndicator());
      } else if (viewModel.hasError) {
        return ErrorWidget(
          message: viewModel.errorMessage,
          onRetry: viewModel.retry,
        );
      } else if (viewModel.items.isEmpty) {
        return const EmptyStateWidget();
      }
      
      return ListView.builder(
        itemCount: viewModel.items.length,
        itemBuilder: (context, index) {
          // Build item UI
        },
      );
    },
  );
}
```

---

## Platform-Specific Implementation

1. **Platform Detection**:
   ```dart
   if (Platform.isIOS) {
     // iOS-specific implementation
   } else if (Platform.isAndroid) {
     // Android-specific implementation
   }
   ```

2. **Permissions Handling**:
   - Use the `permission_handler` package with proper request flow
   - Always check permissions before accessing sensitive features
   - Provide clear explanations for permission requests

3. **UI Adaptation**:
   - Use Material design for Android and Cupertino for iOS
   - Account for notches, safe areas, and different screen sizes
   - Implement adaptive sizing using MediaQuery

---

## Firebase Integration

1. **Authentication**:
   - Initialize Firebase before using services
   - Handle authentication state changes reactively
   - Implement proper token refresh and session management

2. **Security**:
   - Do not include Firebase secrets in version control
   - Implement proper Firestore security rules
   - Validate data before uploading to Firebase

3. **Offline Support**:
   - Cache Firebase responses for offline use
   - Queue operations when offline using WorkManager
   - Sync when connection is restored

Example Firebase Initialization:
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

---

## Storage & Caching

1. **Local Storage**:
   - Use Hive for general persistence needs
   - Use flutter_secure_storage for sensitive data
   - Implement proper migration strategies for schema changes

2. **Image Handling**:
   - Compress images before storage or upload
   - Implement proper caching for downloaded images
   - Use background processing for image manipulation

---

## Error Handling & Logging

1. **Centralized Error Handling**:
   - Use the AppErrorHandler for consistent error handling
   - Group errors by type (network, auth, validation, etc.)
   - Log errors with proper context for debugging

2. **User-Facing Errors**:
   - Provide clear, actionable error messages
   - Implement retry mechanisms for recoverable errors
   - Hide technical details from user-facing messages

Example:
```dart
try {
  await someOperation();
} catch (e, stack) {
  final message = ErrorHandler.handleError(e, stack);
  setError(message);
  
  // Log error for debugging
  AppLogger.error('Failed during operation', e, stack);
}
```

---

## Testing Guidelines

1. **Unit Tests**:
   - Test all ViewModels, Repositories and Services
   - Mock dependencies using Mockito
   - Test both success and error paths

2. **Widget Tests**:
   - Test complex UI components
   - Verify UI state transitions
   - Use Golden Image testing for visual verification

Example Test:
```dart
void main() {
  group('YourViewModel Tests', () {
    late MockRepository mockRepository;
    late YourViewModel viewModel;
    
    setUp(() {
      mockRepository = MockRepository();
      viewModel = YourViewModel(mockRepository);
    });
    
    test('should set loading state and then success when data loads', () async {
      // Arrange
      when(mockRepository.getData()).thenAnswer((_) async => ['item1', 'item2']);
      
      // Act
      await viewModel.loadData();
      
      // Assert
      expect(viewModel.isSuccess, true);
      expect(viewModel.items.length, 2);
    });
  });
}
```

---

## Naming Conventions

1. **Files & Directories**:
   - Use `snake_case` for file and directory names
   - Group related files in feature directories
   - Name files according to their primary class or functionality

2. **Classes & Types**:
   - Use `PascalCase` for classes, enums, and type names
   - Use descriptive names that indicate purpose
   - Follow the pattern: [Feature][Type] (e.g., ImageEditorViewModel)

3. **Variables & Methods**:
   - Use `camelCase` for variables, methods, and functions
   - Prefix private members with underscore (_)
   - Use verb phrases for methods (e.g., `loadData()`, `saveImage()`)
   - Use noun phrases for properties (e.g., `items`, `currentImage`)

---

## Expected Code Quality

When generating code with GitHub Copilot, ensure:

1. **Completeness**:
   - No TODO comments or placeholder code
   - Implementations for all required methods
   - Proper error handling for all edge cases

2. **Context Awareness**:
   - Suggestions should align with nearby code style and patterns
   - Use existing project patterns and conventions
   - Reference related project components appropriately

3. **Performance Considerations**:
   - Avoid unnecessary rebuilds in widget trees
   - Implement pagination for large data sets
   - Cache expensive computations and API results

4. **Self-Documenting Code**:
   - Use clear, descriptive names
   - Add comments for complex algorithms or business rules
   - Document public APIs with proper dartdoc comments

5. **Platform Awareness**:
   - Handle platform differences consistently
   - Account for different screen sizes and orientations
   - Respect platform UI conventions (Material vs Cupertino)