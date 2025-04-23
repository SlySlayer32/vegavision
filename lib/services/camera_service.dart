import 'package:camera/camera.dart';

/// Exception thrown when camera operations fail
class CameraServiceException implements Exception {
  CameraServiceException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => 'CameraServiceException($code): $message';
}

/// Interface for camera operations
abstract class CameraService {
  /// Initialize the camera
  Future<void> initialize();

  /// Capture an unprocessed image at maximum resolution
  /// Returns the path to the captured image file
  Future<String?> captureImage();

  /// Clean up camera resources
  void dispose();
}

/// Implementation of CameraService that supports raw image capture
class CameraServiceImpl implements CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;

  @override
  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.max,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.yuv420,
        );
        await _controller!.initialize();
        // Configure for raw capture
        await _controller!.lockCaptureOrientation();
        await _controller!.setExposureMode(ExposureMode.locked);
        await _controller!.setFocusMode(FocusMode.locked);
      }
    } on CameraException catch (e) {
      throw CameraServiceException('Failed to initialize camera: ${e.description}', code: e.code);
    }
  }

  @override
  Future<String?> captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw CameraServiceException('Camera not initialized');
    }

    try {
      // Capture in raw format
      final XFile file = await _controller!.takePicture();
      return file.path;
    } on CameraException catch (e) {
      throw CameraServiceException('Failed to capture image: ${e.description}', code: e.code);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}
