import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../bug_fixing/auto_bug_fixer.dart';
import '../logging/logger.dart';

class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  final _logger = Logger();
  final _bugFixer = AutoBugFixer();

  Future<void> handleError(
    dynamic error,
    StackTrace stackTrace, {
    String? context,
    BuildContext? buildContext,
  }) async {
    _logger.error(
      message: 'Error caught by ErrorHandler',
      error: error,
      stackTrace: stackTrace,
      context: context,
    );

    // Attempt automatic fix
    final fixed = await _bugFixer.attemptFix(
      error,
      stackTrace,
      context: context,
    );

    if (!fixed && buildContext != null && buildContext.mounted) {
      // Show error to user if we couldn't fix it
      ScaffoldMessenger.of(buildContext).showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static Widget buildErrorWidget(FlutterErrorDetails details) {
    return Center(
      child: Card(
        color: Colors.red[100],
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 50),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: TextStyle(color: Colors.red[900], fontSize: 16),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 8),
                Text(
                  details.exception.toString(),
                  style: TextStyle(color: Colors.red[700], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
