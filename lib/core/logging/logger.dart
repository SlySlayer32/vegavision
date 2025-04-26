import 'package:flutter/foundation.dart';

class Logger {
  static final Logger _instance = Logger._internal();
  factory Logger() => _instance;
  Logger._internal();

  void error({
    required String message,
    dynamic error,
    StackTrace? stackTrace,
    String? context,
  }) {
    if (kDebugMode) {
      print('ERROR: $message');
      if (error != null) print('Error details: $error');
      if (stackTrace != null) print('Stack trace: $stackTrace');
      if (context != null) print('Context: $context');
    }
  }

  void info(String message) {
    if (kDebugMode) {
      print('INFO: $message');
    }
  }

  void warning(String message) {
    if (kDebugMode) {
      print('WARNING: $message');
    }
  }
}
