// services/gemini_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

// Custom exceptions for Gemini service
class GeminiServiceException implements Exception {

  GeminiServiceException(this.message, {this.code, this.originalError, this.statusCode});
  final String message;
  final String? code;
  final dynamic originalError;
  final int? statusCode;

  @override
  String toString() => 'GeminiServiceException($code): $message';
}

// Quality presets for image editing
enum ImageEditQuality {
  fast, // Quicker processing, lower quality
  balanced, // Balance between speed and quality
  premium, // Higher quality, slower processing
}

// Image editing models
enum ImageEditModel {
  geminiPro, // For text-based instructions
  geminiVision, // For visual editing with instructions
}

// Image editing parameters
class ImageEditOptions {

  ImageEditOptions({
    this.model = ImageEditModel.geminiVision,
    this.quality = ImageEditQuality.balanced,
    this.creativityLevel = 0.7,
    this.outputFormat,
    this.additionalParams,
  });
  final ImageEditModel model;
  final ImageEditQuality quality;
  final double creativityLevel; // 0.0 to 1.0, higher is more creative
  final String? outputFormat; // 'jpeg', 'png', etc.
  final Map<String, dynamic>? additionalParams;

  // Convert to API request format
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'model': _modelToString(model),
      'quality': _qualityToString(quality),
      'temperature': creativityLevel.clamp(0.0, 1.0),
    };

    if (outputFormat != null) {
      json['outputFormat'] = outputFormat;
    }

    if (additionalParams != null) {
      json.addAll(additionalParams!);
    }

    return json;
  }

  // Map enum to API string
  String _modelToString(ImageEditModel model) {
    switch (model) {
      case ImageEditModel.geminiPro:
        return 'gemini-pro';
      case ImageEditModel.geminiVision:
        return 'gemini-pro-vision';
    }
  }

  // Map enum to API string
  String _qualityToString(ImageEditQuality quality) {
    switch (quality) {
      case ImageEditQuality.fast:
        return 'standard';
      case ImageEditQuality.balanced:
        return 'balanced';
      case ImageEditQuality.premium:
        return 'premium';
    }
  }
}

// Result of an image edit operation
class ImageEditResult {

  ImageEditResult({
    required this.localPath,
    required this.metadata,
    required this.processingTimeMs,
  });
  final String localPath;
  final Map<String, dynamic> metadata;
  final double processingTimeMs;
}

abstract class GeminiService {
  Future<String?> editImage(
    String cloudPath,
    String instruction,
    List<Map<String, double>> markers, {
    ImageEditOptions? options,
    int maxRetries = 3,
  });

  Future<ImageEditResult?> editImageFile(
    File imageFile,
    String instruction,
    List<Map<String, double>> markers, {
    ImageEditOptions? options,
    int maxRetries = 3,
  });

  Future<List<String>> generateImageVariations(
    String cloudPath,
    String instruction, {
    int count = 3,
    ImageEditOptions? options,
    int maxRetries = 3,
  });
}

class GeminiServiceImpl implements GeminiService {
  // TODO: Replace hardcoded API key with secure storage or environment variable
  final String _apiKey = 'YOUR_GEMINI_API_KEY';

  static const String _apiKeyKey = 'gemini_api_key';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final http.Client _client = http.Client();
  final int _baseDelayMs = 500;

  // Default options
  final ImageEditOptions _defaultOptions = ImageEditOptions();

  // Get API key from secure storage
  Future<String> _getApiKey() async {
    String? apiKey = await _secureStorage.read(key: _apiKeyKey);

    if (apiKey.isEmpty) {
      // Load from assets as fallback (during development)
      try {
        final String configString = await rootBundle.loadString('assets/config.json');
        final Map<String, dynamic> config = jsonDecode(configString);
        apiKey = config['gemini_api_key'] as String?;
      } catch (e) {
        print('Failed to load API key from assets: $e');
      }
    }

    if (apiKey == null || apiKey.isEmpty) {
      throw GeminiServiceException(
        'API key not found. Please set it using setApiKey().',
        code: 'missing-api-key',
      );
    }

    return apiKey;
  }

  // Set API key in secure storage
  Future<void> setApiKey(String apiKey) async {
    await _secureStorage.write(key: _apiKeyKey, value: apiKey);
  }

  @override
  Future<String?> editImage(
    String cloudPath,
    String instruction,
    List<Map<String, double>> markers, {
    ImageEditOptions? options,
    int maxRetries = 3,
  }) async {
    options ??= _defaultOptions;

    try {
      final String downloadUrl = 'https://storage.googleapis.com/$cloudPath';

      // Get API key
      final String apiKey = await _getApiKey();

      // Determine which model to use
      final String modelName =
          options.model == ImageEditModel.geminiPro ? 'gemini-pro' : 'gemini-pro-vision';

      final String url = '$_baseUrl/models/$modelName:generateContent?key=$apiKey';

      // Create a prompt that includes the instruction and markers
      final String promptText = _createEditPrompt(instruction, markers);

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'contents': [
          {
            'parts': [
              {'text': promptText},
              {
                'inlineData': {'mimeType': 'image/jpeg', 'data': downloadUrl},
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': options.creativityLevel,
          'topP': 0.95,
          'topK': 40,
          'maxOutputTokens': 1024,
        },
      };

      // Make API call with retry logic
      final response = await _retryOperation(
        () => _client.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        ),
        maxRetries: maxRetries,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // In a real implementation, this would parse the response to get the edited image
        // For now, we'll save a mock result to a local file
        final Directory tempDir = await getTemporaryDirectory();
        final String tempPath =
            '${tempDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.jpg';

        // Create a mock file (in a real implementation, this would be the actual result)
        // In a real implementation, this would download the generated image from the response
        await File(tempPath).writeAsString('Mock image content');

        // Return the local path to the result
        return tempPath;
      } else {
        throw GeminiServiceException(
          'Failed to edit image (status: ${response.statusCode}): ${response.body}',
          code: 'api-error',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is GeminiServiceException) {
        rethrow;
      }

      throw GeminiServiceException('Failed to edit image: $e', originalError: e);
    }
  }

  @override
  Future<ImageEditResult?> editImageFile(
    File imageFile,
    String instruction,
    List<Map<String, double>> markers, {
    ImageEditOptions? options,
    int maxRetries = 3,
  }) async {
    options ??= _defaultOptions;
    final Stopwatch stopwatch = Stopwatch()..start();

    try {
      // Read file as base64
      final List<int> imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      // Get API key
      final String apiKey = await _getApiKey();

      // Determine which model to use
      final String modelName =
          options.model == ImageEditModel.geminiPro ? 'gemini-pro' : 'gemini-pro-vision';

      final String url = '$_baseUrl/models/$modelName:generateContent?key=$apiKey';

      // Create a prompt that includes the instruction and markers
      final String promptText = _createEditPrompt(instruction, markers);

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'contents': [
          {
            'parts': [
              {'text': promptText},
              {
                'inlineData': {'mimeType': 'image/jpeg', 'data': base64Image},
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': options.creativityLevel,
          'topP': 0.95,
          'topK': 40,
          'maxOutputTokens': 1024,
        },
      };

      // Make API call with retry logic
      final response = await _retryOperation(
        () => _client.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        ),
        maxRetries: maxRetries,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Stop the timer
        stopwatch.stop();

        // In a real implementation, this would parse the response to get the edited image
        // For now, we'll save a mock result to a local file
        final Directory tempDir = await getTemporaryDirectory();
        final String tempPath =
            '${tempDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.jpg';

        // Create a mock file (in a real implementation, this would be the actual result)
        // In a real implementation, this would download the generated image from the response
        await File(tempPath).writeAsString('Mock image content');

        // Return the result
        return ImageEditResult(
          localPath: tempPath,
          metadata: jsonResponse,
          processingTimeMs: stopwatch.elapsedMilliseconds.toDouble(),
        );
      } else {
        throw GeminiServiceException(
          'Failed to edit image file (status: ${response.statusCode}): ${response.body}',
          code: 'api-error',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is GeminiServiceException) {
        rethrow;
      }

      throw GeminiServiceException('Failed to edit image file: $e', originalError: e);
    } finally {
      if (stopwatch.isRunning) {
        stopwatch.stop();
      }
    }
  }

  @override
  Future<List<String>> generateImageVariations(
    String cloudPath,
    String instruction, {
    int count = 3,
    ImageEditOptions? options,
    int maxRetries = 3,
  }) async {
    options ??= _defaultOptions;

    try {
      final String downloadUrl = 'https://storage.googleapis.com/$cloudPath';

      // Get API key
      final String apiKey = await _getApiKey();

      // Determine which model to use
      final String modelName =
          options.model == ImageEditModel.geminiPro ? 'gemini-pro' : 'gemini-pro-vision';

      final String url = '$_baseUrl/models/$modelName:generateContent?key=$apiKey';

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text':
                    'Generate $count variations of this image with the following instruction: $instruction',
              },
              {
                'inlineData': {'mimeType': 'image/jpeg', 'data': downloadUrl},
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': options.creativityLevel,
          'topP': 0.95,
          'topK': 40,
          'maxOutputTokens': 1024,
          'candidateCount': count,
        },
      };

      // Make API call with retry logic
      final response = await _retryOperation(
        () => _client.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        ),
        maxRetries: maxRetries,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // In a real implementation, this would parse the response to get the generated images
        // For now, we'll create mock results
        final List<String> results = [];
        final Directory tempDir = await getTemporaryDirectory();

        for (int i = 0; i < count; i++) {
          final String tempPath =
              '${tempDir.path}/variation_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg';

          // Create a mock file (in a real implementation, this would be the actual result)
          await File(tempPath).writeAsString('Mock variation $i content');

          results.add(tempPath);
        }

        return results;
      } else {
        throw GeminiServiceException(
          'Failed to generate image variations (status: ${response.statusCode}): ${response.body}',
          code: 'api-error',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is GeminiServiceException) {
        rethrow;
      }

      throw GeminiServiceException('Failed to generate image variations: $e', originalError: e);
    }
  }

  // Helper method to create a structured edit prompt from instructions and markers
  String _createEditPrompt(String instruction, List<Map<String, double>> markers) {
    final StringBuffer prompt = StringBuffer();

    // Add main instruction
    prompt.writeln('Edit this image with the following instruction: $instruction');

    // Add marker information
    if (markers.isNotEmpty) {
      prompt.writeln('\nApply the edit at these normalized coordinates (values from 0 to 1):');

      for (int i = 0; i < markers.length; i++) {
        final marker = markers[i];
        prompt.writeln(
          '- Marker ${i + 1}: x=${marker['x']?.toStringAsFixed(3)}, y=${marker['y']?.toStringAsFixed(3)}',
        );
      }
    }

    return prompt.toString();
  }

  // Helper method to retry operations with exponential backoff
  Future<T> _retryOperation<T>(Future<T> Function() operation, {required int maxRetries}) async {
    int currentRetry = 0;

    while (true) {
      try {
        return await operation();
      } catch (e) {
        if (currentRetry >= maxRetries) {
          rethrow;
        }

        // Exponential backoff
        final waitTime = _baseDelayMs * (1 << currentRetry);
        await Future.delayed(Duration(milliseconds: waitTime));

        currentRetry++;
      }
    }
  }

  // Clean up resources
  void dispose() {
    _client.close();
  }
}
