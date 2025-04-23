# Custom Instructions for Flutter AI Image Editor

## Project Structure - Working Files and Folders

### Core Application Code
- `lib/` - Main Flutter application code
  - `lib/models/` - Data models (immutable with copyWith methods)
  - `lib/views/` - UI components and screens
  - `lib/viewmodels/` - Business logic classes extending ChangeNotifier
  - `lib/repositories/` - Data access layer implementing repository pattern
  - `lib/services/` - Core functionality implementations
  - `lib/utils/` - Helper functions and extensions
  - `lib/widgets/` - Reusable UI components
  - `lib/constants/` - App-wide constants and configuration
  - `lib/themes/` - Styling and theming
  - `lib/navigation/` - Routing and navigation
  - `lib/localization/` - Internationalization resources

### Configuration and Assets
- `assets/` - Static resources
  - `assets/images/` - Image resources
  - `assets/icons/` - Icon assets
  - `assets/fonts/` - Custom fonts
  - `assets/animations/` - Lottie or other animation files
- `config/` - Environment-specific configuration

### Testing
- `test/` - Unit and widget tests
  - `test/unit/` - Unit tests for business logic
  - `test/widget/` - Widget tests for UI components
  - `test/integration/` - Integration tests
  - `test/mocks/` - Mock classes for testing

### Documentation
- `docs/` - Project documentation
  - `docs/api/` - API documentation
  - `docs/architecture/` - Architecture diagrams and explanations

### Build and Platform-specific
- `android/` - Android-specific code and configuration
- `ios/` - iOS-specific code and configuration
- `web/` - Web platform configuration (if applicable)
- `windows/` - Windows platform configuration (if applicable)
- `macos/` - macOS platform configuration (if applicable)
- `linux/` - Linux platform configuration (if applicable)

### CI/CD and Tools
- `.github/` - GitHub workflows and templates
- `tools/` - Development and build scripts

## Flutter Best Practices
- **Architecture**: Follow strict MVVM with clear separation of concerns
- **State Management**: Use ChangeNotifier with Provider pattern
  - Keep state variables private with public getters
  - Use Consumer widgets for efficient rebuilds
  
- **Code Style**:
  - 2-space indentation, 100 character line limit
  - UpperCamelCase for classes, lowerCamelCase for variables/methods
  - snake_case for files and directories
  - Prefix private fields with underscore: `_privateField`
  
- **Widget Structure**:
  - Implement loading, error, and empty states for all screens
  - Support accessibility with semantic labels
  - Handle device rotation appropriately
  
- **Performance**:
  - Compress images before upload (target < 1MB)
  - Implement proper caching strategy (LRU eviction policy)
  - Release resources when app is in background
  
- **Testing**:
  - Write unit tests for repositories (>80% coverage)
  - Write unit tests for ViewModels (>70% coverage)
  - Include widget tests for all user interactions

## Image Processing Requirements
- Support camera controls (flash, focus, exposure)
- Implement zoom and pan for editing
- Support undo/redo capabilities
- Handle AI integration with progress reporting

## Dependency Management
- Use GetIt for dependency injection
- Avoid direct instantiation of services
- Follow proper resource disposal patterns
