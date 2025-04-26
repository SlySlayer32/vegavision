class AppConstants {
  // App Info
  static const String appName = 'VegaVision';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String userPrefsKey = 'user_preferences';
  static const String themeKey = 'app_theme';
  static const String languageKey = 'app_language';

  // API Endpoints
  static const String baseApiUrl = 'https://api.vegavision.com';
  static const String geminiApiUrl =
      'https://generativelanguage.googleapis.com';

  // Feature Flags
  static const bool enableImageCompression = true;
  static const bool enableAutoSave = true;
  static const bool enableCloudBackup = true;

  // Image Settings
  static const int maxImageWidth = 2048;
  static const int maxImageHeight = 2048;
  static const int imageQuality = 85;
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png'];

  // Timeouts
  static const int apiTimeoutSeconds = 30;
  static const int uploadTimeoutSeconds = 60;
  static const int processingTimeoutSeconds = 300;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 16.0;
  static const double defaultRadius = 8.0;
  static const double defaultIconSize = 24.0;
  static const double defaultButtonHeight = 48.0;

  // Animation Durations
  static const int shortAnimationDuration = 200;
  static const int mediumAnimationDuration = 350;
  static const int longAnimationDuration = 500;

  // Error Messages
  static const String generalError = 'Something went wrong. Please try again.';
  static const String networkError =
      'Network error. Please check your connection.';
  static const String timeoutError = 'Request timed out. Please try again.';
  static const String uploadError = 'Failed to upload image. Please try again.';
  static const String processingError =
      'Failed to process image. Please try again.';

  // Success Messages
  static const String uploadSuccess = 'Image uploaded successfully!';
  static const String processingSuccess = 'Image processed successfully!';
  static const String saveSuccess = 'Changes saved successfully!';

  // Validation
  static const int minInstructionLength = 10;
  static const int maxInstructionLength = 500;
  static const int minMarkers = 1;
  static const int maxMarkers = 10;

  // Cache Settings
  static const int maxCacheSize = 100 * 1024 * 1024; // 100 MB
  static const int maxCacheAge = 7 * 24 * 60 * 60; // 7 days in seconds
}
