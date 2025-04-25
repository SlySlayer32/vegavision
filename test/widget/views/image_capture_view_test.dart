import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vegavision/viewmodels/image_capture_viewmodel.dart';
import 'package:vegavision/views/image_capture/image_capture_view.dart';

import '../../helpers/mocks.mocks.dart';

void main() {
  late MockImageRepository mockImageRepository;
  late ImageCaptureViewModel viewModel;

  setUp(() {
    mockImageRepository = MockImageRepository();
    viewModel = ImageCaptureViewModel(mockImageRepository);
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: ChangeNotifierProvider.value(value: viewModel, child: const ImageCaptureView()),
    );
  }

  group('ImageCaptureView Widget Tests', () {
    testWidgets('shows loading state when not initialized', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Initializing camera...'), findsOneWidget);
    });

    testWidgets('shows error state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      viewModel.setError('Camera initialization failed');
      await tester.pump();

      expect(find.text('Error: Camera initialization failed'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget); // Retry button
    });
  });
}
