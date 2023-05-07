import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../constants/spacing.dart';
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
    final l10n = AppLocalizations.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.mainScreen_importTask_action_importMethod_url_title,
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
                        errorMessage = l10n.taskImportError;
                      });
                    }
                  },
            material: (_, __) => MaterialElevatedButtonData(
              icon: const Icon(Icons.link_rounded),
            ),
            child: Text(
              l10n.mainScreen_importTask_action_importMethod_url,
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: SMALL_SPACE),
            Text(
              errorMessage!,
              style: getBodyTextTextStyle(context).copyWith(color: getErrorColor(context)),
            ),
          ]
        ],
      ),
    );
  }
}
