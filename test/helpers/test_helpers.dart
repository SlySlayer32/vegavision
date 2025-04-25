import 'package:mockito/annotations.dart';
import 'package:vegavision/core/di/database_interface.dart';
import 'package:vegavision/repositories/edit_repository.dart';
import 'package:vegavision/repositories/image_repository.dart';
import 'package:vegavision/services/gemini_service.dart';
import 'package:vegavision/services/storage_service.dart';
import 'package:vegavision/services/vision_service.dart';

part 'test_helpers.mocks.dart';

@GenerateMocks([
  Database,
  EditRepository,
  ImageRepository,
  StorageService,
  VisionService,
  GeminiService,
])
void main() {}
