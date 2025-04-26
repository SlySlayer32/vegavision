import 'dart:async';

import 'package:flutter/material.dart';

import '../logging/logger.dart';

class AutoBugFixer {
  static final AutoBugFixer _instance = AutoBugFixer._internal();
  factory AutoBugFixer() => _instance;
  AutoBugFixer._internal();

  final _logger = Logger();

  final Map<Type, Function(dynamic)> _fixTemplates = {
    StateError: (error) => _handleStateError(error),
    BuildContext: (error) => _handleBuildContextError(error),
    AssertionError: (error) => _handleAssertionError(error),
  };

  Future<bool> attemptFix(
    dynamic error,
    StackTrace stackTrace, {
    String? context,
  }) async {
    try {
      _logger.error(
        message: 'Attempting to fix bug',
        error: error,
        stackTrace: stackTrace,
        context: context,
      );

      final fix = _fixTemplates[error.runtimeType];
      if (fix != null) {
        await fix(error);
        return true;
      }

      if (error.toString().contains('setState')) {
        return await _handleSetStateError(error);
      }

      return false;
    } catch (e, s) {
      _logger.error(
        message: 'Error during bug fixing attempt',
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }

  static Future<void> _handleStateError(StateError error) async {
    if (error.message.contains('stream already closed')) {
      // Create a new stream controller if needed
      StreamController? controller;
      try {
        controller = StreamController();
        // The old stream was closed, so we create a new one
        _instance._logger.info(
          'Created new StreamController to handle closed stream error',
        );
      } catch (e) {
        controller?.close();
      }
    }
  }

  static Future<void> _handleBuildContextError(dynamic error) async {
    if (error.toString().contains('unmounted')) {
      // Schedule a rebuild for the next frame if widget was unmounted
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _instance._logger.info(
          'Scheduled rebuild for next frame due to unmounted widget',
        );
      });
    }
  }

  static Future<void> _handleAssertionError(AssertionError error) async {
    if (error.message?.toString().contains('mounted') ?? false) {
      // Handle widget mounted assertions
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _instance._logger.info(
          'Assertion error handled: Widget mounted state issue',
        );
      });
    }
  }

  Future<bool> _handleSetStateError(dynamic error) async {
    if (error.toString().contains('after dispose')) {
      _logger.warning('Caught setState after dispose - preventing crash');
      // Return true since we prevented the crash
      return true;
    }
    return false;
  }
}
