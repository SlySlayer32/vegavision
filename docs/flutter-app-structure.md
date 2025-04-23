# Flutter AI Image Editor - Application Structure

## Directory Structure

```
lib/
  |- main.dart               # App entry point
  |- app.dart                # App configuration
  |- models/                 # Data models
  |   |- image_model.dart
  |   |- edit_request.dart
  |   |- edit_result.dart
  |
  |- views/                  # UI components
  |   |- image_capture/
  |   |   |- image_capture_view.dart
  |   |   |- components/
  |   |
  |   |- image_editor/
  |   |   |- image_editor_view.dart
  |   |   |- components/
  |   |       |- marker_canvas.dart
  |   |       |- instruction_input.dart
  |   |
  |   |- result/
  |       |- result_view.dart
  |
  |- viewmodels/             # Business logic
  |   |- image_capture_viewmodel.dart
  |   |- image_editor_viewmodel.dart
  |   |- result_viewmodel.dart
  |
  |- services/               # External service integrations
  |   |- camera_service.dart
  |   |- storage_service.dart
  |   |- vision_service.dart
  |   |- gemini_service.dart
  |
  |- repositories/           # Data management
  |   |- image_repository.dart
  |   |- edit_repository.dart
  |
  |- core/                   # Core utilities and helpers
      |- di/                 # Dependency injection
      |- utils/              # Utility functions
      |- constants/          # App constants
```

## Application Flow

1. **Image Capture**
   - User captures an image using the device camera
   - Image is saved locally

2. **Image Editing**
   - User adds markers to objects in the image
   - User enters instructions for editing (e.g., "remove tree")
   - Edit request is created and image is uploaded to cloud storage

3. **Processing**
   - Cloud Function processes the image (triggered by upload)
   - Vision API analyzes the image
   - Gemini API performs the requested edit
   - Result is stored in cloud storage

4. **Result Display**
   - User views the edited image
   - User can accept the result or request specific improvements

## Key Components

### Models

- `ImageModel`: Represents captured images
- `EditRequest`: Contains editing instructions and marker positions
- `EditResult`: Stores processing results

### ViewModels

- `ImageCaptureViewModel`: Manages camera and image capture
- `ImageEditorViewModel`: Handles marker placement and edit instructions
- `ResultViewModel`: Processes edit requests and displays results

### Services

- `CameraService`: Interfaces with device camera
- `StorageService`: Handles cloud storage operations
- `VisionService`: Interfaces with Google Cloud Vision API
- `GeminiService`: Interfaces with Google Gemini API

### Repositories

- `ImageRepository`: Manages image data
- `EditRepository`: Manages edit requests and results

This architecture follows the MVVM pattern with clean separation of concerns, making the application maintainable, testable, and scalable.
