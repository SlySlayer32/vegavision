import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Helper function to wrap a widget with required providers for testing
Widget testableWidget({
  required Widget child,
  List<SingleChildWidget> providers = const [],
}) {
  return MaterialApp(
    home: MultiProvider(providers: providers, child: Material(child: child)),
  );
}

/// Helper function to pump a widget with standard timeout
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  var timerDone = false;
  final timer = Timer(timeout, () => timerDone = true);

  while (!timerDone) {
    await tester.pump(const Duration(milliseconds: 100));

    final found = tester.any(finder);
    if (found) {
      timerDone = true;
    }
  }

  timer.cancel();
}
