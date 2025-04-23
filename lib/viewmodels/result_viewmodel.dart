import 'dart:async';
import 'dart:io';

import 'package:firebase_functions/firebase_functions.dart';
import 'package:flutter/foundation.dart';

import 'package:vegavision/models/edit_request.dart';
import 'package:vegavision/models/edit_result.dart';
import 'package:vegavision/models/image_model.dart';
import 'package:vegavision/repositories/edit_repository.dart';
import 'package:vegavision/repositories/image_repository.dart';
import 'package:vegavision/services/gemini_service.dart';
import 'package:vegavision/services/vision_service.dart';

enum ProcessingMethod {
  directApi,     // Using Vision and Gemini APIs directly
  cloudFunction, // Using Cloud Functions (recommended for production)
  mockResult,    // For testing/demo purposes
}

enum ProcessingStatus {
  notStarted,
  initializing,
  analyzing,   // Using Vision API
  generating,  // Using Gemini API
  downloading,
  completed,
  failed,
  cancelled,
}

class ProcessingProgress {
  
  ProcessingProgress({
    required this.status,
    this.progress,
    this.message,
    this.timeElapsedMs,
    this.estimatedTimeRemainingMs,
  });
  
  factory ProcessingProgress.initial() {
    return ProcessingProgress(status: ProcessingStatus.notStarted);
  }
  final ProcessingStatus status;
  final double? progress;
  final String? message;
  final int? timeElapsedMs;
  final int? estimatedTimeRemainingMs;
  
  ProcessingProgress copyWith({
    ProcessingStatus? status,
    double? progress,
    String? message,
    int? timeElapsedMs,
    int? estimatedTimeRemainingMs,
  }) {
    return ProcessingProgress(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      timeElapsedMs: timeElapsedMs ?? this.timeElapsedMs,
      estimatedTimeRemainingMs: estimatedTimeRemainingMs ?? this.estimatedTimeRemainingMs,
    );
  }
}

class ResultViewModel extends ChangeNotifier {
  
  ResultViewModel(
    this._editRepository,
    this._imageRepository,
    this._visionService,
    this._geminiService,
  );
  final EditRepository _editRepository;
  final ImageRepository _imageRepository;
  final VisionService _visionService;
  final GeminiService _geminiService;
  
  bool _isBusy = false;
  bool get isBusy => _isBusy;
  
  String? _error;
  String? get error => _error;
  
  EditRequest? _editRequest;
  EditRequest? get editRequest => _editRequest;
  
  EditResult? _editResult;
  EditResult? get editResult => _editResult;
  
  ImageModel? _originalImage;
  ImageModel? get originalImage => _originalImage;
  
  File? _originalImageFile;
  File? get originalImageFile => _originalImageFile;
  
  File? _resultImageFile;
  File? get resultImageFile => _resultImageFile;
  
  bool _processingCancelled = false;
  ProcessingProgress _progress = ProcessingProgress.initial();
  ProcessingProgress get progress => _progress;
  
  Timer? _progressTimer;
  final Stopwatch _processingStopwatch = Stopwatch();
  
  // Default to cloud function for production use
  ProcessingMethod _processingMethod = ProcessingMethod.cloudFunction;
  ProcessingMethod get processingMethod => _processingMethod;
  
  // Polling interval when waiting for cloud function results
  final Duration _pollingInterval = const Duration(seconds: 2);
  
  Future<void> loadEditRequest(String requestId) async {
    _isBusy = true;
    _error = null;
    _progress = ProcessingProgress.initial();
    notifyListeners();
    
    try {
      _editRequest = await _editRepository.getEditRequest(requestId);
      
      if (_editRequest == null) {
        _error = 'Edit request not found';
      } else {
        // Load the original image
        _originalImage = await _imageRepository.getImage(_editRequest!.imageId);
        
        if (_originalImage != null) {
          _originalImageFile = await _imageRepository.getImageFile(_editRequest!.imageId);
        }
        
        // Check if there's already a result for this request
        final results = await _editRepository.getEditResultsForRequest(requestId);
        
        if (results.isNotEmpty) {
          // Get the latest result (sorted by creation date)
          results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _editResult = results.first;
          
          // If the result is completed and has a path, load the result image
          if (_editResult!.status == EditResultStatus.completed && 
              _editResult!.resultImagePath != null) {
            _resultImageFile = File(_editResult!.resultImagePath!);
            
            // Verify file exists
            if (!await _resultImageFile!.exists()) {
              _resultImageFile = null;
            }
          }
        }
      }
    } catch (e) {
      _error = 'Failed to load edit request: $e';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
  
  // Set the processing method
  void setProcessingMethod(ProcessingMethod method) {
    _processingMethod = method;
    notifyListeners();
  }
  
  // Start processing the edit request
  Future<void> processEditRequest() async {
    if (_editRequest == null) {
      _error = 'No edit request loaded';
      notifyListeners();
      return;
    }
    
    if (_originalImage == null) {
      _error = 'Original image not found';
      notifyListeners();
      return;
    }
    
    if (_editResult != null && _editResult!.status == EditResultStatus.completed) {
      // Already processed successfully
      return;
    }
    
    _isBusy = true;
    _error = null;
    _processingCancelled = false;
    _progress = ProcessingProgress(
      status: ProcessingStatus.initializing,
      progress: 0.0,
      message: 'Initializing...',
    );
    notifyListeners();
    
    // Start tracking processing time
    _processingStopwatch.reset();
    _processingStopwatch.start();
    
    // Start updating the progress timer
    _startProgressTimer();
    
    try {
      // Update request status
      await _editRepository.updateEditRequestStatus(
        _editRequest!.id,
        EditRequestStatus.inProgress,
      );
      
      // Process according to selected method
      switch (_processingMethod) {
        case ProcessingMethod.directApi:
          await _processWithDirectApi();
          break;
        case ProcessingMethod.cloudFunction:
          await _processWithCloudFunction();
          break;
        case ProcessingMethod.mockResult:
          await _processWithMockResult();
          break;
      }
    } catch (e) {
      if (_processingCancelled) {
        _error = 'Processing cancelled';
        
        // Save cancelled result
        _editResult = await _editRepository.saveEditResult(
          _editRequest!.id,
          _editRequest!.imageId,
          null,
          EditResultStatus.failed,
          errorMessage: 'Processing cancelled by user',
        );
        
        // Update request status
        await _editRepository.updateEditRequestStatus(
          _editRequest!.id,
          EditRequestStatus.failed,
        );
      } else {
        _error = 'Failed to process edit request: $e';
        
        // Save failed result
        _editResult = await _editRepository.saveEditResult(
          _editRequest!.id,
          _editRequest!.imageId,
          null,
          EditResultStatus.failed,
          errorMessage: 'Error: $e',
        );
        
        // Update request status
        await _editRepository.updateEditRequestStatus(
          _editRequest!.id,
          EditRequestStatus.failed,
        );
      }
    } finally {
      // Stop the stopwatch and timer
      _processingStopwatch.stop();
      _stopProgressTimer();
      
      _isBusy = false;
      notifyListeners();
    }
  }
  
  // Cancel the current processing
  void cancelProcessing() {
    if (_isBusy) {
      _processingCancelled = true;
      
      _progress = _progress.copyWith(
        status: ProcessingStatus.cancelled,
        message: 'Cancelling...',
      );
      
      notifyListeners();
    }
  }
  
  // Process using direct API calls (not recommended for production)
  Future<void> _processWithDirectApi() async {
    if (_originalImage!.cloudPath == null) {
      throw Exception('Image not uploaded');
    }
    
    // Check if cancellation was requested
    if (_processingCancelled) {
      throw Exception('Processing cancelled');
    }
    
    // Update status to analyzing
    _progress = _progress.copyWith(
      status: ProcessingStatus.analyzing,
      progress: 0.2,
      message: 'Analyzing image...',
    );
    notifyListeners();
    
    // Analyze the image with Vision API
    final analysisResult = await _visionService.analyzeImage(
      _originalImage!.cloudPath!,
      options: VisionRequestOptions(
        features: [
          VisionFeatureType.objectLocalization,
          VisionFeatureType.labelDetection,
          VisionFeatureType.imageProperties,
        ],
      ),
    );
    
    // Check if cancellation was requested
    if (_processingCancelled) {
      throw Exception('Processing cancelled');
    }
    
    // Update status to generating
    _progress = _progress.copyWith(
      status: ProcessingStatus.generating,
      progress: 0.5,
      message: 'Generating edited image...',
    );
    notifyListeners();
    
    // Process with Gemini API
    final List<Map<String, double>> markerData = _editRequest!.markers
        .map((marker) => {'x': marker.x, 'y': marker.y})
        .toList();
    
    final resultImagePath = await _geminiService.editImage(
      _originalImage!.cloudPath!,
      _editRequest!.instruction,
      markerData,
    );
    
    // Check if cancellation was requested
    if (_processingCancelled) {
      throw Exception('Processing cancelled');
    }
    
    // Update status to downloading
    _progress = _progress.copyWith(
      status: ProcessingStatus.downloading,
      progress: 0.8,
      message: 'Downloading result...',
    );
    notifyListeners();
    
    // Save the result
    if (resultImagePath != null) {
      // In a real implementation, this would be a download if the path is a URL
      _resultImageFile = File(resultImagePath);
      
      // Create the result
      _editResult = await _editRepository.saveEditResult(
        _editRequest!.id,
        _editRequest!.imageId,
        resultImagePath,
        EditResultStatus.completed,
        processingTimeMs: _processingStopwatch.elapsedMilliseconds,
      );
      
      // Update request status
      await _editRepository.updateEditRequestStatus(
        _editRequest!.id,
        EditRequestStatus.completed,
      );
      
      // Update original image status
      await _imageRepository.updateImageStatus(
        _originalImage!.id,
        ImageStatus.completed,
      );
      
      // Update progress
      _progress = _progress.copyWith(
        status: ProcessingStatus.completed,
        progress: 1.0,
        message: 'Editing completed',
      );
    } else {
      throw Exception('Failed to generate edited image');
    }
  }
  
  // Process using Cloud Functions (recommended for production)
  Future<void> _processWithCloudFunction() async {
    if (_originalImage!.cloudPath == null) {
      throw Exception('Image not uploaded');
    }
    
    // Update status to initializing
    _progress = _progress.copyWith(
      status: ProcessingStatus.initializing,
      progress: 0.1,
      message: 'Starting cloud processing...',
    );
    notifyListeners();
    
    try {
      // Call the cloud function to process the image
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('processImageEdit');
      
      // Prepare the request data
      final Map<String, dynamic> requestData = {
        'requestId': _editRequest!.id,
        'imageId': _editRequest!.imageId,
        'cloudPath': _originalImage!.cloudPath,
        'instruction': _editRequest!.instruction,
        'markers': _editRequest!.markers.map((marker) => {
          'x': marker.x,
          'y': marker.y,
          'type': marker.type.toString().split('.').last,
        }).toList(),
      };
      
      // Call the function
      final result = await callable.call(requestData);
      
      // Get the job ID from the response
      final String jobId = result.data['jobId'];
      
      // Poll for results
      await _pollForCloudFunctionResults(jobId);
    } catch (e) {
      throw Exception('Cloud function error: $e');
    }
  }
  
  // Poll for cloud function results
  Future<void> _pollForCloudFunctionResults(String jobId) async {
    const int maxAttempts = 30; // 60 seconds max (with 2-second interval)
    int attempts = 0;
    
    while (attempts < maxAttempts) {
      // Check if cancellation was requested
      if (_processingCancelled) {
        throw Exception('Processing cancelled');
      }
      
      attempts++;
      
      try {
        // Call the status check function
        final HttpsCallable statusCallable = FirebaseFunctions.instance.httpsCallable('checkImageEditStatus');
        final statusResult = await statusCallable.call({'jobId': jobId});
        
        final String status = statusResult.data['status'];
        final double? progressValue = statusResult.data['progress'] != null 
            ? (statusResult.data['progress'] as num).toDouble() 
            : null;
        final String? statusMessage = statusResult.data['message'];
        
        // Update progress based on status
        switch (status) {
          case 'analyzing':
            _progress = _progress.copyWith(
              status: ProcessingStatus.analyzing,
              progress: progressValue ?? 0.3,
              message: statusMessage ?? 'Analyzing image...',
            );
            break;
          case 'generating':
            _progress = _progress.copyWith(
              status: ProcessingStatus.generating,
              progress: progressValue ?? 0.6,
              message: statusMessage ?? 'Generating edited image...',
            );
            break;
          case 'completed':
            // Process is complete, get the result
            final String resultPath = statusResult.data['resultPath'];
            final int processingTimeMs = statusResult.data['processingTimeMs'] ?? _processingStopwatch.elapsedMilliseconds;
            
            // Update status to downloading
            _progress = _progress.copyWith(
              status: ProcessingStatus.downloading,
              progress: 0.9,
              message: 'Downloading result...',
            );
            notifyListeners();
            
            // In a real implementation, download the result if it's a cloud path
            // For now, we'll assume it's a local path
            _resultImageFile = File(resultPath);
            
            // Save the result
            _editResult = await _editRepository.saveEditResult(
              _editRequest!.id,
              _editRequest!.imageId,
              resultPath,
              EditResultStatus.completed,
              processingTimeMs: processingTimeMs,
            );
            
            // Update request status
            await _editRepository.updateEditRequestStatus(
              _editRequest!.id,
              EditRequestStatus.completed,
            );
            
            // Update original image status
            await _imageRepository.updateImageStatus(
              _originalImage!.id,
              ImageStatus.completed,
            );
            
            // Update progress
            _progress = _progress.copyWith(
              status: ProcessingStatus.completed,
              progress: 1.0,
              message: 'Editing completed',
            );
            
            // Exit the polling loop
            return;
            
          case 'failed':
            final String errorMessage = statusResult.data['error'] ?? 'Unknown error';
            throw Exception('Processing failed: $errorMessage');
            
          default:
            // Still processing, continue polling
            break;
        }
        
        notifyListeners();
        
        // Wait before next poll
        await Future.delayed(_pollingInterval);
      } catch (e) {
        if (e.toString().contains('Processing failed')) {
          // This is an expected error from the status check
          rethrow;
        } else {
          // Unexpected error during polling, log and continue
          print('Error polling for results: $e');
          
          // Wait before retry
          await Future.delayed(_pollingInterval);
        }
      }
    }
    
    // If we get here, we've reached the maximum attempts without completion
    throw Exception('Processing timed out after ${maxAttempts * _pollingInterval.inSeconds} seconds');
  }
  
  // Process with mock result (for testing)
  Future<void> _processWithMockResult() async {
    // Simulate processing steps with delays
    
    // Analyzing stage
    _progress = _progress.copyWith(
      status: ProcessingStatus.analyzing,
      progress: 0.2,
      message: 'Analyzing image...',
    );
    notifyListeners();
    
    await Future.delayed(const Duration(seconds: 1));
    
    // Check if cancellation was requested
    if (_processingCancelled) {
      throw Exception('Processing cancelled');
    }
    
    // Generating stage
    _progress = _progress.copyWith(
      status: ProcessingStatus.generating,
      progress: 0.6,
      message: 'Generating edited image...',
    );
    notifyListeners();
    
    await Future.delayed(const Duration(seconds: 2));
    
    // Check if cancellation was requested
    if (_processingCancelled) {
      throw Exception('Processing cancelled');
    }
    
    // Create a temporary file as the "result"
    final Directory tempDir = Directory.systemTemp;
    final String resultPath = '${tempDir.path}/mock_result_${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    // If we have an original file, copy it as the mock result
    if (_originalImageFile != null && await _originalImageFile!.exists()) {
      await _originalImageFile!.copy(resultPath);
    } else {
      // Otherwise create an empty file
      await File(resultPath).writeAsString('Mock result file');
    }
    
    // Downloading stage
    _progress = _progress.copyWith(
      status: ProcessingStatus.downloading,
      progress: 0.9,
      message: 'Downloading result...',
    );
    notifyListeners();
    
    await Future.delayed(const Duration(seconds: 1));
    
    // Check if cancellation was requested
    if (_processingCancelled) {
      throw Exception('Processing cancelled');
    }
    
    // Save the result
    _resultImageFile = File(resultPath);
    
    _editResult = await _editRepository.saveEditResult(
      _editRequest!.id,
      _editRequest!.imageId,
      resultPath,
      EditResultStatus.completed,
      processingTimeMs: _processingStopwatch.elapsedMilliseconds,
    );
    
    // Update request status
    await _editRepository.updateEditRequestStatus(
      _editRequest!.id,
      EditRequestStatus.completed,
    );
    
    // Update original image status
    await _imageRepository.updateImageStatus(
      _originalImage!.id,
      ImageStatus.completed,
    );
    
    // Update progress
    _progress = _progress.copyWith(
      status: ProcessingStatus.completed,
      progress: 1.0,
      message: 'Editing completed',
    );
  }
  
  // Start a timer to update the progress elapsed time
  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_processingStopwatch.isRunning) {
        // Update elapsed time
        _progress = _progress.copyWith(
          timeElapsedMs: _processingStopwatch.elapsedMilliseconds,
        );
        
        // Calculate estimated time remaining if we have progress
        if (_progress.progress != null && _progress.progress! > 0) {
          final double progressValue = _progress.progress!;
          final int elapsedMs = _processingStopwatch.elapsedMilliseconds;
          
          // Estimate total time based on current progress and elapsed time
          final int estimatedTotalMs = (elapsedMs / progressValue).round();
          final int estimatedRemainingMs = estimatedTotalMs - elapsedMs;
          
          // Only update if it's a reasonable value
          if (estimatedRemainingMs > 0 && estimatedRemainingMs < 5 * 60 * 1000) {
            _progress = _progress.copyWith(
              estimatedTimeRemainingMs: estimatedRemainingMs,
            );
          }
        }
        
        notifyListeners();
      }
    });
  }
  
  // Stop the progress timer
  void _stopProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }
  
  @override
  void dispose() {
    _stopProgressTimer();
    super.dispose();
  }
}