import 'package:flutter_test/flutter_test.dart';
import 'package:your_project/features/image_capture/views/image_capture_view.dart';

void main() {
  testWidgets('hello world!', (WidgetTester tester) async {
    await tester.pumpWidget(ImageCaptureView());
    expect(find.text('Hello World'), findsOneWidget);
  });
}
