import 'package:vegavision/features/image_editor/models/edit_request.dart';
import 'package:vegavision/shared/models/marker.dart';
import 'package:vegavision/shared/repositories/edit_repository.dart';
import 'package:vegavision/shared/services/gemini_service.dart';

class EditorService {
  final EditRepository _editRepository;
  final GeminiService _geminiService;

  EditorService({
    required EditRepository editRepository,
    required GeminiService geminiService,
  }) : _editRepository = editRepository,
       _geminiService = geminiService;

  Future<String> createEditRequest({
    required String imagePath,
    required String instruction,
    required List<Marker> markers,
  }) async {
    // Validate the instruction with Gemini
    final refinedInstruction = await _geminiService.refineInstruction(
      instruction,
    );

    // Create and save the edit request
    final request = EditRequest(
      imagePath: imagePath,
      instruction: refinedInstruction,
      markers: markers,
      status: EditRequestStatus.pending,
      createdAt: DateTime.now(),
    );

    return await _editRepository.createEditRequest(request);
  }

  Future<void> validateMarkers(List<Marker> markers) async {
    if (markers.isEmpty) {
      throw Exception('At least one marker is required');
    }

    // Additional marker validation logic
    for (final marker in markers) {
      if (!_isValidMarker(marker)) {
        throw Exception('Invalid marker configuration');
      }
    }
  }

  bool _isValidMarker(Marker marker) {
    // Add marker validation logic
    if (marker.points.isEmpty) {
      return false;
    }

    // Check if marker points form a valid shape
    switch (marker.type) {
      case MarkerType.polygon:
        return marker.points.length >= 3;
      case MarkerType.rectangle:
        return marker.points.length == 4;
      case MarkerType.point:
        return marker.points.length == 1;
      default:
        return false;
    }
  }

  Future<List<String>> getSuggestedInstructions(String imagePath) async {
    try {
      // Use Gemini to analyze the image and suggest edits
      return await _geminiService.suggestEdits(imagePath);
    } catch (e) {
      throw Exception('Failed to generate edit suggestions: $e');
    }
  }

  Future<void> cancelEditRequest(String requestId) async {
    await _editRepository.updateEditRequestStatus(
      requestId,
      EditRequestStatus.cancelled,
    );
  }
}
