import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vegavision/core/base/base_view_model.dart';
import 'package:vegavision/core/widgets/error_widget.dart';
import 'package:vegavision/core/widgets/loading_widget.dart';

/// Base view that handles common view functionality like loading and error states
class BaseView<T extends BaseViewModel> extends StatelessWidget {
  final Widget Function(BuildContext context, T viewModel) builder;
  final Function(T)? onModelReady;
  final bool handleLoading;
  final bool handleError;

  const BaseView({
    required this.builder,
    this.onModelReady,
    this.handleLoading = true,
    this.handleError = true,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<T>(
      create: (context) {
        final viewModel = context.read<T>();
        if (onModelReady != null) {
          onModelReady!(viewModel);
        }
        return viewModel;
      },
      child: Consumer<T>(
        builder: (context, viewModel, child) {
          if (handleError && viewModel.hasError) {
            return AppErrorWidget(
              message: viewModel.errorMessage ?? 'An error occurred',
              onRetry: viewModel.retry,
            );
          }

          if (handleLoading && viewModel.isLoading) {
            return const AppLoadingWidget();
          }

          return builder(context, viewModel);
        },
      ),
    );
  }
}
