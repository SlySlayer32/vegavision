import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vegavision/core/error/error_handler.dart';
import 'package:vegavision/core/logging/logger.dart';

void main() {
  group('ErrorHandler Tests', () {
    late ErrorHandler errorHandler;
    late Logger logger;

    setUp(() {
      errorHandler = ErrorHandler();
      logger = Logger();
    });

    testWidgets('ErrorHandler should handle setState after dispose error', (
      WidgetTester tester,
    ) async {
      // Build widget that will cause setState after dispose error
      final testWidget = ErrorTestWidget();
      await tester.pumpWidget(MaterialApp(home: testWidget));

      // Find and tap the button that will trigger the error
      final button = find.byType(ElevatedButton);
      expect(button, findsOneWidget);
      await tester.tap(button);

      // Wait for potential error
      await tester.pump(const Duration(milliseconds: 200));

      // Navigate away to dispose the widget
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      // Wait again to ensure any delayed errors surface
      await tester.pumpAndSettle();

      // Verify no crash occurred
      expect(tester.takeException(), isNull);
    });

    testWidgets('ErrorHandler should show error widget on build errors', (
      WidgetTester tester,
    ) async {
      FlutterError.onError = (details) {
        ErrorHandler.buildErrorWidget(details);
      };

      // Build widget that will cause a build error
      await tester.pumpWidget(const MaterialApp(home: ErrorBuildTestWidget()));

      // Verify error widget is shown
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
    });
  });
}

class ErrorTestWidget extends StatefulWidget {
  const ErrorTestWidget({super.key});

  @override
  _ErrorTestWidgetState createState() => _ErrorTestWidgetState();
}

class _ErrorTestWidgetState extends State<ErrorTestWidget> {
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _triggerSetStateError() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_disposed) {
        setState(() {}); // This should trigger our error handler
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: _triggerSetStateError,
          child: const Text('Trigger Error'),
        ),
      ),
    );
  }
}

class ErrorBuildTestWidget extends StatelessWidget {
  const ErrorBuildTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    throw FlutterError('Intentional build error');
  }
}
