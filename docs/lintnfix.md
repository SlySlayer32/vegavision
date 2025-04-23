1. Setup Dart Analysis Options
First, create or update your analysis_options.yaml file:

include: package:flutter_lints/flutter_lints.yaml

# linter

  rules:
    # Style rules from Dart Style Guide
    - always_declare_return_types
    - always_use_package_imports
    - avoid_empty_else
    - avoid_print
    - avoid_redundant_argument_values
    - avoid_types_as_parameter_names
    - avoid_web_libraries_in_flutter
    - camel_case_types
    - cancel_subscriptions
    - close_sinks
    - comment_references
    - constant_identifier_names
    - control_flow_in_finally
    - empty_catches
    - empty_constructor_bodies
    - empty_statements
    - hash_and_equals
    - implementation_imports
    - library_names
    - library_prefixes
    - lines_longer_than_80_chars
    - no_duplicate_case_values
    - null_closures
    - prefer_collection_literals
    - prefer_conditional_assignment
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_final_fields
    - prefer_final_locals
    - prefer_is_empty
    - prefer_is_not_empty
    - prefer_single_quotes
    - sort_child_properties_last
    - sort_constructors_first
    - sort_unnamed_constructors_first
    - unnecessary_brace_in_string_interps
    - unnecessary_const
    - unnecessary_new
    - unnecessary_null_in_if_null_operators
    - unnecessary_this
    - unrelated_type_equality_checks
    - use_key_in_widget_constructors
    - use_rethrow_when_possible
    - valid_regexps

analyzer:
  errors:
    # Treat specific issues as errors, warnings, or info
    missing_required_param: error
    missing_return: error
    todo: info
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  language:
    strict-casts: true
    strict-raw-types: true

analysis_options.yaml
2. Set Up Git Hooks with Husky
Create a pre-commit hook using Husky to automatically lint and format code:

Add the required dependencies:
flutter pub add --dev husky lint_staged

Initialize Husky:
dart run husky install

Create a .husky/pre-commit file:

# !/bin/sh

. "$(dirname "$0")/_/husky.sh"

dart run lint_staged

pre-commit
Make it executable:
chmod +x .husky/pre-commit

Configure lint-staged in pubspec.yaml:

# Add this section to your pubspec.yaml

lint_staged:
  "lib/**.dart":
    - dart format --line-length=100
    - dart fix --apply
    - dart analyze

pubspec.yaml
3. Setup VSCode Integration
Create a .vscode/settings.json file to enable format-on-save and other helpful features:

{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true,
    "source.organizeImports": true
  },
  "dart.lineLength": 100,
  "dart.previewFlutterUiGuides": true,
  "dart.previewFlutterUiGuidesCustomTracking": true,
  "dart.showInspectorNotificationsForWidgetErrors": true,
  "dart.analysisExcludedFolders": [
    ".dart_tool",
    ".pub",
    "build",
    "ios",
    "android"
  ]
}

settings.json
4. Continuous Integration Setup
Add a GitHub Actions workflow for continuous linting:

name: Lint and Analyze

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.0'
          channel: 'stable'
      - run: flutter pub get
      - name: Verify formatting
        run: dart format --output=none --set-exit-if-changed .
      - name: Analyze project source
        run: flutter analyze
      - name: Run tests
        run: flutter test

lint.yml
5. Custom Lint Rules Script
Create a script to check for project-specific rules that aren't covered by standard linters:

import 'dart:io';

void main() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));
  
  int errors = 0;
  
  for (final file in files) {
    final content = file.readAsStringSync();

    // Check for direct service instantiation (violates DI rule)
    if (RegExp(r'new\s+\w+Service\(').hasMatch(content)) {
      print('${file.path}: Direct service instantiation found. Use GetIt instead.');
      errors++;
    }
    
    // Check for business logic in view files
    if (file.path.contains('/views/') && 
        (content.contains('Repository(') || content.contains('Service('))) {
      print('${file.path}: Business logic found in view file. Move to ViewModel.');
      errors++;
    }
    
    // Check for missing documentation on public APIs
    if (!file.path.contains('_test.dart')) {
      final publicApis = RegExp(r'(class|enum|extension|typedef)\s+\w+').allMatches(content);
      for (final match in publicApis) {
        final linesBefore = content.substring(0, match.start).split('\n');
        if (linesBefore.last.trim().isEmpty && 
            (linesBefore.length < 2 || !linesBefore[linesBefore.length - 2].trim().startsWith('///'))) {
          print('${file.path}: Missing documentation for ${match.group(0)}');
          errors++;
        }
      }
    }
  }
  
  if (errors > 0) {
    print('$errors custom lint errors found');
    exit(1);
  }
  
  print('No custom lint errors found');
}

custom_lint.dart
Add this to your pre-commit hook:

dart run scripts/custom_lint.dart

6. Add a Project-Wide Format Command
Add a script in your pubspec.yaml to easily format the entire project:

# Add to your pubspec.yaml scripts section

scripts:
  format: dart format --line-length=100 lib test
  fix: dart fix --apply
  analyze: flutter analyze
  lint: dart run scripts/custom_lint.dart
  check_all: flutter pub run scripts:format && flutter pub run scripts:fix && flutter pub run scripts:analyze && flutter pub run scripts:lint

Copy

pubspec.yaml
7. Documentation for Team Members
Create a document explaining the linting setup:

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
