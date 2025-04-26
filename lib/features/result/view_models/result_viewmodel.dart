import 'package:vegavision/core/base/base_view_model.dart';
import 'package:vegavision/features/result/models/edit_result.dart';
import 'package:vegavision/features/result/services/result_service.dart';
import 'package:vegavision/shared/models/image_model.dart';
import 'package:vegavision/shared/repositories/image_repository.dart';

class ResultViewModel extends BaseViewModel {
  final ResultService _resultService;
  final ImageRepository _imageRepository;

  EditResult? _result;
  ImageModel? _originalImage;

  ResultViewModel({
    required ResultService resultService,
    required ImageRepository imageRepository,
  }) : _resultService = resultService,
       _imageRepository = imageRepository;

  EditResult? get result => _result;
  ImageModel? get originalImage => _originalImage;

  Future<void> loadResult(String editRequestId, String imageId) async {
    try {
      setLoading(true);

      // Load result and original image in parallel
      final resultsFuture = _resultService.getEditResult(editRequestId);
      final imageFuture = _imageRepository.getImage(imageId);

      final results = await Future.wait([resultsFuture, imageFuture]);

      _result = results[0] as EditResult;
      _originalImage = results[1] as ImageModel;

      // Analyze result if available
      if (_result != null) {
        await _resultService.analyzeResult(_result!);
      }

      notifyListenersIfNotDisposed();
    } catch (e, stack) {
      await handleError(e, stack, context: 'ResultViewModel.loadResult');
    } finally {
      setLoading(false);
    }
  }

  Future<void> saveResult() async {
    if (_result == null) return;

    try {
      setLoading(true);
      await _resultService.saveResult(_result!);
      notifyListenersIfNotDisposed();
    } catch (e, stack) {
      await handleError(e, stack, context: 'ResultViewModel.saveResult');
    } finally {
      setLoading(false);
    }
  }
}
