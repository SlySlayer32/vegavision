# Copilot Instructions for VegaVision Project

This document provides strict guidelines to ensure high-quality code generation from GitHub Copilot. These instructions align with Flutter best practices, the MVVM architecture, and the specific requirements of the VegaVision project.

---

## General Rules
1. Adhere to **Flutter's best practices** and **Effective Dart principles**.
2. Enforce **MVVM architecture**:
   - Models must only represent data structures.
   - ViewModels should handle business logic and state management.
   - Views should only handle UI rendering and user interactions.
3. Generate **consistent and production-ready code**:
   - Avoid placeholders like `TODO`, `example`, or incomplete methods.
   - Do not produce code with missing implementations or vague comments.
4. Use **Dart null safety** features in all generated code.

---

## Project-Specific Guidelines

### Architecture & Dependency Management
- Follow MVVM architecture strictly:
  - Never reference UI elements in `Model` or `Repository` classes.
  - Use `GetIt` for dependency injection and service location.
  - Organize code by **feature**, not by type.
- Ensure imports follow consistent paths:
  - Example: `package:vegavision/views/...`.

### Flutter Best Practices
- Use **named parameters** for all widget constructors.
- Always prefer `const` constructors when possible.
- Extract reusable widgets into separate files.
- Keep widget methods under **30 lines** for readability.
- Implement proper `dispose` methods for all stateful widgets to prevent memory leaks.
- Avoid direct instantiation of services; always use `GetIt`.

### Platform-Specific Code
- Implement separate platform-specific functionality for cameras and storage.
- Use `if (Platform.isIOS)` or `if (Platform.isAndroid)` checks for platform-specific logic.
- Ensure proper permissions handling for both iOS and Android.
- Use Material Design for Android and Cupertino for iOS.
- Handle safe areas and device-specific notches consistently.
- Implement adaptive screen sizing for different devices.

---

## Error Handling
- Wrap all asynchronous operations in `try/catch` blocks.
- Log errors with contextual information.
- Provide user-friendly error messages in the UI.
- Use **typed exceptions** for specific error cases.
- Never silently catch exceptions without handling them.
- Handle network and permission errors gracefully.

---

## Firebase Integration
- Use Firebase securely:
  - Do not include Firebase secrets in version control.
  - Ensure Firebase configuration files are properly generated and stored.
- Initialize Firebase before using any Firebase services.
- Handle Firebase errors and authentication failures explicitly.
- Apply Firebase security rules to protect user data.
- Test Firebase functionality in both online and offline modes.

---

## Testing Guidelines
- Write unit tests for all repositories and services.
- Add widget tests for complex UI components.
- Use **MockDatabase** and **MockServices** for testing.
- Test both happy paths and error handling scenarios.
- Aim for at least **70% code coverage**.
- Test platform-specific features thoroughly.

---

## Performance Optimization
- Use `const` widgets to minimize rebuilds.
- Optimize image handling with compression and caching.
- Use lazy loading for list views.
- Employ background processing for heavy operations.
- Profile and optimize main-thread operations.
- Use Hive for efficient local storage.
- Cache Firebase calls where appropriate.

---

## Naming Conventions
- Use **PascalCase** for classes and enum types.
- Use **camelCase** for variables, methods, and functions.
- Use **snake_case** for file names.
- Use **ALL_CAPS** for constants.
- Prefix private variables with an underscore (`_`).
- Name files according to their primary class or functionality.

---

## Code Generation Expectations for GitHub Copilot
To ensure high-quality suggestions:
1. **Context Awareness**: Suggestions must align with the MVVM architecture and Flutter best practices.
2. **Avoid Placeholder Code**:
   - Do not generate incomplete code or vague comments.
   - Avoid placeholders like `TODO` or `example`.
3. **Strict Adherence to Guidelines**:
   - Follow project-specific rules for architecture, dependency management, and error handling.
   - Never produce code that contradicts the instructions in this document.
4. **Clean and Readable Code**:
   - Suggestions must follow proper formatting and naming conventions.
   - Avoid overly complex or lengthy methods.
5. **Comprehensive Testing**:
   - Include test cases where applicable.
   - Ensure all edge cases are handled.

