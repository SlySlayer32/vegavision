import 'package:mockito/annotations.dart';
import 'package:vegavision/repositories/edit_repository.dart';
import 'package:vegavision/repositories/image_repository.dart';
import 'package:vegavision/services/gemini_service.dart';
import 'package:vegavision/services/storage_service.dart';
import 'package:vegavision/services/vision_service.dart';

// Generate mocks for all our services and repositories
@GenerateMocks([
  GeminiService,
  StorageService,
  VisionService,
  EditRepository,
  ImageRepository,
])
void main() {}
