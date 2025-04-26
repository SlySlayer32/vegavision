import 'dart:async';
import 'package:hive/hive.dart';
import 'package:vegavision/core/services/connectivity_service.dart';

/// Represents a queued operation that will be executed when online
class QueuedOperation {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;

  QueuedOperation({
    required this.id,
    required this.type,
    required this.data,
    DateTime? createdAt,
    this.retryCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  QueuedOperation copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    int? retryCount,
  }) {
    return QueuedOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  factory QueuedOperation.fromJson(Map<String, dynamic> json) {
    return QueuedOperation(
      id: json['id'] as String,
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }
}

/// Service to handle offline operations that need to be synced when online
class OfflineQueueService {
  final Box _box;
  final ConnectivityService _connectivityService;
  final int _maxRetries;
  final Duration _retryDelay;
  Timer? _syncTimer;
  bool _isSyncing = false;

  static const String _queueKey = 'offline_queue';

  OfflineQueueService(
    this._box,
    this._connectivityService, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(minutes: 5),
  }) : _maxRetries = maxRetries,
       _retryDelay = retryDelay {
    _initialize();
  }

  void _initialize() {
    _connectivityService.onConnectivityChanged.listen((isConnected) {
      if (isConnected) {
        syncQueue();
      }
    });
  }

  /// Add an operation to the queue
  Future<void> addOperation(QueuedOperation operation) async {
    final queue = await _getQueue();
    queue.add(operation);
    await _saveQueue(queue);

    // Try to sync immediately if online
    if (await _connectivityService.isConnected()) {
      syncQueue();
    }
  }

  /// Get all queued operations
  Future<List<QueuedOperation>> getQueue() async {
    return _getQueue();
  }

  /// Start syncing the queue
  Future<void> syncQueue() async {
    if (_isSyncing || !await _connectivityService.isConnected()) {
      return;
    }

    _isSyncing = true;
    try {
      final queue = await _getQueue();
      if (queue.isEmpty) {
        return;
      }

      for (final operation in queue.toList()) {
        try {
          await _processOperation(operation);
          queue.remove(operation);
        } catch (e) {
          // Handle retry logic
          if (operation.retryCount < _maxRetries) {
            final updatedOperation = operation.copyWith(
              retryCount: operation.retryCount + 1,
            );
            queue[queue.indexOf(operation)] = updatedOperation;
          } else {
            // Operation failed after max retries
            queue.remove(operation);
            await _handleFailedOperation(operation);
          }
        }
      }

      await _saveQueue(queue);
    } finally {
      _isSyncing = false;
      _scheduleNextSync();
    }
  }

  void _scheduleNextSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer(_retryDelay, syncQueue);
  }

  Future<List<QueuedOperation>> _getQueue() async {
    final data = _box.get(_queueKey);
    if (data == null) return [];

    final List<dynamic> jsonList = data;
    return jsonList
        .map((json) => QueuedOperation.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveQueue(List<QueuedOperation> queue) async {
    await _box.put(_queueKey, queue.map((op) => op.toJson()).toList());
  }

  Future<void> _processOperation(QueuedOperation operation) async {
    // Implement specific operation processing logic here
    switch (operation.type) {
      case 'upload_image':
        // Handle image upload
        break;
      case 'delete_image':
        // Handle image deletion
        break;
      case 'update_status':
        // Handle status update
        break;
      default:
        throw Exception('Unknown operation type: ${operation.type}');
    }
  }

  Future<void> _handleFailedOperation(QueuedOperation operation) async {
    // Implement failed operation handling (e.g., logging, notifications)
  }

  void dispose() {
    _syncTimer?.cancel();
  }
}
