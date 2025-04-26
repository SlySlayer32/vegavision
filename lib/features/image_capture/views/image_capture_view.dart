import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:vegavision/core/base/views/base_view.dart';
import 'package:vegavision/core/widgets/error_widget.dart';
import 'package:vegavision/core/widgets/loading_widget.dart';
import 'package:vegavision/features/image_capture/view_models/image_capture_viewmodel.dart';
import 'package:vegavision/features/image_capture/views/components/marker_canvas.dart';
import 'package:vegavision/core/navigation/routes.dart';

class ImageCaptureView extends StatelessWidget {
  const ImageCaptureView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseView<ImageCaptureViewModel>(
      onModelReady: (model) => model.initializeCamera(),
      builder: (context, viewModel) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Capture Image'),
            actions: _buildActions(viewModel),
          ),
          body: _buildBody(context, viewModel),
        );
      },
    );
  }

  List<Widget> _buildActions(ImageCaptureViewModel viewModel) {
    if (!viewModel.isInitialized) return [];

    return [
      IconButton(
        icon: const Icon(Icons.switch_camera),
        onPressed: viewModel.switchCamera,
        tooltip: 'Switch Camera',
      ),
      IconButton(
        icon: const Icon(Icons.photo_library),
        onPressed: viewModel.pickImageFromGallery,
        tooltip: 'Choose from Gallery',
      ),
    ];
  }

  Widget _buildBody(BuildContext context, ImageCaptureViewModel viewModel) {
    if (!viewModel.isInitialized) {
      return const AppLoadingWidget(message: 'Initializing camera...');
    }

    if (viewModel.hasError) {
      return AppErrorWidget(
        message: viewModel.errorMessage ?? 'An error occurred',
        onRetry: viewModel.retry,
      );
    }

    return Column(
      children: [
        Expanded(child: _buildPreview(viewModel)),
        _buildControls(context, viewModel),
      ],
    );
  }

  Widget _buildPreview(ImageCaptureViewModel viewModel) {
    if (viewModel.capturedImage != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(viewModel.capturedImage!, fit: BoxFit.cover),
          if (viewModel.markers.isNotEmpty)
            MarkerCanvas(
              markers: viewModel.markers,
              onMarkerTapped: viewModel.onMarkerTapped,
            ),
        ],
      );
    }

    if (viewModel.controller == null) {
      return const Center(child: Text('Camera not available'));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: AspectRatio(
        aspectRatio: viewModel.controller!.value.aspectRatio,
        child: CameraPreview(viewModel.controller!),
      ),
    );
  }

  Widget _buildControls(BuildContext context, ImageCaptureViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (viewModel.capturedImage != null) ...[
              ElevatedButton.icon(
                onPressed: viewModel.resetCapture,
                icon: const Icon(Icons.refresh),
                label: const Text('Retake'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _navigateToEditor(context, viewModel),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continue'),
              ),
            ] else
              FloatingActionButton(
                onPressed: viewModel.isLoading ? null : viewModel.captureImage,
                child:
                    viewModel.isLoading
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.camera_alt, size: 32),
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToEditor(
    BuildContext context,
    ImageCaptureViewModel viewModel,
  ) {
    if (viewModel.imageId != null) {
      Navigator.pushNamed(
        context,
        Routes.imageEditorView,
        arguments: {'imageId': viewModel.imageId},
      );
    }
  }
}
