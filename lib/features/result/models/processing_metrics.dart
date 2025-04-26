import 'package:hive/hive.dart';

part 'processing_metrics.g.dart';

@HiveType(typeId: 7)
class ProcessingMetrics {
  const ProcessingMetrics({
    required this.segmentCount,
    required this.averageConfidence,
    required this.totalPixelsProcessed,
    this.componentMetrics,
  });

  factory ProcessingMetrics.fromJson(Map<String, dynamic> json) {
    return ProcessingMetrics(
      segmentCount: json['segmentCount'] as int,
      averageConfidence: json['averageConfidence'] as double,
      totalPixelsProcessed: json['totalPixelsProcessed'] as int,
      componentMetrics: (json['componentMetrics'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as double)),
    );
  }
  @HiveField(0)
  final int segmentCount;

  @HiveField(1)
  final double averageConfidence;

  @HiveField(2)
  final int totalPixelsProcessed;

  @HiveField(3)
  final Map<String, double>? componentMetrics;

  Map<String, dynamic> toJson() {
    return {
      'segmentCount': segmentCount,
      'averageConfidence': averageConfidence,
      'totalPixelsProcessed': totalPixelsProcessed,
      'componentMetrics': componentMetrics,
    };
  }
}
