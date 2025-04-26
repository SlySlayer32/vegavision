import 'package:flutter/foundation.dart';
import 'package:vegavision/core/services/base_api_service.dart';

class ErrorHandler {
  static String handleError(dynamic error, [StackTrace? stackTrace]) {
    // Log error for debugging
    if (kDebugMode) {
      print('Error: $error');
      if (stackTrace != null) {
        print('StackTrace: $stackTrace');
      }
    }

    if (error is ApiException) {
      return _handleApiError(error);
    }

    // Add Firebase Crashlytics reporting here if needed

    return 'An unexpected error occurred. Please try again.';
  }

  static String _handleApiError(ApiException error) {
    switch (error.statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Unauthorized. Please log in again.';
      case 403:
        return 'Access denied. You don\'t have permission for this action.';
      case 404:
        return 'Resource not found.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        if (error.message.isNotEmpty) {
          return error.message;
        }
        return 'An error occurred. Please try again.';
    }
  }

  static bool shouldRetry(dynamic error) {
    if (error is ApiException) {
      // Retry on server errors and network issues
      return error.statusCode == null || // Network error
          error.statusCode! >= 500 || // Server error
          error.statusCode == 429; // Rate limit
    }
    return false;
  }

  static Duration getRetryDelay(int retryCount) {
    // Exponential backoff with jitter
    final baseDelay = Duration(milliseconds: 1000 * (1 << retryCount));
    final jitter = Duration(
      milliseconds: (baseDelay.inMilliseconds * 0.1).round(),
    );
    return baseDelay + jitter;
  }
}
