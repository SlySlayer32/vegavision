import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vegavision/core/base/base_view_model.dart';

abstract class BaseView<T extends BaseViewModel> extends StatelessWidget {
  const BaseView({Key? key}) : super(key: key);

  T createViewModel(BuildContext context);

  Widget buildView(BuildContext context, T viewModel);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<T>(
      create: (context) => createViewModel(context),
      child: Consumer<T>(
        builder: (context, viewModel, _) {
          return Stack(
            children: [
              buildView(context, viewModel),
              if (viewModel.isLoading)
                const Center(child: CircularProgressIndicator()),
              if (viewModel.error != null)
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Material(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.red.withOpacity(0.8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        viewModel.error!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
