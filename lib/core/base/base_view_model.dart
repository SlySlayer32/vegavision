import 'package:flutter/foundation.dart';
import 'package:vegavision/core/services/base_api_service.dart';
import 'package:vegavision/core/services/error_handler.dart';
import 'package:vegavision/core/services/connectivity_service.dart';

enum ViewState { idle, loading, error, success }

abstract class BaseViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String? _errorMessage;
  bool _isDisposed = false;
  Function? _retryFunction;

  final ConnectivityService _connectivityService;

  BaseViewModel(this._connectivityService);

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == ViewState.loading;
  bool get hasError => _state == ViewState.error;
  bool get isSuccess => _state == ViewState.success;

  void Function()? get retry => _retryFunction;

  @protected
  void setState(ViewState newState) {
    if (_isDisposed) return;
    _state = newState;
    _errorMessage = null;
    notifyListeners();
  }

  @protected
  void setError(String message, {Function? retryFunction}) {
    if (_isDisposed) return;
    _state = ViewState.error;
    _errorMessage = message;
    _retryFunction = retryFunction;
    notifyListeners();
  }

  @protected
  Future<T?> handleApiRequest<T>(
    Future<T> Function() request, {
    bool requiresConnection = true,
    String? offlineMessage,
  }) async {
    try {
      if (requiresConnection && !await _connectivityService.isConnected()) {
        setError(
          offlineMessage ?? 'No internet connection available',
          retryFunction:
              () => handleApiRequest(
                request,
                requiresConnection: requiresConnection,
                offlineMessage: offlineMessage,
              ),
        );
        return null;
      }

      setState(ViewState.loading);
      final result = await request();
      setState(ViewState.success);
      return result;
    } on ApiException catch (e) {
      final message = ErrorHandler.handleError(e);
      final shouldRetry = ErrorHandler.shouldRetry(e);

      setError(
        message,
        retryFunction:
            shouldRetry
                ? () => handleApiRequest(
                  request,
                  requiresConnection: requiresConnection,
                  offlineMessage: offlineMessage,
                )
                : null,
      );
      return null;
    } catch (e, stack) {
      final message = ErrorHandler.handleError(e, stack);
      setError(
        message,
        retryFunction:
            () => handleApiRequest(
              request,
              requiresConnection: requiresConnection,
              offlineMessage: offlineMessage,
            ),
      );
      return null;
    }
  }

  @protected
  Future<void> handleOfflineAction(
    Future<void> Function() action,
    Future<void> Function() offlineAction,
  ) async {
    try {
      setState(ViewState.loading);

      if (await _connectivityService.isConnected()) {
        await action();
      } else {
        await offlineAction();
      }

      setState(ViewState.success);
    } catch (e, stack) {
      final message = ErrorHandler.handleError(e, stack);
      setError(message);
    }
  }

  void resetState() {
    setState(ViewState.idle);
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
