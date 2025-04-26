import 'package:vegavision/core/error/error_handler.dart';
import 'package:vegavision/core/logging/logger.dart';

abstract class BaseRepository {
  final ErrorHandler _errorHandler = ErrorHandler();
  final Logger _logger = Logger();

  /// Log repository operations
  void logOperation(
    String operation, {
    String? context,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    if (error != null) {
      _logger.error(
        message: 'Repository operation failed: $operation',
        error: error,
        stackTrace: stackTrace,
        context: context,
      );
    } else {
      _logger.info('Repository operation: $operation', context: context);
    }
  }

  /// Handle repository errors
  Future<void> handleError(
    dynamic error,
    StackTrace stackTrace, {
    String? context,
  }) async {
    await _errorHandler.handleError(error, stackTrace, context: context);
  }

  /// Execute repository operation with error handling
  Future<T> executeOperation<T>(
    Future<T> Function() operation,
    String operationName,
  ) async {
    try {
      final result = await operation();
      logOperation('$operationName succeeded');
      return result;
    } catch (e, stack) {
      logOperation('$operationName failed', error: e, stackTrace: stack);
      await handleError(e, stack, context: operationName);
      rethrow;
    }
  }
}
