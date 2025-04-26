import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

enum CameraQuality {
  low, // 720p
  medium, // 1080p
  high, // 4K if available
}

class CameraConfiguration {
  final ResolutionPreset resolution;
  final bool enableAudio;
  final int imageQuality;
  final double maxZoom;
  final bool enableFlash;

  const CameraConfiguration({
    this.resolution = ResolutionPreset.high,
    this.enableAudio = false,
    this.imageQuality = 90,
    this.maxZoom = 3.0,
    this.enableFlash = true,
  });
}

abstract class CameraService {
  Future<void> initialize();
  Future<void> dispose();
  Future<File> captureImage();
  Future<void> switchCamera();
  Future<void> setFlashMode(FlashMode mode);
  Future<void> setZoomLevel(double zoom);
  Future<void> setFocusPoint(Offset point);
  bool get isInitialized;
  CameraController? get controller;
}

class CameraServiceImpl implements CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  CameraConfiguration _config;
  bool _isInitialized = false;

  CameraServiceImpl([CameraConfiguration? config])
    : _config = config ?? const CameraConfiguration();

  @override
  bool get isInitialized => _isInitialized;

  @override
  CameraController? get controller => _controller;

  @override
  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw CameraException(
          'No cameras found',
          'Device has no cameras available',
        );
      }

      await _initializeController();
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      throw CameraException('Failed to initialize camera', e.toString());
    }
  }

  Future<void> _initializeController() async {
    if (_cameras.isEmpty) return;

    // Dispose previous controller if exists
    await _controller?.dispose();

    // Create new controller
    _controller = CameraController(
      _cameras[_currentCameraIndex],
      _config.resolution,
      enableAudio: _config.enableAudio,
      imageFormatGroup:
          Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420,
    );

    try {
      await _controller!.initialize();

      // Set initial flash mode
      if (_config.enableFlash) {
        await _controller!.setFlashMode(FlashMode.auto);
      }

      // Set initial zoom level
      if (_controller!.value.maxZoomLevel > 1.0) {
        await _controller!.setZoomLevel(1.0);
      }
    } catch (e) {
      throw CameraException(
        'Failed to initialize camera controller',
        e.toString(),
      );
    }
  }

  @override
  Future<File> captureImage() async {
    if (!_isInitialized || _controller == null) {
      throw CameraException(
        'Camera not initialized',
        'Initialize camera before capturing',
      );
    }

    try {
      // Capture image
      final XFile xFile = await _controller!.takePicture();

      // Process image quality
      if (_config.imageQuality < 100) {
        final File originalFile = File(xFile.path);
        final img.Image? image = img.decodeImage(
          await originalFile.readAsBytes(),
        );

        if (image != null) {
          final img.Image processedImage = img.copyResize(
            image,
            width: (image.width * (_config.imageQuality / 100)).round(),
            height: (image.height * (_config.imageQuality / 100)).round(),
          );

          final List<int> processedBytes = img.encodeJpg(
            processedImage,
            quality: _config.imageQuality,
          );
          await originalFile.writeAsBytes(processedBytes);
          return originalFile;
        }
      }

      return File(xFile.path);
    } catch (e) {
      throw CameraException('Failed to capture image', e.toString());
    }
  }

  @override
  Future<void> switchCamera() async {
    if (_cameras.length <= 1) {
      throw CameraException(
        'Camera switch not available',
        'Device has only one camera',
      );
    }

    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    await _initializeController();
  }

  @override
  Future<void> setFlashMode(FlashMode mode) async {
    if (!_isInitialized || _controller == null) {
      throw CameraException(
        'Camera not initialized',
        'Initialize camera before setting flash mode',
      );
    }

    try {
      await _controller!.setFlashMode(mode);
    } catch (e) {
      throw CameraException('Failed to set flash mode', e.toString());
    }
  }

  @override
  Future<void> setZoomLevel(double zoom) async {
    if (!_isInitialized || _controller == null) {
      throw CameraException(
        'Camera not initialized',
        'Initialize camera before setting zoom',
      );
    }

    try {
      // Ensure zoom level is within bounds
      final double constrainedZoom = zoom.clamp(
        _controller!.value.minZoomLevel,
        _controller!.value.maxZoomLevel,
      );

      await _controller!.setZoomLevel(constrainedZoom);
    } catch (e) {
      throw CameraException('Failed to set zoom level', e.toString());
    }
  }

  @override
  Future<void> setFocusPoint(Offset point) async {
    if (!_isInitialized || _controller == null) {
      throw CameraException(
        'Camera not initialized',
        'Initialize camera before setting focus',
      );
    }

    try {
      // Set focus point
      await _controller!.setFocusPoint(point);

      // Also set exposure point for consistent results
      await _controller!.setExposurePoint(point);

      // Auto focus after setting point
      await _controller!.setFocusMode(FocusMode.auto);
    } catch (e) {
      throw CameraException('Failed to set focus point', e.toString());
    }
  }

  Future<void> updateConfiguration(CameraConfiguration newConfig) async {
    _config = newConfig;
    if (_isInitialized) {
      await _initializeController();
    }
  }

  @override
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
}
