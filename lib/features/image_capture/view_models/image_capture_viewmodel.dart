import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vegavision/core/base/base_view_model.dart';
import 'package:vegavision/core/services/connectivity_service.dart';
import 'package:vegavision/features/image_capture/models/image_marker.dart';
import 'package:vegavision/shared/repositories/image_repository.dart';

class ImageCaptureViewModel extends BaseViewModel {
  final ImageRepository _imageRepository;
  final ImagePicker _imagePicker;

  CameraController? _controller;
  bool _isInitialized = false;
  File? _capturedImage;
  String? _imageId;
  List<ImageMarker> _markers = [];
  int _selectedCameraIndex = 0;
  List<CameraDescription> _cameras = [];

  ImageCaptureViewModel({
    required ImageRepository imageRepository,
    required ConnectivityService connectivityService,
    ImagePicker? imagePicker,
  }) : _imageRepository = imageRepository,
       _imagePicker = imagePicker ?? ImagePicker(),
       super(connectivityService);

  // Getters
  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  File? get capturedImage => _capturedImage;
  String? get imageId => _imageId;
  List<ImageMarker> get markers => _markers;

  // Initialize camera
  Future<void> initializeCamera() async {
    await handleApiRequest(() async {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      await _initializeCameraController();
      _isInitialized = true;
      notifyListeners();
    }, requiresConnection: false);
  }

  Future<void> _initializeCameraController() async {
    if (_cameras.isEmpty) return;

    _controller?.dispose();

    _controller = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
    } on CameraException catch (e) {
      setError('Failed to initialize camera: ${e.description}');
    }
  }

  // Switch camera
  Future<void> switchCamera() async {
    if (_cameras.length <= 1) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _initializeCameraController();
    notifyListeners();
  }

  // Capture image
  Future<void> captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      setError('Camera not initialized');
      return;
    }

    await handleApiRequest(() async {
      final xFile = await _controller!.takePicture();
      _capturedImage = File(xFile.path);

      // Save to repository
      final savedImage = await _imageRepository.saveImage(
        xFile.path,
        metadata: {
          'source': 'camera',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      _imageId = savedImage.id;
      notifyListeners();
    }, requiresConnection: false);
  }

  // Pick image from gallery
  Future<void> pickImageFromGallery() async {
    await handleApiRequest(() async {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (pickedFile != null) {
        _capturedImage = File(pickedFile.path);

        // Save to repository
        final savedImage = await _imageRepository.saveImage(
          pickedFile.path,
          metadata: {
            'source': 'gallery',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );

        _imageId = savedImage.id;
        notifyListeners();
      }
    }, requiresConnection: false);
  }

  // Reset capture
  void resetCapture() {
    _capturedImage = null;
    _imageId = null;
    _markers = [];
    notifyListeners();
  }

  // Handle markers
  void addMarker(ImageMarker marker) {
    _markers.add(marker);
    notifyListeners();
  }

  void removeMarker(ImageMarker marker) {
    _markers.removeWhere((m) => m.id == marker.id);
    notifyListeners();
  }

  void onMarkerTapped(ImageMarker marker) {
    // Handle marker tap
    // You can implement marker editing or deletion here
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
