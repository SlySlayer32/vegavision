import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  static final PermissionManager _instance = PermissionManager._internal();
  factory PermissionManager() => _instance;
  PermissionManager._internal();

  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> requestStoragePermission() async {
    if (await Permission.storage.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<bool> requestPhotosPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  Future<Map<Permission, PermissionStatus>>
  requestAllRequiredPermissions() async {
    return await [
      Permission.camera,
      Permission.storage,
      Permission.photos,
    ].request();
  }

  Future<bool> checkCameraPermission() async {
    return await Permission.camera.status.isGranted;
  }

  Future<bool> checkStoragePermission() async {
    return await Permission.storage.status.isGranted;
  }

  Future<bool> checkPhotosPermission() async {
    return await Permission.photos.status.isGranted;
  }
}
