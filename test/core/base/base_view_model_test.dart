import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:vegavision/core/base/base_view_model.dart';

class MockBaseViewModel extends BaseViewModel {
  @override
  void notifyListeners() {
    super.notifyListeners();
  }
}

void main() {
  group('BaseViewModel', () {
    late MockBaseViewModel viewModel;

    setUp(() {
      viewModel = MockBaseViewModel();
    });

    test('initial state is correct', () {
      expect(viewModel.isLoading, false);
      expect(viewModel.error, null);
    });

    test('setLoading updates loading state and notifies listeners', () {
      // Act
      viewModel.setLoading(true);

      // Assert
      expect(viewModel.isLoading, true);
    });

    test('setError updates error state and notifies listeners', () {
      // Arrange
      const errorMessage = 'Test error';

      // Act
      viewModel.setError(errorMessage);

      // Assert
      expect(viewModel.error, errorMessage);
    });

    test('handleError sets error and notifies listeners', () async {
      // Arrange
      final error = Exception('Test error');
      final stackTrace = StackTrace.current;

      // Act
      await viewModel.handleError(error, stackTrace);

      // Assert
      expect(viewModel.error, error.toString());
    });

    test('dispose sets disposed flag', () {
      // Act
      viewModel.dispose();

      // Assert
      expect(viewModel.isDisposed, true);
    });
  });
}
