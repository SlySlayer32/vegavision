# Flutter AI Image Editor Development Rules

## Project Architecture

- **Strict MVVM Architecture**: Maintain clear separation between Models, Views, and ViewModels.
- **Repository Pattern**: All data access should go through repositories, never directly to services.
- **Dependency Injection**: Use GetIt for service locator pattern; avoid direct instantiation.

## Code Quality Standards

### Formatting & Structure

- Follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Maximum line length: 100 characters
- Use 2-space indentation
- Organize files according to established directory structure
- Keep methods small and focused (< 30 lines when possible)

### Naming Conventions

- `UpperCamelCase` for classes, enums, extensions, and type parameters
- `lowerCamelCase` for variables, methods, and parameters
- `snake_case` for files and directories
- Prefix private fields with underscore: `_privateField`
- Use descriptive names; abbreviations should be avoided

### Documentation

- All public APIs must have dartdoc comments
- Complex algorithms require detailed inline comments
- Include references to document sections when implementing design patterns

## Implementation Rules

### Models

- Models should be immutable (prefer `final` fields)
- Implement `copyWith()` method for all models
- Include proper equality checks and hashCode

### ViewModels

- Must extend `ChangeNotifier`
- All state variables must be private with public getters
- UI state should be represented by specific enums, not booleans
- Include proper error handling and status reporting
- Implement proper resource disposal in `dispose()` method

### Views

- No business logic in views
- Use `Consumer` widgets from Provider for efficient rebuilds
- Implement loading states, error states, and empty states
- All user inputs must be validated
- Support accessibility (semantic labels, sufficient contrast)

### Services

- Services should have interfaces (abstract classes)
- Implement proper error handling with specific exceptions
- Include retry logic for network operations
- Respect app lifecycle for resource-intensive operations
- Properly handle authentication and security

## Image Editing Requirements

### Camera Implementation

- Support flash modes: auto, on, off
- Support multiple resolutions
- Implement focus and exposure controls
- Handle camera permissions gracefully

### Image Processing

- Compress images before upload (target < 1MB for standard images)
- Support zoom and pan for precise editing
- Implement undo/redo capabilities for edits
- Support different marker types with visual distinction

### AI Integration

- Handle API keys securely
- Implement progress reporting for long-running operations
- Allow cancellation of processing operations
- Cache results to minimize API usage

## Improvement Tracking

### Change Documentation

All significant changes must be documented in commit messages following this format:

```
[Component]: Brief description of the change

- Detailed explanation of what was changed
- Why it was changed
- How it impacts the rest of the system

Ref: #issue_number (if applicable)
```

### Performance Tracking

- Record baseline metrics for key operations:
  - Time to capture image: ___ ms
  - Time to load editor: ___ ms
  - Time to upload image: ___ ms/KB
  - Time to process edit: ___ ms
- Regularly test and update these metrics
- Document performance improvements

### Error Tracking

- Log all errors with context
- Record common error patterns
- Update error handling based on frequency analysis

## Testing Requirements

### Unit Tests

- All repositories must have >80% test coverage
- All ViewModels must have >70% test coverage
- All utility functions must have 100% test coverage

### Widget Tests

- Test all screen transitions
- Test all user interactions
- Test error states and loading states

### Integration Tests

- Test full user flows from image capture to result
- Test offline behavior
- Test device rotation and app suspension

## Cloud Integration

### Firebase Configuration

- Maintain separate Development and Production projects
- Document all Firebase service usage and quotas
- Monitor costs and usage patterns

### Cloud Functions

- Maximum execution time: 60 seconds
- Implement proper error handling and retry
- Document all environment variables
- Include logs for key operations

## Build and Release

### Dependencies

- Review and update dependencies monthly
- Document reasons for major dependency changes
- Maintain compatibility with Flutter stable channel

### Versioning

- Follow Semantic Versioning (MAJOR.MINOR.PATCH)
- Update version and build number for each release
- Maintain a changelog with user-facing features

### Release Process

- Run all tests before release
- Validate on at least 3 different devices
- Check for Firebase configuration before build
- Verify proper API key handling

## Continuous Improvement

### Code Reviews

- All PRs require at least one reviewer
- Check for adherence to these rules
- Verify proper error handling
- Validate UI with design specs

### Refactoring

- Record technical debt in the Issues tracker
- Schedule regular refactoring sessions
- Focus on high-impact areas first

### Feature Requests

- Document all feature requests with clear scope
- Evaluate impact on existing architecture
- Consider backward compatibility

## Usage Analytics

### User Behavior Tracking

- Track key user actions:
  - Images captured
  - Edit types used
  - Processing completion rate
  - Gallery vs camera usage ratio
- Review metrics monthly
- Use data to prioritize improvements

### Error Analytics

- Track errors by type and frequency
- Prioritize fixes based on impact and occurrence
- Document error handling improvements

## Resources

### Flutter Documentation

- [Flutter Dev](https://flutter.dev/docs)
- [Pub.dev](https://pub.dev)

### Project Documentation

- Project Specification Document
- UI/UX Design Guidelines
- API Documentation

## Caching Strategy

### Local Cache

- Cache captured images (max 100MB)
- Cache edit results (max 200MB)
- Implement LRU eviction policy

### Memory Management

- Monitor and limit image cache size
- Release resources when app is in background
- Implement low-memory handling

---

**Note**: This file should be reviewed and updated quarterly to reflect evolving best practices and project requirements.
