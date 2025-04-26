import 'package:vegavision/features/result/models/edit_result.dart';
import 'package:vegavision/shared/repositories/edit_repository.dart';
import 'package:vegavision/shared/services/vision_service.dart';

class ResultService {
  final EditRepository _editRepository;
  final VisionService _visionService;

  ResultService({
    required EditRepository editRepository,
    required VisionService visionService,
  }) : _editRepository = editRepository,
       _visionService = visionService;

  Future<EditResult> getEditResult(String editRequestId) async {
    return await _editRepository.getEditResult(editRequestId);
  }

  Future<void> analyzeResult(EditResult result) async {
    await _visionService.analyzeImage(result.outputImagePath);
  }

  Future<void> saveResult(EditResult result) async {
    await _editRepository.saveEditResult(result);
  }
}
