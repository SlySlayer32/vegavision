import 'package:vegavision/core/di/database_interface.dart';
import 'package:vegavision/models/image_model.dart';

/// Repository for managing image data
class ImageRepository {
  ImageRepository(this._db);
  final Database _db;

  // Single Image Operations
  Future<void> saveImage(ImageModel image) => _db.saveImage(image);
  Future<List<ImageModel>> getImages() => _db.getImages();
  Future<ImageModel?> getImage(String id) => _db.getImage(id);
  Future<void> updateImage(ImageModel image) => _db.updateImage(image);
  Future<bool> deleteImage(String id) => _db.deleteImage(id);

  // Batch Operations
  Future<void> saveMultipleImages(List<ImageModel> images) =>
      _db.saveMultipleImages(images);
}
