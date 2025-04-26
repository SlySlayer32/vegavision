import 'package:cloud_functions/cloud_functions.dart';

enum VisionFeatureType {
  labelDetection,
  objectDetection,
  objectLocalization,
  imageProperties,
  faceDetection,
  textDetection,
}

class VisionRequestOptions {
  VisionRequestOptions({this.maxResults = 10, this.confidenceThreshold = 0.5});

  final int maxResults;
  final double confidenceThreshold;

  Map<String, dynamic> toJson() {
    return {
      'maxResults': maxResults,
      'confidenceThreshold': confidenceThreshold,
    };
  }
}

class VisionService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<Map<String, dynamic>?> analyzeImage(
    String imagePath, {
    List<VisionFeatureType> features = const [
      VisionFeatureType.objectDetection,
    ],
    VisionRequestOptions? options,
  }) async {
    try {
      final callable = _functions.httpsCallable('analyzeImage');

      final result =
          await callable<Map<String, dynamic>, Map<String, dynamic>>({
            'imagePath': imagePath,
            'features':
                features.map((f) => f.toString().split('.').last).toList(),
            'options': options?.toJson(),
          });

      return result.data;
    } catch (e) {
      print('Vision API error: $e');
      return null;
    }
  }
}
