import 'package:get_it/get_it.dart';
import 'package:vegavision/core/di/database_interface.dart';
import 'package:vegavision/core/di/hive_database.dart';
import 'package:vegavision/repositories/edit_repository.dart';
import 'package:vegavision/repositories/image_repository.dart';
import 'package:vegavision/services/camera_service.dart';
import 'package:vegavision/services/gemini_service.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Services - Singleton instances
  final database = HiveDatabase();
  await database.initialize();
  getIt.registerSingleton<Database>(database);

  final storageService = StorageService();
  await storageService.initialize();
  getIt.registerSingleton<StorageService>(storageService);

  getIt.registerSingleton<GeminiService>(GeminiService());
  getIt.registerLazySingleton<CameraService>(() => CameraServiceImpl());

  // Repositories
  getIt.registerLazySingleton<ImageRepository>(
    () => ImageRepositoryImpl(getIt<StorageService>(), getIt<Database>()),
  );

  getIt.registerLazySingleton<EditRepository>(() => EditRepositoryImpl(getIt<Database>()));

  // TODO: Register ViewModels that are referenced in the project but missing from DI
  // Example:
  // getIt.registerFactory<ImageCaptureViewModel>(
  //   () => ImageCaptureViewModel(getIt<CameraService>(), getIt<ImageRepository>())
  // );
}
// Improved version with better organization and error handling

final getIt = GetIt.instance;

/// Sets up all dependencies for the application
/// Throws [Exception] if initialization fails
Future<void> setupDependencies() async {
  await _registerServices();
  _registerRepositories();
  _registerViewModels();
}

/// Initialize and register all services
Future<void> _registerServices() async {
  try {
    // Database
    final database = HiveDatabase();
    await database.initialize();
    getIt.registerSingleton<Database>(database);

    // Storage
    final storageService = StorageService();
    await storageService.initialize();
    getIt.registerSingleton<StorageService>(storageService);

    // Other services
    getIt.registerSingleton<GeminiService>(GeminiService());
    getIt.registerLazySingleton<CameraService>(() => CameraServiceImpl());
  } catch (e) {
    throw Exception('Failed to initialize services: $e');
  }
}

/// Register all repositories
void _registerRepositories() {
  getIt.registerLazySingleton<ImageRepository>(
    () => ImageRepositoryImpl(
      getIt<StorageService>(),
      getIt<Database>(),
    ),
  );

  getIt.registerLazySingleton<EditRepository>(
    () => EditRepositoryImpl(
      getIt<Database>(),
    ),
  );
}

/// Register all ViewModels
void _registerViewModels() {
  // TODO: Implement ViewModel registration
  // Example:
  // getIt.registerFactory<ImageCaptureViewModel>(
  //   () => ImageCaptureViewModel(
  //     getIt<CameraService>(),
  //     getIt<ImageRepository>(),
  //   ),
  // );
}
