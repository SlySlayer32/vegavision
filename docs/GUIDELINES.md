# VegaVision Development Guidelines

A comprehensive guide for maintaining consistent code quality and architecture in the VegaVision project.

## Architecture Overview

### MVVM Implementation

- **Models**: Data structures and business logic
  ```dart
  class ImageModel extends BaseModel {
    final String id;
    final String path;
    final ImageStatus status;
    // ...
  }
  ```

- **Views**: UI components only
  ```dart
  class ImageEditorView extends BaseView<ImageEditorViewModel> {
    @override
    Widget buildView(BuildContext context, ImageEditorViewModel viewModel) {
      // UI implementation only
    }
  }
  ```

- **ViewModels**: Business logic and state management
  ```dart
  class ImageEditorViewModel extends BaseViewModel {
    final ImageService _imageService;
    // State management and business logic
  }
  ```

### Dependency Injection

```dart
// Register services
getIt.registerSingleton<ImageService>(ImageService());

// Use in components
final imageService = getIt<ImageService>();
```

## Code Organization

### Feature-Based Structure
```
lib/
├── core/           # Core functionality
├── features/       # Feature modules
│   ├── image_capture/
│   ├── image_editor/
│   └── result/
└── shared/        # Shared components
```

### Import Conventions
```dart
// ✓ Correct
import 'package:vegavision/features/image_editor/models/edit_request.dart';

// ✗ Incorrect
import '../../models/edit_request.dart';
```

## Coding Standards

### Widget Construction
```dart
// ✓ Correct
@immutable
class CustomButton extends StatelessWidget {
  const CustomButton({
    required this.onPressed,
    required this.label,
    this.icon,
    super.key,
  });

  final VoidCallback onPressed;
  final String label;
  final IconData? icon;
}

// ✗ Incorrect
class CustomButton extends StatelessWidget {
  CustomButton(this.onPressed, this.label, [this.icon]); // No named parameters
}
```

### Error Handling
```dart
// ✓ Correct
Future<void> processImage() async {
  try {
    setLoading(true);
    await _imageService.process();
  } on ImageProcessingException catch (e, stack) {
    await handleError(e, stack, context: 'ImageEditor.processImage');
  } finally {
    setLoading(false);
  }
}

// ✗ Incorrect
Future<void> processImage() async {
  await _imageService.process(); // No error handling
}
```

### State Management
```dart
// ✓ Correct
class ImageEditorViewModel extends BaseViewModel {
  ImageModel? _currentImage;
  ImageModel? get currentImage => _currentImage;

  Future<void> loadImage(String id) async {
    setLoading(true);
    try {
      _currentImage = await _imageService.getImage(id);
      notifyListeners();
    } catch (e, stack) {
      await handleError(e, stack);
    } finally {
      setLoading(false);
    }
  }
}
```

## Platform-Specific Code

### Implementation
```dart
// ✓ Correct
class ImagePicker {
  Future<File?> pickImage() async {
    if (Platform.isIOS) {
      return await _pickImageIOS();
    } else if (Platform.isAndroid) {
      return await _pickImageAndroid();
    }
    throw UnsupportedPlatformException();
  }
}
```

### UI Adaptation
```dart
// ✓ Correct
Widget buildPlatformSpecificButton(BuildContext context) {
  return Platform.isIOS
      ? CupertinoButton(/* ... */)
      : ElevatedButton(/* ... */);
}
```

## Testing Requirements

### Unit Tests
```dart
// ✓ Correct
void main() {
  group('ImageEditorViewModel', () {
    late ImageEditorViewModel viewModel;
    late MockImageService mockImageService;

    setUp(() {
      mockImageService = MockImageService();
      viewModel = ImageEditorViewModel(mockImageService);
    });

    test('should handle image loading success', () async {
      // Test implementation
    });
  });
}
```

### Widget Tests
```dart
// ✓ Correct
testWidgets('ImageEditorView shows loading indicator', (tester) async {
  await tester.pumpWidget(const MaterialApp(
    home: ImageEditorView(),
  ));
  await tester.pump();
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

## Performance Guidelines

### Image Optimization
```dart
// ✓ Correct
Future<File> optimizeImage(File file) async {
  final compressed = await FlutterImageCompress.compressWithFile(
    file.absolute.path,
    minWidth: 1024,
    minHeight: 1024,
    quality: 85,
  );
  return compressed;
}
```

### List Optimization
```dart
// ✓ Correct
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(item: items[index]),
);

// ✗ Incorrect
ListView(
  children: items.map((item) => ItemWidget(item: item)).toList(),
);
```

## Firebase Integration

### Initialization
```dart
// ✓ Correct
Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Additional initialization
  } catch (e, stack) {
    await FirebaseErrorHandler.handleError(e, stack);
  }
}
```

### Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```