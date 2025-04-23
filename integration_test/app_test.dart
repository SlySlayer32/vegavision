import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vegavision/main.dart' as app;
import 'package:vegavision/views/image_capture/image_capture_view.dart';
import 'package:vegavision/views/image_editor/image_editor_view.dart';
import 'package:vegavision/views/result/result_view.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end Image Editing Flow Tests', () {
    testWidgets('Complete image editing flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify app starts at image capture
      expect(find.byType(ImageCaptureView), findsOneWidget);

      // Simulate image capture
      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pumpAndSettle();

      // Verify navigation to editor
      expect(find.byType(ImageEditorView), findsOneWidget);

      // Add markers and instructions
      final canvas = find.byType(GestureDetector).first;
      await tester.tapAt(tester.getCenter(canvas));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Remove the background and make it white');
      await tester.pumpAndSettle();

      // Submit edit request
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify navigation to result view
      expect(find.byType(ResultView), findsOneWidget);
    });

    testWidgets('Offline behavior test', (WidgetTester tester) async {
      // TODO: Implement offline mode testing
      // This will require mocking network connectivity
    });

    testWidgets('Device rotation test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test portrait mode
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpAndSettle();

      // Test landscape mode
      await tester.binding.setSurfaceSize(const Size(800, 400));
      await tester.pumpAndSettle();

      // Verify UI adapts correctly
      expect(find.byType(ImageCaptureView), findsOneWidget);
    });
  });
}
