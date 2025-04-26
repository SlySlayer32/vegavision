#!/bin/bash

# Run build_runner
flutter pub run build_runner build --delete-conflicting-outputs

# Format generated files
flutter format lib/**/*.g.dart