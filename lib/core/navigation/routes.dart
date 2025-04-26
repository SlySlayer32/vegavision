import 'package:flutter/material.dart';
import 'package:vegavision/features/image_capture/views/image_capture_view.dart';
import 'package:vegavision/features/image_editor/views/image_editor_view.dart';
import 'package:vegavision/features/result/views/result_view.dart';

class Routes {
  static const String imageCaptureView = '/';
  static const String imageEditorView = '/editor';
  static const String resultView = '/result';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case imageCaptureView:
        return MaterialPageRoute(builder: (_) => const ImageCaptureView());

      case imageEditorView:
        final args = settings.arguments as Map<String, dynamic>?;
        final imageId = args?['imageId'] as String?;

        if (imageId == null) {
          throw ArgumentError('imageId is required for ImageEditorView');
        }

        return MaterialPageRoute(
          builder: (_) => ImageEditorView(imageId: imageId),
        );

      case resultView:
        final args = settings.arguments as Map<String, dynamic>?;
        final editRequestId = args?['editRequestId'] as String?;
        final imageId = args?['imageId'] as String?;

        if (editRequestId == null || imageId == null) {
          throw ArgumentError(
            'editRequestId and imageId are required for ResultView',
          );
        }

        return MaterialPageRoute(
          builder:
              (_) => ResultView(editRequestId: editRequestId, imageId: imageId),
        );

      default:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                body: Center(
                  child: Text('No route defined for ${settings.name}'),
                ),
              ),
        );
    }
  }
}
