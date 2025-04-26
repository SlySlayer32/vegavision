import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:vegavision/core/services/cache_service.dart';
import 'package:vegavision/core/services/connectivity_service.dart';
import 'package:vegavision/core/services/offline_queue_service.dart';

extension ServiceLocatorExtensions on GetIt {
  Future<void> registerCoreServices() async {
    // Register core boxes
    final cacheBox = await Hive.openBox('cache');
    final queueBox = await Hive.openBox('offline_queue');

    // Register core services
    registerSingleton<Box>(cacheBox, instanceName: 'cache');
    registerSingleton<Box>(queueBox, instanceName: 'offline_queue');

    registerSingleton<ConnectivityService>(ConnectivityService());

    registerSingleton<CacheService>(
      CacheService(
        get<Box>(instanceName: 'cache'),
        defaultExpiry: const Duration(days: 1),
      ),
    );

    registerSingleton<OfflineQueueService>(
      OfflineQueueService(
        get<Box>(instanceName: 'offline_queue'),
        get<ConnectivityService>(),
        maxRetries: 3,
        retryDelay: const Duration(minutes: 5),
      ),
    );
  }
}
