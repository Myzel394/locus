import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/spacing.dart';
import '../../services/task_service.dart';
import '../../services/view_service.dart';
import '../../utils/theme.dart';
import 'URLImporter.dart';

class URLForm extends StatefulWidget {
  final TextEditingController controller;
  final Future<void> Function() onImport;
  final bool isFetching;

  const URLForm({
    required this.controller,
    required this.onImport,
    this.isFetching = false,
    Key? key,
  }) : super(key: key);

  @override
  State<URLForm> createState() => _URLFormState();
}

class _URLFormState extends State<URLForm> {
  final _formKey = GlobalKey<FormState>();
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(() {
      if (widget.controller.text.isNotEmpty && errorMessage != null) {
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
            controller: widget.controller,
            enabled: !widget.isFetching,
          ),
          const SizedBox(height: MEDIUM_SPACE),
          if (widget.isFetching) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: MEDIUM_SPACE),
          ],
          PlatformElevatedButton(
            padding: const EdgeInsets.all(MEDIUM_SPACE),
            onPressed: widget.isFetching
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }

                    try {
                      await widget.onImport();
                    } catch (_) {
                      setState(() {
                        errorMessage =
                            "An error occurred while fetching the task.";
                      });
                    }
                  },
            material: (_, __) => MaterialElevatedButtonData(
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
