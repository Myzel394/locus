import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/spacing.dart';
import '../../services/task_service.dart';
import '../../services/view_service.dart';
import '../../utils/theme.dart';
import 'URLImporter.dart';

class URLForm extends StatefulWidget {
  final void Function(TaskView) onSubmitted;
  final void Function(String) onTaskError;

  const URLForm({
    required this.onSubmitted,
    required this.onTaskError,
    Key? key,
  }) : super(key: key);

  @override
  State<URLForm> createState() => _URLFormState();
}

class _URLFormState extends State<URLForm> {
  final _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isFetching = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    _urlController.addListener(() {
      if (_urlController.text.isNotEmpty && errorMessage != null) {
        setState(() {
          errorMessage = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskService = context.read<TaskService>();
    final viewService = context.read<ViewService>();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            "Enter the URL of your task",
            style: getBodyTextTextStyle(context),
          ),
          const SizedBox(height: MEDIUM_SPACE),
          URLImporter(
            controller: _urlController,
            enabled: !isFetching,
          ),
          const SizedBox(height: MEDIUM_SPACE),
          if (isFetching) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: MEDIUM_SPACE),
          ],
          PlatformElevatedButton(
            padding: const EdgeInsets.all(MEDIUM_SPACE),
            onPressed: isFetching
                ? null
                : () async {
              if (!_formKey.currentState!.validate()) {
                return;
              }

              try {
                setState(() {
                  isFetching = true;
                });

                final parameters = TaskView.parseLink(_urlController.text);
                final taskView = await TaskView.fetchFromNostr(parameters);
                final errorMessage = await taskView.validate(taskService: taskService, viewService: viewService);

                if (errorMessage != null) {
                  widget.onTaskError(errorMessage);
                  return;
                } else {
                  widget.onSubmitted(taskView);
                }
              } catch (_) {
                setState(() {
                  errorMessage = "An error occurred while fetching the task.";
                });
              } finally {
                setState(() {
                  isFetching = false;
                });
              }
            },
            material: (_, __) =>
                MaterialElevatedButtonData(
                  icon: const Icon(Icons.link_rounded),
                ),
            child: const Text("Import URL"),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: SMALL_SPACE),
            Text(
              errorMessage!,
              style: getBodyTextTextStyle(context).copyWith(color: Colors.red),
            ),
          ]
        ],
      ),
    );
  }
}
