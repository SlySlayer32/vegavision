import 'package:vegavision/core/error/error_handler.dart';
import 'package:vegavision/core/logging/logger.dart';

abstract class BaseService {
  final ErrorHandler _errorHandler = ErrorHandler();
  final Logger _logger = Logger();

  /// Log info level message
  void logInfo(String message, {String? context}) {
    _logger.info(message, context: context);
  }

  /// Log warning level message
  void logWarning(
    String message, {
    String? context,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _logger.warning(
      message,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log error level message
  void logError({
    required String message,
    dynamic error,
    StackTrace? stackTrace,
    String? context,
  }) {
    _logger.error(
      message: message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  /// Handle errors consistently across services
  Future<void> handleError(
    dynamic error,
    StackTrace stackTrace, {
    String? context,
  }) async {
    await _errorHandler.handleError(error, stackTrace, context: context);
  }

  /// Execute function with error handling
  Future<T> executeWithErrorHandling<T>(
    Future<T> Function() action,
    String context,
  ) async {
    try {
      return await action();
    } catch (e, stack) {
      await handleError(e, stack, context: context);
      rethrow;
    }
  }
}
