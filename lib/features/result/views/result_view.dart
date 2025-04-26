import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:vegavision/core/base/base_view.dart';
import 'package:vegavision/features/result/models/edit_result_status.dart';
import 'package:vegavision/features/result/view_models/result_viewmodel.dart';

class ResultView extends BaseView<ResultViewModel> {
  final String editRequestId;
  final String imageId;

  const ResultView({
    Key? key,
    required this.editRequestId,
    required this.imageId,
  }) : super(key: key);

  @override
  ResultViewModel createViewModel(BuildContext context) {
    return GetIt.I.get<ResultViewModel>()..loadResult(editRequestId, imageId);
  }

  @override
  Widget buildView(BuildContext context, ResultViewModel viewModel) {
    final result = viewModel.result;
    final originalImage = viewModel.originalImage;

    if (result == null || originalImage == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Result'),
        actions: [
          if (result.status == EditResultStatus.completed)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: viewModel.saveResult,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildImageComparison(
                  originalImage.path,
                  result.outputImagePath,
                ),
                const SizedBox(height: 16),
                _buildResultDetails(result),
              ],
            ),
          ),
          _buildBottomActions(context, result),
        ],
      ),
    );
  }

  Widget _buildImageComparison(String originalPath, String resultPath) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [const Text('Original'), Image.network(originalPath)],
          ),
        ),
        Expanded(
          child: Column(
            children: [const Text('Result'), Image.network(resultPath)],
          ),
        ),
      ],
    );
  }

  Widget _buildResultDetails(EditResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${result.status}'),
            const SizedBox(height: 8),
            Text('Processing Time: ${result.processingDuration?.inSeconds}s'),
            if (result.error != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error: ${result.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, EditResult result) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
          if (result.status == EditResultStatus.completed)
            ElevatedButton(
              onPressed: () {
                // Navigate to share/export
              },
              child: const Text('Share'),
            ),
        ],
      ),
    );
  }
}
