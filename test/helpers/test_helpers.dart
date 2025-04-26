import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:vegavision/core/error/error_handler.dart';
import 'package:vegavision/core/logging/logger.dart';

// Mock classes
class MockErrorHandler extends Mock implements ErrorHandler {}

class MockLogger extends Mock implements Logger {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

// Widget test helpers
extension WidgetTesterExtension on WidgetTester {
  Future<void> pumpApp(Widget widget) async {
    await pumpWidget(
      MaterialApp(home: widget, navigatorObservers: [MockNavigatorObserver()]),
    );
    await pumpAndSettle();
  }

  Future<void> tapAndSettle(Finder finder) async {
    await tap(finder);
    await pumpAndSettle();
  }

  Future<void> enterTextAndSettle(Finder finder, String text) async {
    await enterText(finder, text);
    await pumpAndSettle();
  }
}

// Test data generators
class TestData {
  static const testEmail = 'test@example.com';
  static const testPassword = 'Password123!';
  static const testUsername = 'testuser';

  static Map<String, dynamic> get testUser => {
    'id': '1',
    'email': testEmail,
    'username': testUsername,
  };
}

// Custom matchers
Matcher isWidgetType<T>() => isA<T>();

Matcher hasErrorOfType<T>() {
  return predicate((dynamic e) => e is T);
}

// Widget test wrapper
Widget testableWidget({required Widget child}) {
  return MaterialApp(home: Scaffold(body: child));
}
