import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic error;
  final StackTrace? stackTrace;

  ApiException(this.message, {this.statusCode, this.error, this.stackTrace});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

/// Base class for all API services with retry logic and error handling
abstract class BaseApiService {
  final Duration timeout;
  final int maxRetries;

  BaseApiService({
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
  });

  /// Execute API request with retry logic and error handling
  Future<T> executeRequest<T>(Future<T> Function() request) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        return await request().timeout(timeout);
      } on TimeoutException {
        attempts++;
        if (attempts >= maxRetries) {
          throw ApiException('Request timed out after $maxRetries attempts');
        }
        await Future.delayed(
          Duration(seconds: attempts),
        ); // Exponential backoff
      } on SocketException catch (e) {
        throw ApiException('No internet connection', error: e);
      } on http.ClientException catch (e) {
        throw ApiException('Network error', error: e);
      } catch (e, stack) {
        throw ApiException('Unexpected error', error: e, stackTrace: stack);
      }
    }

    throw ApiException('Max retries exceeded');
  }

  /// Validate response and handle common error cases
  void validateResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    switch (response.statusCode) {
      case 400:
        throw ApiException('Bad request', statusCode: response.statusCode);
      case 401:
        throw ApiException('Unauthorized', statusCode: response.statusCode);
      case 403:
        throw ApiException('Forbidden', statusCode: response.statusCode);
      case 404:
        throw ApiException('Not found', statusCode: response.statusCode);
      case 429:
        throw ApiException(
          'Too many requests',
          statusCode: response.statusCode,
        );
      case 500:
        throw ApiException('Server error', statusCode: response.statusCode);
      default:
        throw ApiException(
          'Request failed with status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
    }
  }

  /// Handle rate limiting
  Future<void> handleRateLimit(http.Response response) async {
    final retryAfter = response.headers['retry-after'];
    if (retryAfter != null) {
      final seconds = int.tryParse(retryAfter) ?? 5;
      await Future.delayed(Duration(seconds: seconds));
    }
  }
}
