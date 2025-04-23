import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vegavision/viewmodels/image_editor_viewmodel.dart';
import 'package:vegavision/result/result_view.dart';
import 'package:vegavision/integration%20folder/components/marker_canvas.dart';
import 'package:vegavision/core/di/locator.dart';

class ImageEditorView extends StatefulWidget {

  const ImageEditorView({Key? key, required this.imageId}) : super(key: key);
  final String imageId;

  @override
  _ImageEditorViewState createState() => _ImageEditorViewState();
}

class _ImageEditorViewState extends State<ImageEditorView> {
  late ImageEditorViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<ImageEditorViewModel>();
    _loadImage();
  }

  Future<void> _loadImage() async {
    await _viewModel.loadImage(widget.imageId);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<ImageEditorViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Mark & Edit Image'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  onPressed: _showHelp,
                ),
              ],
            ),
            body: _buildBody(viewModel),
            bottomNavigationBar: viewModel.selectedImage != null 
                ? _buildBottomPanel(viewModel)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildBody(ImageEditorViewModel viewModel) {
    if (viewModel.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: ${viewModel.error}',
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadImage,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (viewModel.isBusy) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing...'),
          ],
        ),
      );
    }

    if (viewModel.selectedImage == null) {
      return const Center(
        child: Text('Loading image...'),
      );
    }

    return Column(
      children: [
        Expanded(
          child: MarkerCanvas(
            imagePath: viewModel.selectedImage!.localPath,
            markers: viewModel.markers,
            onMarkerPlaced: (x, y) => viewModel.addMarker(x, y),
            onMarkerRemoved: (index) => viewModel.removeMarker(index),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPanel(ImageEditorViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Markers placed: ${viewModel.markers.length}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Edit instruction',
              hintText: 'e.g., "remove tree", "replace sky"',
              border: OutlineInputBorder(),
              filled: true,
            ),
            maxLines: 2,
            onChanged: (value) => viewModel.setInstruction(value),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: viewModel.markers.isEmpty || viewModel.instruction.isEmpty
                ? null
                : () => _submitEditRequest(viewModel),
            icon: const Icon(Icons.send),
            label: const Text('Submit Edit Request'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to use the editor'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Tap on the image to place markers on objects you want to edit'),
            SizedBox(height: 8),
            Text('2. Tap on a marker to remove it'),
            SizedBox(height: 8),
            Text('3. Enter a clear instruction describing what you want to do'),
            SizedBox(height: 8),
            Text('4. Tap "Submit Edit Request" to process your edit'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitEditRequest(ImageEditorViewModel viewModel) async {
    if (viewModel.markers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please place at least one marker')),
      );
      return;
    }

    if (viewModel.instruction.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an edit instruction')),
      );
      return;
    }

    final editRequest = await viewModel.submitEditRequest();
    if (editRequest != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ResultView(requestId: editRequest.id),
        ),
      );
    }
  }
}

// views/image_editor/components/marker_canvas.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vegavision/models/edit_request.dart';

class MarkerCanvas extends StatefulWidget {

  const MarkerCanvas({
    Key? key,
    required this.imagePath,
    required this.markers,
    required this.onMarkerPlaced,
    required this.onMarkerRemoved,
  }) : super(key: key);
  final String imagePath;
  final List<MarkerPosition> markers;
  final Function(double, double) onMarkerPlaced;
  final Function(int) onMarkerRemoved;

  @override
  _MarkerCanvasState createState() => _MarkerCanvasState();
}

class _MarkerCanvasState extends State<MarkerCanvas> {
  final GlobalKey _imageKey = GlobalKey();
  Size _imageSize = Size.zero;
  bool _imageLoaded = false;
  
  @override
  void initState() {
    super.initState();
    _scheduleImageSizeCalculation();
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: _handleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          Image.file(
            File(widget.imagePath),
            key: _imageKey,
            fit: BoxFit.contain,
          ),
          
          // Markers overlay
          if (_imageLoaded) ..._buildMarkers(),
          
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
      
      return Positioned(
        left: marker.x * _imageSize.width,
        top: marker.y * _imageSize.height,
        child: GestureDetector(
          onTap: () => widget.onMarkerRemoved(index),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.5),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      );
    }).toList();
  }

  void _handleTap(TapUpDetails details) {
    if (!_imageLoaded || _imageSize == Size.zero) return;
    
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(details.globalPosition);
    
    // Convert to relative coordinates (0-1)
    final double relativeX = localPosition.dx / _imageSize.width;
    final double relativeY = localPosition.dy / _imageSize.height;
    
    // Ensure within bounds
    if (relativeX >= 0 && relativeX <= 1 && relativeY >= 0 && relativeY <= 1) {
      widget.onMarkerPlaced(relativeX, relativeY);
    }
  }
}