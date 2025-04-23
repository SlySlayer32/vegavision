# VegaVision Linting Guide

This project uses automated linting and formatting to maintain code quality standards as defined in our Development Rules.

## Automatic Checks

The following checks run automatically when you commit code:

1. Code formatting (line length: 100)
2. Static analysis
3. Custom lint rules specific to our architecture
4. Import sorting

## IDE Setup

For the best development experience:

1. Use VSCode with the Dart and Flutter extensions
2. Enable format-on-save in your editor
3. Use the provided `.vscode/settings.json` configuration

## Manual Commands

You can run these commands manually:

- `flutter pub run scripts:format` - Format all code
- `flutter pub run scripts:fix` - Apply automated fixes
- `flutter pub run scripts:analyze` - Run static analysis
- `flutter pub run scripts:lint` - Run custom lint rules
- `flutter pub run scripts:check_all` - Run all checks

## Common Issues

If you encounter linting errors, refer to our Development Rules document for guidance on:

- MVVM architecture separation
- Naming conventions
- Documentation requirements
- Dependency injection patterns
