import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:vegavision/core/di/database_interface.dart';
import 'package:vegavision/core/di/hive_database.dart';
import 'package:vegavision/core/di/service_locator.dart';
import 'package:vegavision/shared/models/image_model.dart';
import 'package:vegavision/shared/repositories/edit_repository.dart';
import 'package:vegavision/shared/repositories/image_repository.dart';
import 'package:vegavision/shared/services/storage_service.dart';
import 'package:vegavision/shared/services/gemini_service.dart';
import 'package:vegavision/shared/services/vision_service.dart';

// Feature: Image Capture
import 'package:vegavision/features/image_capture/services/camera_service.dart';
import 'package:vegavision/features/image_capture/view_models/image_capture_viewmodel.dart';

// Feature: Image Editor
import 'package:vegavision/features/image_editor/services/editor_service.dart';
import 'package:vegavision/features/image_editor/view_models/image_editor_viewmodel.dart';

// Feature: Result
import 'package:vegavision/features/result/services/result_service.dart';
import 'package:vegavision/features/result/view_models/result_viewmodel.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Register core services
  await getIt.registerCoreServices();

  // Initialize Database
  final hiveDb = HiveDatabase();
  await hiveDb.initialize();
  final imagesBox = await Hive.openBox<ImageModel>('images');

  // Register Singleton Core Dependencies
  getIt.registerSingleton<Box<ImageModel>>(imagesBox);
  getIt.registerSingleton<Database>(hiveDb);

  // Register Shared Services
  getIt.registerSingleton<StorageService>(StorageService());
  getIt.registerSingleton<GeminiService>(GeminiServiceImpl());
  getIt.registerSingleton<VisionService>(VisionService());

  // Register Shared Repositories
  getIt.registerLazySingleton<ImageRepository>(
    () => ImageRepositoryImpl(
      storageService: getIt<StorageService>(),
      database: imagesBox,
      cacheService: getIt<CacheService>(),
      connectivityService: getIt<ConnectivityService>(),
    ),
  );

  getIt.registerLazySingleton<EditRepository>(
    () => EditRepositoryImpl(
      database: getIt<Database>(),
      cacheService: getIt<CacheService>(),
      connectivityService: getIt<ConnectivityService>(),
    ),
  );

  // Feature: Image Capture
  getIt.registerLazySingleton<CameraService>(() => CameraServiceImpl());

  getIt.registerFactory<ImageCaptureViewModel>(
    () => ImageCaptureViewModel(
      imageRepository: getIt<ImageRepository>(),
      connectivityService: getIt<ConnectivityService>(),
    ),
  );

  // Feature: Image Editor
  getIt.registerLazySingleton<EditorService>(
    () => EditorService(
      editRepository: getIt<EditRepository>(),
      geminiService: getIt<GeminiService>(),
      cacheService: getIt<CacheService>(),
    ),
  );

  getIt.registerFactory<ImageEditorViewModel>(
    () => ImageEditorViewModel(
      editorService: getIt<EditorService>(),
      imageRepository: getIt<ImageRepository>(),
      connectivityService: getIt<ConnectivityService>(),
    ),
  );

  // Feature: Result
  getIt.registerLazySingleton<ResultService>(
    () => ResultService(
      editRepository: getIt<EditRepository>(),
      visionService: getIt<VisionService>(),
      cacheService: getIt<CacheService>(),
    ),
  );

  getIt.registerFactory<ResultViewModel>(
    () => ResultViewModel(
      resultService: getIt<ResultService>(),
      imageRepository: getIt<ImageRepository>(),
      connectivityService: getIt<ConnectivityService>(),
    ),
  );
}
