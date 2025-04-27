import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vegavision/features/image_editor/view_models/image_editor_viewmodel.dart';
import 'package:vegavision/features/image_editor/views/image_editor_view.dart';

import '../../../helpers/mocks.mocks.dart';
import '../../../helpers/test_view_helper.dart';

void main() {
  group('ImageEditorView', () {
    late MockStorageService mockStorageService;
    late MockEditRepository mockEditRepository;
    late ImageEditorViewModel viewModel;

    setUp(() {
      mockStorageService = MockStorageService();
      mockEditRepository = MockEditRepository();
      viewModel = ImageEditorViewModel(mockStorageService, mockEditRepository);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      // Arrange
      await tester.pumpWidget(
        testableWidget(
          child: const ImageEditorView(),
          providers: [
            ChangeNotifierProvider<ImageEditorViewModel>.value(
              value: viewModel,
            ),
          ],
        ),
      );

      // Act
      viewModel.setState(ViewState.loading);
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when error occurs', (tester) async {
      // Arrange
      const errorMessage = 'Test error message';
      await tester.pumpWidget(
        testableWidget(
          child: const ImageEditorView(),
          providers: [
            ChangeNotifierProvider<ImageEditorViewModel>.value(
              value: viewModel,
            ),
          ],
        ),
      );

      // Act
      viewModel.setError(errorMessage);
      await tester.pump();

      // Assert
      expect(find.text(errorMessage), findsOneWidget);
    });
  });
}
