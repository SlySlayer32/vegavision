import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vegavision/models/edit_request.dart';
import 'package:vegavision/models/edit_result.dart';
import 'package:vegavision/models/image_model.dart';

/// Initialize Hive for the application
Future<void> initializeHive() async {
  // Initialize Hive
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);

  // Register adapters
  Hive.registerAdapter(ImageModelAdapter());
  Hive.registerAdapter(EditRequestAdapter());
  Hive.registerAdapter(EditResultAdapter());
  Hive.registerAdapter(ImageStatusAdapter());

  // Open boxes
  await Future.wait([
    Hive.openBox('cache'),
    Hive.openBox('offline_queue'),
    Hive.openBox<ImageModel>('images'),
    Hive.openBox<EditRequest>('edit_requests'),
    Hive.openBox<EditResult>('edit_results'),
  ]);
}
