import 'package:darwin_camera/darwin_camera.dart';
import 'package:flutter/foundation.dart';
import 'package:vegavision/repositories/image_repository.dart';

class ImageCaptureViewModel extends ChangeNotifier {
  ImageCaptureViewModel(this._darwinController, this._imageRepository);
  final DarwinCameraController _darwinController;
  final ImageRepository _imageRepository;

  Future<void> initializeDarwinCamera() async {
    await _darwinController.initialize();
    notifyListeners();
  }

  DarwinCameraController get darwinController => _darwinController;

  // Add other methods to interact with the darwin_camera package...
}
