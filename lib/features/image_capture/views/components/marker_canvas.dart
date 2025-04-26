import 'package:flutter/material.dart';
import 'package:vegavision/features/image_capture/models/image_marker.dart';

class MarkerCanvas extends StatelessWidget {
  final List<ImageMarker> markers;
  final Function(ImageMarker)? onMarkerTapped;
  final Function(Offset)? onTapAdd;
  final bool isEditable;

  const MarkerCanvas({
    required this.markers,
    this.onMarkerTapped,
    this.onTapAdd,
    this.isEditable = true,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: isEditable && onTapAdd != null ? _handleTapUp : null,
      child: CustomPaint(
        painter: MarkerPainter(markers: markers),
        child: Stack(
          children: markers.map((marker) => _buildMarker(marker)).toList(),
        ),
      ),
    );
  }

  void _handleTapUp(TapUpDetails details) {
    onTapAdd?.call(details.localPosition);
  }

  Widget _buildMarker(ImageMarker marker) {
    return Positioned(
      left: marker.position.dx - marker.size / 2,
      top: marker.position.dy - marker.size / 2,
      child: GestureDetector(
        onTap: () => onMarkerTapped?.call(marker),
        child: Container(
          width: marker.size,
          height: marker.size,
          decoration: BoxDecoration(
            color: marker.color.withOpacity(0.5),
            shape: BoxShape.circle,
            border: Border.all(color: marker.color, width: 2),
          ),
          child:
              marker.label != null
                  ? Center(
                    child: Text(
                      marker.label!,
                      style: TextStyle(
                        color: marker.color,
                        fontSize: marker.size * 0.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                  : null,
        ),
      ),
    );
  }
}

class MarkerPainter extends CustomPainter {
  final List<ImageMarker> markers;

  MarkerPainter({required this.markers});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    // Draw connecting lines between markers if needed
    for (var i = 0; i < markers.length - 1; i++) {
      paint.color = markers[i].color.withOpacity(0.5);
      canvas.drawLine(markers[i].position, markers[i + 1].position, paint);
    }
  }

  @override
  bool shouldRepaint(MarkerPainter oldDelegate) {
    return oldDelegate.markers != markers;
  }
}
