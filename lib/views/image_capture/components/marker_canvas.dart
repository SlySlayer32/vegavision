import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:vegavision/models/edit_request.dart';

class MarkerCanvas extends StatefulWidget {
  
  const MarkerCanvas({
    Key? key,
    required this.imagePath,
    required this.markers,
    required this.onMarkerPlaced,
    required this.onMarkerRemoved,
    this.onMarkerUpdated,
    this.onTap,
    this.currentMarkerType = MarkerType.remove,
    this.currentMarkerSize = 1.0,
    this.enableZoom = true,
    this.enableDrag = true,
  }) : super(key: key);
  final String imagePath;
  final List<Marker> markers;
  final Function(double, double) onMarkerPlaced;
  final Function(int) onMarkerRemoved;
  final Function(int, Marker)? onMarkerUpdated;
  final Function(Offset)? onTap;
  final MarkerType currentMarkerType;
  final double currentMarkerSize;
  final bool enableZoom;
  final bool enableDrag;

  @override
  _MarkerCanvasState createState() => _MarkerCanvasState();
}

class _MarkerCanvasState extends State<MarkerCanvas> with SingleTickerProviderStateMixin {
  final GlobalKey _imageKey = GlobalKey();
  
  // Image dimensions and loading state
  Size _imageSize = Size.zero;
  bool _imageLoaded = false;
  
  // Transformation variables for zoom and pan
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  
  // Selected marker for dragging
  int? _selectedMarkerIndex;
  Offset? _lastDragPosition;
  
  // Double tap zoom variables
  TapDownDetails? _doubleTapDetails;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _scheduleImageSizeCalculation();
  }
  
  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  void _scheduleImageSizeCalculation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateImageSize();
    });
  }
  
  void _calculateImageSize() {
    final RenderBox? renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      setState(() {
        _imageSize = renderBox.size;
        _imageLoaded = true;
      });
    } else {
      // Try again next frame if render box isn't ready
      _scheduleImageSizeCalculation();
    }
  }
  
  // Reset the zoom level to fit the entire image
  void _resetZoom() {
    final Matrix4 matrix = Matrix4.identity();
    _transformationController.value = matrix;
  }
  
  // Handle double tap to zoom in/out
  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }
  
  void _handleDoubleTap() {
    if (_doubleTapDetails == null) return;
    
    const double zoomScale = 2.5;
    
    // Get current scale
    final Matrix4 matrix = _transformationController.value;
    final double currentScale = matrix.getMaxScaleOnAxis();
    
    // Determine the focal point for zooming
    final Offset position = _doubleTapDetails!.localPosition;
    
    // Create a new matrix for the animation
    Matrix4 newMatrix;
    
    if (currentScale > 1.5) {
      // Zoom out to original size
      newMatrix = Matrix4.identity();
    } else {
      // Zoom in to the focal point
      newMatrix = Matrix4.identity()
        ..translate(
          -position.dx * (zoomScale - 1),
          -position.dy * (zoomScale - 1),
        )
        ..scale(zoomScale);
    }
    
    // Animate to the new zoom level
    _animateTransform(newMatrix);
  }
  
  // Animate between transformation matrices
  void _animateTransform(Matrix4 endMatrix) {
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Listen to animation updates
    _animationController.addListener(() {
      if (_animation != null) {
        _transformationController.value = _animation!.value;
      }
    });
    
    // Reset the animation controller and start the animation
    _animationController.reset();
    _animationController.forward();
  }
  
  // Convert page coordinates to image-relative coordinates (0-1 range)
  Offset _pageToImageCoordinates(Offset pagePosition) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(pagePosition);
    
    // Apply inverse transform to get coordinates in the untransformed space
    final Matrix4 inverseMatrix = Matrix4.inverted(_transformationController.value);
    final Vector3 untransformedPoint = inverseMatrix.transform3(Vector3(
      localPosition.dx,
      localPosition.dy,
      0,
    ));
    
    // Convert to relative coordinates (0-1 range)
    final double relativeX = untransformedPoint.x / _imageSize.width;
    final double relativeY = untransformedPoint.y / _imageSize.height;
    
    return Offset(relativeX, relativeY);
  }
  
  // Convert image-relative coordinates (0-1 range) to widget coordinates
  Offset _imageToWidgetCoordinates(double x, double y) {
    return Offset(
      x * _imageSize.width,
      y * _imageSize.height,
    );
  }
  
  // Handle tap on the canvas to place a new marker
  void _handleTap(TapUpDetails details) {
    if (!_imageLoaded || _imageSize == Size.zero) return;
    
    // Convert tap position to image-relative coordinates
    final Offset relativePosition = _pageToImageCoordinates(details.globalPosition);
    
    // Ensure within bounds
    if (relativePosition.dx >= 0 && relativePosition.dx <= 1 && 
        relativePosition.dy >= 0 && relativePosition.dy <= 1) {
      
      // Check if we tapped on an existing marker
      final int? tappedMarkerIndex = _getTappedMarkerIndex(details.globalPosition);
      
      if (tappedMarkerIndex != null) {
        // Tapped on an existing marker, remove it
        widget.onMarkerRemoved(tappedMarkerIndex);
      } else {
        // Add a new marker
        widget.onMarkerPlaced(relativePosition.dx, relativePosition.dy);
      }
      
      // Notify about tap location if listener is provided
      if (widget.onTap != null) {
        widget.onTap!(relativePosition);
      }
    }
  }
  
  // Get the index of a tapped marker, or null if none was tapped
  int? _getTappedMarkerIndex(Offset globalPosition) {
    if (!_imageLoaded || _imageSize == Size.zero) return null;
    
    // Convert to image-relative coordinates
    final Offset relativePosition = _pageToImageCoordinates(globalPosition);
    
    // Check if the tap is within any marker's hit area
    for (int i = widget.markers.length - 1; i >= 0; i--) {
      final marker = widget.markers[i];
      final Offset markerPosition = Offset(marker.x, marker.y);
      
      // Calculate distance from tap to marker center
      final double distance = (markerPosition - relativePosition).distance;
      
      // Adjust hit area based on marker size and zoom level
      final double hitRadius = 0.03 * marker.size;
      
      if (distance <= hitRadius) {
        return i;
      }
    }
    
    return null;
  }
  
  // Start dragging a marker
  void _handleDragStart(DragStartDetails details) {
    if (!widget.enableDrag || !_imageLoaded || _imageSize == Size.zero) return;
    
    // Check if we're dragging an existing marker
    final int? markerIndex = _getTappedMarkerIndex(details.globalPosition);
    
    if (markerIndex != null) {
      setState(() {
        _selectedMarkerIndex = markerIndex;
        _lastDragPosition = details.globalPosition;
      });
    }
  }
  
  // Update marker position during drag
  void _handleDragUpdate(DragUpdateDetails details) {
    if (_selectedMarkerIndex == null || _lastDragPosition == null) return;
    
    // Calculate delta in image-relative coordinates
    final Offset oldPosition = _pageToImageCoordinates(_lastDragPosition!);
    final Offset newPosition = _pageToImageCoordinates(details.globalPosition);
    final Offset delta = newPosition - oldPosition;
    
    // Get the marker being dragged
    final marker = widget.markers[_selectedMarkerIndex!];
    
    // Calculate new position
    final double newX = (marker.x + delta.dx).clamp(0.0, 1.0);
    final double newY = (marker.y + delta.dy).clamp(0.0, 1.0);
    
    // Update the marker through callback
    if (widget.onMarkerUpdated != null) {
      final updatedMarker = Marker(
        id: marker.id,
        x: newX,
        y: newY,
        type: marker.type,
        size: marker.size,
        label: marker.label,
      );
      
      widget.onMarkerUpdated!(_selectedMarkerIndex!, updatedMarker);
    }
    
    // Update last position
    _lastDragPosition = details.globalPosition;
  }
  
  // End dragging a marker
  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      _selectedMarkerIndex = null;
      _lastDragPosition = null;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: _handleTap,
      onDoubleTapDown: widget.enableZoom ? _handleDoubleTapDown : null,
      onDoubleTap: widget.enableZoom ? _handleDoubleTap : null,
      onPanStart: _handleDragStart,
      onPanUpdate: _handleDragUpdate,
      onPanEnd: _handleDragEnd,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Zoomable and pannable container
          InteractiveViewer(
            transformationController: _transformationController,
            panEnabled: widget.enableZoom,
            scaleEnabled: widget.enableZoom,
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.file(
              File(widget.imagePath),
              key: _imageKey,
              fit: BoxFit.contain,
            ),
          ),
          
          // Markers overlay
          if (_imageLoaded) ..._buildMarkers(),
          
          // Reset zoom button
          if (widget.enableZoom)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                mini: true,
                onPressed: _resetZoom,
                backgroundColor: Colors.white.withOpacity(0.8),
                foregroundColor: Colors.black87,
                child: const Icon(Icons.zoom_out_map),
              ),
            ),
          
          // Instructions overlay
          if (widget.markers.isEmpty)
            const Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Tap on the image to place markers on objects you want to edit',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  List<Widget> _buildMarkers() {
    return widget.markers.asMap().entries.map((entry) {
      final index = entry.key;
      final marker = entry.value;
      
      // Convert marker position to widget coordinates
      final Offset position = _imageToWidgetCoordinates(marker.x, marker.y);
      
      // Apply current transformation
      final Matrix4 matrix = _transformationController.value;
      final Vector3 transformedPoint = matrix.transform3(Vector3(position.dx, position.dy, 0));
      
      // Determine marker color based on type
      Color markerColor;
      IconData markerIcon;
      
      switch (marker.type) {
        case MarkerType.remove:
          markerColor = Colors.red;
          markerIcon = Icons.close;
          break;
        case MarkerType.replace:
          markerColor = Colors.blue;
          markerIcon = Icons.swap_horiz;
          break;
        case MarkerType.modify:
          markerColor = Colors.orange;
          markerIcon = Icons.edit;
          break;
        case MarkerType.enhance:
          markerColor = Colors.green;
          markerIcon = Icons.auto_fix_high;
          break;
      }
      
      // Calculate marker size based on marker size property and current transformation scale
      final double scale = matrix.getMaxScaleOnAxis();
      final double baseSize = 30.0 * marker.size;
      final double scaledSize = baseSize / math.max(1.0, scale);
      
      return Positioned(
        left: transformedPoint.x - scaledSize / 2,
        top: transformedPoint.y - scaledSize / 2,
        child: GestureDetector(
          onTap: () => widget.onMarkerRemoved(index),
          child: Container(
            width: scaledSize,
            height: scaledSize,
            decoration: BoxDecoration(
              color: markerColor.withOpacity(0.6),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white, 
                width: 2 / math.max(1.0, scale),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4 / math.max(1.0, scale),
                  spreadRadius: 1 / math.max(1.0, scale),
                ),
              ],
            ),
            child: Icon(
              markerIcon,
              color: Colors.white,
              size: 16 * marker.size / math.max(1.0, scale),
            ),
          ),
        ),
      );
    }).toList();
  }
}