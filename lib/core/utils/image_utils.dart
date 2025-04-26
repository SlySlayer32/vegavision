import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageUtils {
  static const _uuid = Uuid();

  static Future<File> compressImage(
    File file, {
    int quality = 85,
    int minWidth = 1024,
    int minHeight = 1024,
  }) async {
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/${_uuid.v4()}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: quality,
      minWidth: minWidth,
      minHeight: minHeight,
    );

    return File(result?.path ?? file.path);
  }

  static Future<String> getImageSize(File file) async {
    final bytes = await file.length();
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  static Future<Map<String, int>> getImageDimensions(File file) async {
    final decodedImage = await decodeImageFromList(await file.readAsBytes());
    return {'width': decodedImage.width, 'height': decodedImage.height};
  }

  static String generateThumbnailPath(String originalPath) {
    final lastDot = originalPath.lastIndexOf('.');
    final pathWithoutExtension =
        lastDot != -1 ? originalPath.substring(0, lastDot) : originalPath;
    final extension = lastDot != -1 ? originalPath.substring(lastDot) : '.jpg';
    return '${pathWithoutExtension}_thumb$extension';
  }
}
