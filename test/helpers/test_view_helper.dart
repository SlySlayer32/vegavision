import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vegavision/core/base/base_view_model.dart';
import 'package:vegavision/core/navigation/navigation_service.dart';
import 'package:get_it/get_it.dart';

/// Helper class for testing views with MVVM pattern
class TestViewHelper {
  /// Pumps a widget wrapped with necessary providers for testing
  static Future<void> pumpWidget<T extends BaseViewModel>({
    required WidgetTester tester,
    required Widget widget,
    required T viewModel,
    NavigationService? navigationService,
    ThemeData? theme,
  }) async {
    // Register mocked services if needed
    if (navigationService != null &&
        !GetIt.I.isRegistered<NavigationService>()) {
      GetIt.I.registerSingleton<NavigationService>(navigationService);
    }

    // Build widget tree
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? ThemeData.light(),
        home: ChangeNotifierProvider<T>.value(value: viewModel, child: widget),
      ),
    );

    await tester.pumpAndSettle();
  }

  /// Finds a widget by type and verifies its properties
  static T findWidgetByType<T extends Widget>(WidgetTester tester) {
    final finder = find.byType(T);
    expect(finder, findsOneWidget);
    return tester.widget<T>(finder);
  }

  /// Verifies that a widget exists by key
  static void verifyWidgetExists(WidgetTester tester, Key key) {
    expect(find.byKey(key), findsOneWidget);
  }

  /// Verifies that text exists
  static void verifyTextExists(WidgetTester tester, String text) {
    expect(find.text(text), findsOneWidget);
  }

  /// Taps a widget and waits for animations
  static Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Enters text in a text field and waits for animations
  static Future<void> enterTextAndSettle(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  /// Verifies loading indicator is shown/hidden
  static void verifyLoadingIndicator(
    WidgetTester tester, {
    required bool isShown,
  }) {
    final finder = find.byType(CircularProgressIndicator);
    if (isShown) {
      expect(finder, findsOneWidget);
    } else {
      expect(finder, findsNothing);
    }
  }

  /// Verifies error message is shown/hidden
  static void verifyErrorMessage(WidgetTester tester, String? errorMessage) {
    if (errorMessage != null) {
      expect(find.text(errorMessage), findsOneWidget);
    } else {
      expect(find.byType(SnackBar), findsNothing);
    }
  }
}
