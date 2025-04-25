import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vegavision/viewmodels/image_editor_viewmodel.dart';
import 'package:vegavision/views/image_editor/image_editor_view.dart';

import '../../helpers/mocks.mocks.dart';

void main() {
  late MockImageRepository mockImageRepository;
  late MockEditRepository mockEditRepository;
  late MockStorageService mockStorageService;
  late ImageEditorViewModel viewModel;

  setUp(() {
    mockImageRepository = MockImageRepository();
    mockEditRepository = MockEditRepository();
    mockStorageService = MockStorageService();
    viewModel = ImageEditorViewModel(mockImageRepository, mockEditRepository, mockStorageService);
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: ChangeNotifierProvider.value(
        value: viewModel,
        child: ImageEditorView(imageId: 'test-1'),
      ),
    );
  }

  group('ImageEditorView Widget Tests', () {
    testWidgets('shows loading state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await viewModel.loadImage('test-1');
      viewModel.setError('Failed to load image');
      await tester.pump();

      expect(find.text('Error: Failed to load image'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget); // Retry button
    });
  });
}
