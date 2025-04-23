# vegavision

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Development Setup

### Pre-commit Hooks and Lint-staged

This project uses pre-commit hooks with lint-staged to ensure code quality before pushing to GitHub. Follow these steps to set up:

1. Install dependencies:
```bash
flutter pub get
dart pub add --dev lint_staged husky
```

2. Initialize husky:
```bash
dart run husky install
```

3. Create a pre-commit hook:
```bash
dart run husky set .husky/pre-commit "dart run lint_staged"
```

4. Add lint-staged configuration to your `pubspec.yaml`:
```yaml
lint_staged:
  "lib/**.dart":
    - dart format
    - dart analyze
    - dart fix --apply
    - dart test
```

Now, whenever you try to commit changes:
- Changed Dart files will be automatically formatted
- Static analysis will be run
- Common issues will be auto-fixed
- Tests will be executed

If any of these steps fail, the commit will be aborted, allowing you to fix the issues before pushing.

### Skipping Pre-commit Hooks

In rare cases where you need to bypass the pre-commit hooks, you can use:
```bash
git commit -m "your message" --no-verify
```

**Note**: Use this sparingly and only when absolutely necessary.
