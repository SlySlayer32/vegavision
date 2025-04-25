import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:vegavision/core/di/database_interface.dart';
import 'package:vegavision/core/di/hive_database.dart';
import 'package:vegavision/models/image_model.dart';
import 'package:vegavision/repositories/edit_repository.dart';
import 'package:vegavision/repositories/image_repository.dart';
import 'package:vegavision/services/camera_service.dart';
import 'package:vegavision/services/gemini_service.dart';
import 'package:vegavision/services/storage_service.dart';
import 'package:vegavision/services/vision_service.dart';
import 'package:vegavision/viewmodels/image_capture_viewmodel.dart';
import 'package:vegavision/viewmodels/image_editor_viewmodel.dart';
import 'package:vegavision/viewmodels/result_viewmodel.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Initialize Database
  final hiveDb = HiveDatabase();
  await hiveDb.initialize();
  final imagesBox = await Hive.openBox<ImageModel>('images');

  // Register core dependencies
  getIt.registerSingleton<Box<ImageModel>>(imagesBox);
  getIt.registerSingleton<Database>(hiveDb);

  // Register Services
  getIt.registerSingleton<StorageService>(StorageService());
  getIt.registerSingleton<GeminiService>(GeminiServiceImpl());
  getIt.registerSingleton<VisionService>(VisionService());
  getIt.registerLazySingleton<CameraService>(() => CameraServiceImpl());

  // Register Repositories
  getIt.registerLazySingleton<ImageRepository>(
    () => ImageRepositoryImpl(storageService: getIt<StorageService>(), database: imagesBox),
  );

  getIt.registerLazySingleton<EditRepository>(() => EditRepositoryImpl(getIt<Database>()));

  // Register ViewModels
  getIt.registerFactory<ImageCaptureViewModel>(
    () => ImageCaptureViewModel(getIt<ImageRepository>()),
  );

  getIt.registerFactory<ImageEditorViewModel>(
    () => ImageEditorViewModel(
      getIt<ImageRepository>(),
      getIt<EditRepository>(),
      getIt<StorageService>(),
    ),
  );

  getIt.registerFactoryParam<ResultViewModel, String, String>(
    (imageId, editRequestId) => ResultViewModel(
      getIt<EditRepository>(),
      getIt<ImageRepository>(),
      getIt<VisionService>(),
      getIt<GeminiService>(),
    ),
  );
}
