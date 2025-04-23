import 'package:mockito/annotations.dart';
import 'package:vegavision/core/di/database_interface.dart';
import 'package:vegavision/repositories/edit_repository.dart';
import 'package:vegavision/repositories/image_repository.dart';

// This connects to the generated mock file
part 'test_helpers.mocks.dart';

@GenerateMocks([Database, EditRepository, ImageRepository])
void main() {}
