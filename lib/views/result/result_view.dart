import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:vegavision/core/di/locator.dart';
import 'package:vegavision/models/edit_request.dart';
import 'package:vegavision/models/edit_result.dart';
import 'package:vegavision/viewmodels/result_viewmodel.dart';
import 'package:vegavision/image_capture/image_capture_view.dart';

class ResultView extends StatefulWidget {

  const ResultView({Key? key, required this.requestId}) : super(key: key);
  final String requestId;

  @override
  _ResultViewState createState() => _ResultViewState();
}

class _ResultViewState extends State<ResultView> {
  late ResultViewModel _viewModel;
  
  // For comparison slider
  double _sliderPosition = 0.5;
  bool _useComparisonSlider = false;
  
  // For zooming
  final TransformationController _transformationController = TransformationController();
  
  @override
  void initState() {
    super.initState();
    _viewModel = getIt<ResultViewModel>();
    _loadEditRequest();
  }
  
  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadEditRequest() async {
    await _viewModel.loadEditRequest(widget.requestId);
    
    // If the edit hasn't been processed yet, process it
    if (_viewModel.editResult == null || 
        _viewModel.editResult!.status == EditResultStatus.pending) {
      await _viewModel.processEditRequest();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<ResultViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Edit Result'),
              actions: [
                // Settings button
                if (viewModel.editResult == null || viewModel.editResult!.status != EditResultStatus.completed)
                  PopupMenuButton<ProcessingMethod>(
                    tooltip: 'Processing Method',
                    icon: const Icon(Icons.settings),
                    onSelected: (method) {
                      viewModel.setProcessingMethod(method);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: ProcessingMethod.cloudFunction,
                        child: Text('Cloud Function'),
                      ),
                      const PopupMenuItem(
                        value: ProcessingMethod.directApi,
                        child: Text('Direct API'),
                      ),
                      const PopupMenuItem(
                        value: ProcessingMethod.mockResult,
                        child: Text('Mock Result (Demo)'),
                      ),
                    ],
                  ),
                  
                // Comparison mode button
                if (viewModel.editResult?.status == EditResultStatus.completed && 
                    viewModel.resultImageFile != null)
                  IconButton(
                    icon: Icon(
                      _useComparisonSlider ? Icons.compare : Icons.compare_arrows,
                      color: _useComparisonSlider ? Theme.of(context).colorScheme.secondary : null,
                    ),
                    onPressed: () {
                      setState(() {
                        _useComparisonSlider = !_useComparisonSlider;
                        // Reset transformation when switching modes
                        _transformationController.value = Matrix4.identity();
                      });
                    },
                    tooltip: 'Comparison Mode',
                  ),
                  
                // Home button
                IconButton(
                  icon: const Icon(Icons.home),
                  onPressed: () => _navigateToHome(),
                  tooltip: 'Back to Home',
                ),
              ],
            ),
            body: _buildBody(viewModel),
          );
        },
      ),
    );
  }

  Widget _buildBody(ResultViewModel viewModel) {
    if (viewModel.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: ${viewModel.error}',
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadEditRequest,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (viewModel.isBusy) {
      return _buildProcessingView(viewModel);
    }

    if (viewModel.editRequest == null) {
      return const Center(
        child: Text('Edit request not found'),
      );
    }

    if (viewModel.editResult == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Waiting for results...'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadEditRequest,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    if (viewModel.editResult!.status == EditResultStatus.failed) {
      return _buildFailedView(viewModel);
    }

    if (viewModel.editResult!.resultImagePath == null || viewModel.resultImageFile == null) {
      return const Center(
        child: Text('No result image available'),
      );
    }

    return _useComparisonSlider 
        ? _buildComparisonView(viewModel)
        : _buildResultView(viewModel);
  }
  
  Widget _buildProcessingView(ResultViewModel viewModel) {
    final progress = viewModel.progress;
    
    // Format time strings
    String elapsedTime = '';
    if (progress.timeElapsedMs != null) {
      final int seconds = (progress.timeElapsedMs! / 1000).round();
      elapsedTime = '${seconds}s';
    }
    
    String remainingTime = '';
    if (progress.estimatedTimeRemainingMs != null) {
      final int seconds = (progress.estimatedTimeRemainingMs! / 1000).round();
      remainingTime = '~${seconds}s remaining';
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Show different icons based on progress status
          if (progress.status == ProcessingStatus.analyzing)
            const Icon(Icons.search, color: Colors.blue, size: 48)
          else if (progress.status == ProcessingStatus.generating)
            const Icon(Icons.auto_fix_high, color: Colors.purple, size: 48)
          else if (progress.status == ProcessingStatus.downloading)
            const Icon(Icons.cloud_download, color: Colors.green, size: 48)
          else
            const CircularProgressIndicator(strokeWidth: 5),
            
          const SizedBox(height: 24),
          
          Text(
            progress.message ?? 'Processing your edit...',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          
          const SizedBox(height: 16),
          
          // Show progress bar if we have a progress value
          if (progress.progress != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: LinearProgressIndicator(
                value: progress.progress,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            
          const SizedBox(height: 8),
          
          // Show timing information
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (elapsedTime.isNotEmpty)
                Text(
                  elapsedTime,
                  style: const TextStyle(color: Colors.grey),
                ),
                
              if (elapsedTime.isNotEmpty && remainingTime.isNotEmpty)
                const Text(' • ', style: TextStyle(color: Colors.grey)),
                
              if (remainingTime.isNotEmpty)
                Text(
                  remainingTime,
                  style: const TextStyle(color: Colors.grey),
                ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Cancel button
          ElevatedButton.icon(
            onPressed: () => viewModel.cancelProcessing(),
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[700],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFailedView(ResultViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.orange,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Edit processing failed',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              viewModel.editResult!.errorMessage ?? 'Unknown error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => viewModel.processEditRequest(),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView(ResultViewModel viewModel) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Instruction
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Edit Instruction:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            viewModel.editRequest!.instruction,
                            style: const TextStyle(fontSize: 16),
                          ),
                          
                          if (viewModel.editResult!.processingTimeMs != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                'Processing Time: ${(viewModel.editResult!.processingTimeMs! / 1000).toStringAsFixed(1)}s',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Before/After tabs
                DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [
                          Tab(text: 'BEFORE'),
                          Tab(text: 'AFTER'),
                        ],
                        labelColor: Colors.black87,
                        unselectedLabelColor: Colors.grey,
                      ),
                      SizedBox(
                        height: 400,
                        child: TabBarView(
                          children: [
                            // Before (Original Image)
                            InteractiveViewer(
                              transformationController: _transformationController,
                              child: viewModel.originalImageFile != null
                                ? Image.file(
                                    viewModel.originalImageFile!,
                                    fit: BoxFit.contain,
                                  )
                                : const Center(child: Text('Original image not available')),
                            ),
                            
                            // After (Result Image)
                            InteractiveViewer(
                              transformationController: _transformationController,
                              child: Image.file(
                                viewModel.resultImageFile!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Bottom Action Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                onPressed: _navigateToHome,
                icon: const Icon(Icons.camera_alt),
                label: const Text('New Image'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _saveImage(viewModel.editResult!.resultImagePath!),
                icon: const Icon(Icons.save_alt),
                label: const Text('Save to Gallery'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _shareImage(viewModel.editResult!.resultImagePath!),
                tooltip: 'Share',
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildComparisonView(ResultViewModel viewModel) {
    if (viewModel.originalImageFile == null || viewModel.resultImageFile == null) {
      return const Center(child: Text('Images not available for comparison'));
    }
    
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              // Interactively zoomable container
              InteractiveViewer(
                transformationController: _transformationController,
                child: SizedBox.expand(
                  child: Stack(
                    children: [
                      // "After" image (full)
                      Image.file(
                        viewModel.resultImageFile!,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      
                      // "Before" image (clipped to slider position)
                      Positioned.fill(
                        child: ClipRect(
                          clipper: _HorizontalClipper(_sliderPosition),
                          child: Image.file(
                            viewModel.originalImageFile!,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                      
                      // Slider divider line
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _SliderDividerPainter(_sliderPosition),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Slider control
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SliderTheme(
                    data: SliderThemeData(
                      thumbColor: Colors.white,
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white.withOpacity(0.5),
                      overlayColor: Colors.white.withOpacity(0.3),
                    ),
                    child: Slider(
                      value: _sliderPosition,
                      onChanged: (value) {
                        setState(() {
                          _sliderPosition = value;
                        });
                      },
                    ),
                  ),
                ),
              ),
              
              // Labels
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'BEFORE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'AFTER',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Bottom Action Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                onPressed: _navigateToHome,
                icon: const Icon(Icons.camera_alt),
                label: const Text('New Image'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _saveImage(viewModel.editResult!.resultImagePath!),
                icon: const Icon(Icons.save_alt),
                label: const Text('Save to Gallery'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _shareImage(viewModel.editResult!.resultImagePath!),
                tooltip: 'Share',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveImage(String imagePath) async {
    try {
      final result = await ImageGallerySaver.saveFile(imagePath);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Image saved to gallery'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save image: $e'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _shareImage(String imagePath) async {
    try {
      await Share.shareFiles(
        [imagePath],
        text: 'Check out this image I edited with AI Image Editor!',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share image: $e'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const ImageCaptureView()),
      (route) => false,
    );
  }
}

// Custom clipper for the comparison slider
class _HorizontalClipper extends CustomClipper<Rect> {
  
  _HorizontalClipper(this.position);
  final double position;
  
  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width * position, size.height);
  }
  
  @override
  bool shouldReclip(_HorizontalClipper oldClipper) {
    return position != oldClipper.position;
  }
}

// Custom painter for the slider divider
class _SliderDividerPainter extends CustomPainter {
  
  _SliderDividerPainter(this.position);
  final double position;
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final x = size.width * position;
    
    // Draw divider line with shadow
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      shadowPaint,
    );
    
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      paint,
    );
    
    // Draw handles at top, middle, and bottom
    const handleRadius = 12.0;
    
    // Draw handle shadows
    canvas.drawCircle(
      Offset(x, size.height * 0.5),
      handleRadius + 2,
      Paint()..color = Colors.black.withOpacity(0.5),
    );
    
    // Draw handles
    canvas.drawCircle(
      Offset(x, size.height * 0.5),
      handleRadius,
      Paint()..color = Colors.white,
    );
    
    // Draw arrows inside the handle
    final arrowPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    // Left arrow
    canvas.drawLine(
      Offset(x - 5, size.height * 0.5),
      Offset(x - 2, size.height * 0.5 - 3),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(x - 5, size.height * 0.5),
      Offset(x - 2, size.height * 0.5 + 3),
      arrowPaint,
    );
    
    // Right arrow
    canvas.drawLine(
      Offset(x + 5, size.height * 0.5),
      Offset(x + 2, size.height * 0.5 - 3),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(x + 5, size.height * 0.5),
      Offset(x + 2, size.height * 0.5 + 3),
      arrowPaint,
    );
  }
  
  @override
  bool shouldRepaint(_SliderDividerPainter oldPainter) {
    return position != oldPainter.position;
  }
}