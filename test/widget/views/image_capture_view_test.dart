import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vegavision/viewmodels/image_editor_viewmodel.dart';
import 'package:vegavision/views/image_capture/image_capture_view.dart';


void main() {
  group('ImageCaptureView Widget Tests', () {
    testWidgets('should render ImageCaptureView', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => ImageEditorViewModel(),
            child: const ImageCaptureView(),
          ),
        ),
      );

      expect(find.byType(ImageCaptureView), findsOneWidget);
    });
  });
}
