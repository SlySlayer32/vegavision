import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vegavision/core/di/locator.dart';
import 'package:vegavision/viewmodels/image_capture_viewmodel.dart';
import 'package:vegavision/views/image_editor/image_editor_view.dart';

class ImageCaptureView extends StatefulWidget {
  const ImageCaptureView({super.key});

  @override
  State<ImageCaptureView> createState() => _ImageCaptureViewState();
}

class _ImageCaptureViewState extends State<ImageCaptureView> with WidgetsBindingObserver {
  late ImageCaptureViewModel _viewModel;
  bool _showControls = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _viewModel = getIt<ImageCaptureViewModel>();
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _viewModel.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    await _viewModel.initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<ImageCaptureViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('AI Image Editor'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.photo_library),
                  onPressed: viewModel.isBusy ? null : _pickImageFromGallery,
                  tooltip: 'Choose from gallery',
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed:
                      viewModel.isBusy ||
                              !viewModel.isInitialized ||
                              viewModel.capturedImage != null
                          ? null
                          : () => setState(() => _showControls = !_showControls),
                  tooltip: 'Camera settings',
                ),
              ],
            ),
            body: _buildBody(viewModel),
            floatingActionButton:
                viewModel.isInitialized && viewModel.capturedImage == null
                    ? FloatingActionButton(
                      onPressed: viewModel.isBusy ? null : () => _captureImage(viewModel),
                      child: const Icon(Icons.camera_alt),
                    )
                    : null,
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          );
        },
      ),
    );
  }

  Widget _buildBody(ImageCaptureViewModel viewModel) {
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
            ElevatedButton(onPressed: _initializeCamera, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (viewModel.isBusy) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!viewModel.isInitialized) {
      return const Center(child: Text('Initializing camera...'));
    }

    if (viewModel.capturedImage != null) {
      return _buildCapturedImageView(viewModel);
    }

    return _buildCameraPreview(viewModel);
  }

  Widget _buildCameraPreview(ImageCaptureViewModel viewModel) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        ClipRect(
          child: Container(
            color: Colors.black,
            child: Center(child: CameraPreview(viewModel.controller!)),
          ),
        ),

        // Camera controls overlay
        if (_showControls) _buildCameraControls(viewModel),

        // Flash indicator
        if (viewModel.settings.flashMode != FlashMode.off)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                viewModel.settings.flashMode == FlashMode.always
                    ? Icons.flash_on
                    : Icons.flash_auto,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),

        // Instructions overlay
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Tap the camera button to capture an image',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ),

        // Camera switch button
        if (viewModel.availableCameras.length > 1)
          Positioned(
            top: 16,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
              onPressed: () => viewModel.switchCamera(),
              tooltip: 'Switch camera',
            ),
          ),
      ],
    );
  }

  Widget _buildCameraControls(ImageCaptureViewModel viewModel) {
    return Container(
      color: Colors.black54,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => setState(() => _showControls = false),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Flash mode
                    const Text(
                      'Flash',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFlashModeButton(viewModel, FlashMode.off, 'Off', Icons.flash_off),
                        _buildFlashModeButton(viewModel, FlashMode.auto, 'Auto', Icons.flash_auto),
                        _buildFlashModeButton(viewModel, FlashMode.always, 'On', Icons.flash_on),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Resolution
                    const Text(
                      'Resolution',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildResolutionButton(viewModel, ResolutionPreset.low, 'Low'),
                        _buildResolutionButton(viewModel, ResolutionPreset.medium, 'Medium'),
                        _buildResolutionButton(viewModel, ResolutionPreset.high, 'High'),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Zoom control
                    const Text(
                      'Zoom',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderThemeData(
                        thumbColor: Colors.white,
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white.withOpacity(0.3),
                      ),
                      child: Slider(
                        min: 1.0,
                        max: viewModel.maxZoomLevel,
                        value: viewModel.settings.zoomLevel,
                        onChanged: (value) => viewModel.setZoom(value),
                        label: '${viewModel.settings.zoomLevel.toStringAsFixed(1)}x',
                        divisions: (viewModel.maxZoomLevel - 1.0).round() * 2,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Exposure control
                    const Text(
                      'Exposure',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderThemeData(
                        thumbColor: Colors.white,
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white.withOpacity(0.3),
                      ),
                      child: Slider(
                        min: viewModel.minExposureOffset,
                        max: viewModel.maxExposureOffset,
                        value: viewModel.settings.exposureOffset,
                        onChanged: (value) => viewModel.setExposureOffset(value),
                        label: viewModel.settings.exposureOffset.toStringAsFixed(1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashModeButton(
    ImageCaptureViewModel viewModel,
    FlashMode mode,
    String label,
    IconData icon,
  ) {
    final isSelected = viewModel.settings.flashMode == mode;

    return InkWell(
      onTap: () => viewModel.setFlashMode(mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildResolutionButton(
    ImageCaptureViewModel viewModel,
    ResolutionPreset resolution,
    String label,
  ) {
    final isSelected = viewModel.settings.resolution == resolution;

    return InkWell(
      onTap: () => viewModel.setResolution(resolution),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildCapturedImageView(ImageCaptureViewModel viewModel) {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.black,
            child: Center(
              child: Image.file(File(viewModel.capturedImage!.localPath), fit: BoxFit.contain),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => viewModel.resetCapture(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retake'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _navigateToEditor(viewModel.capturedImage!.id),
                icon: const Icon(Icons.edit),
                label: const Text('Edit Image'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _captureImage(ImageCaptureViewModel viewModel) async {
    await viewModel.captureImage();
  }

  Future<void> _pickImageFromGallery() async {
    await _viewModel.pickImageFromGallery();
  }

  void _navigateToEditor(String imageId) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => ImageEditorView(imageId: imageId)));
  }
}
