import 'package:camera/camera.dart' as camera;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vegavision/models/image_model.dart';
import 'package:vegavision/models/image_status.dart';
import 'package:vegavision/repositories/image_repository.dart';

class CameraSettings {
  CameraSettings({
    this.flashMode = camera.FlashMode.auto,
    this.resolution = camera.ResolutionPreset.high,
    this.zoomLevel = 1.0,
    this.exposureOffset = 0.0,
  });

  final camera.FlashMode flashMode;
  final camera.ResolutionPreset resolution;
  final double zoomLevel;
  final double exposureOffset;

  CameraSettings copyWith({
    camera.FlashMode? flashMode,
    camera.ResolutionPreset? resolution,
    double? zoomLevel,
    double? exposureOffset,
  }) {
    return CameraSettings(
      flashMode: flashMode ?? this.flashMode,
      resolution: resolution ?? this.resolution,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      exposureOffset: exposureOffset ?? this.exposureOffset,
    );
  }
}

class ImageCaptureViewModel extends ChangeNotifier {
  ImageCaptureViewModel(this._imageRepository);

  final ImageRepository _imageRepository;
  camera.CameraController? _controller;
  ImageModel? _capturedImage;
  String? _error;
  bool _isBusy = false;
  CameraSettings _settings = CameraSettings();
  List<camera.CameraDescription> _cameras = [];
  int _selectedCamera = 0;

  // Getters
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  bool get isBusy => _isBusy;
  String? get error => _error;
  ImageModel? get capturedImage => _capturedImage;
  camera.CameraController? get controller => _controller;
  CameraSettings get settings => _settings;
  List<camera.CameraDescription> get availableCameras => _cameras;
  double get maxZoomLevel => _controller?.value.maxZoomLevel ?? 1.0;
  double get minExposureOffset => _controller?.value.exposureOffsetSteps?.lowerBound ?? -1.0;
  double get maxExposureOffset => _controller?.value.exposureOffsetSteps?.upperBound ?? 1.0;

  Future<void> initializeCamera() async {
    try {
      _setBusy(true);
      _error = null;

      _cameras = await camera.availableCameras();
      if (_cameras.isEmpty) {
        throw camera.CameraException('No cameras found', 'No cameras available on this device');
      }

      final newController = camera.CameraController(
        _cameras[_selectedCamera],
        _settings.resolution,
        enableAudio: false,
        imageFormatGroup: camera.ImageFormatGroup.jpeg,
      );

      await newController.initialize();
      _controller = newController;

      await _applySettings();
      notifyListeners();
    } on camera.CameraException catch (e) {
      _error = 'Failed to initialize camera: ${e.description}';
    } catch (e) {
      _error = 'Failed to initialize camera: $e';
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _applySettings() async {
    if (!isInitialized) return;

    try {
      await _controller!.setFlashMode(_settings.flashMode);
      await _controller!.setZoomLevel(_settings.zoomLevel);
      await _controller!.setExposureOffset(_settings.exposureOffset);
    } catch (e) {
      _error = 'Failed to apply camera settings: $e';
      notifyListeners();
    }
  }

  Future<void> setFlashMode(camera.FlashMode mode) async {
    if (!isInitialized) return;
    _settings = _settings.copyWith(flashMode: mode);
    await _applySettings();
    notifyListeners();
  }

  Future<void> setResolution(camera.ResolutionPreset resolution) async {
    if (!isInitialized || _settings.resolution == resolution) return;

    _settings = _settings.copyWith(resolution: resolution);
    await _reinitializeCamera();
    notifyListeners();
  }

  Future<void> setZoom(double level) async {
    if (!isInitialized) return;
    _settings = _settings.copyWith(zoomLevel: level);
    await _applySettings();
    notifyListeners();
  }

  Future<void> setExposureOffset(double offset) async {
    if (!isInitialized) return;
    _settings = _settings.copyWith(exposureOffset: offset);
    await _applySettings();
    notifyListeners();
  }

  Future<void> switchCamera() async {
    if (_cameras.length <= 1) return;

    _selectedCamera = (_selectedCamera + 1) % _cameras.length;
    await _reinitializeCamera();
    notifyListeners();
  }

  Future<void> _reinitializeCamera() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }
    await initializeCamera();
  }

  Future<void> captureImage() async {
    if (!isInitialized || isBusy) return;

    try {
      _setBusy(true);
      final xFile = await _controller!.takePicture();

      final image = await _imageRepository.saveImage(
        xFile.path,
        ImageSource.camera,
        status: ImageStatus.pending,
      );

      _capturedImage = image;
    } catch (e) {
      _error = 'Failed to capture image: $e';
    } finally {
      _setBusy(false);
    }
  }

  Future<void> pickImageFromGallery() async {
    if (isBusy) return;

    try {
      _setBusy(true);
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final image = await _imageRepository.saveImage(
          path: pickedFile.path,
          source: 'gallery',
          status: ImageStatus.pending,
        );

        _capturedImage = image;
      }
    } catch (e) {
      _error = 'Failed to pick image from gallery: $e';
    } finally {
      _setBusy(false);
    }
  }

  void resetCapture() {
    _capturedImage = null;
    notifyListeners();
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
