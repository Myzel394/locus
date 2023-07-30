import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/widgets/ModalSheetContent.dart';

import '../../constants/spacing.dart';

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

class _URLFormState extends State<URLForm> with ClipboardListener {
  final _formKey = GlobalKey<FormState>();
  String? clipboard;

  @override
  void initState() {
    super.initState();

    clipboardWatcher.addListener(this);
    clipboardWatcher.start();
    onClipboardChanged();
  }

  @override
  void dispose() {
    clipboardWatcher.removeListener(this);
    clipboardWatcher.stop();

    super.dispose();
  }

  @override
  void onClipboardChanged() async {
    setState(() {
      clipboard = null;
    });

    final newClipboardData = await Clipboard.getData(Clipboard.kTextPlain);

    final result = Uri.tryParse(newClipboardData?.text ?? "");

    if (result?.hasAbsolutePath ?? false) {
      setState(() {
        clipboard = result!.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Form(
      key: _formKey,
      child: ModalSheetContent(
        title:
            l10n.sharesOverviewScreen_importTask_action_importMethod_url_title,
        submitLabel:
            l10n.sharesOverviewScreen_importTask_action_importMethod_url,
        onSubmit: () {
          if (_formKey.currentState?.validate() ?? false) {
            widget.onImport();
          }
        },
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: PlatformTextFormField(
                  controller: widget.controller,
                  enabled: !widget.isFetching,
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.url,
                  hintText: l10n
                      .sharesOverviewScreen_importTask_action_importMethod_url_hint,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.fields_errors_isEmpty;
                    }

                    final result = Uri.tryParse(value);

                    if (result == null || !result.hasAbsolutePath) {
                      return l10n.fields_errors_invalidURL;
                    }

                    return null;
                  },
                  material: (_, __) => MaterialTextFormFieldData(
                    decoration: InputDecoration(
                      labelText: l10n
                          .sharesOverviewScreen_importTask_action_importMethod_url_label,
                      border: clipboard == null
                          ? OutlineInputBorder(
                              borderRadius: BorderRadius.circular(MEDIUM_SPACE),
                            )
                          : const OutlineInputBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(MEDIUM_SPACE),
                                bottomLeft: Radius.circular(MEDIUM_SPACE),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              if (clipboard != null)
                PlatformElevatedButton(
                  padding: const EdgeInsets.all(MEDIUM_SPACE),
                  onPressed: () {
                    widget.controller.text = clipboard!;
                  },
                  child: const Icon(Icons.paste_rounded),
                  material: (_, __) => MaterialElevatedButtonData(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(MEDIUM_SPACE - 1),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(MEDIUM_SPACE),
                          bottomRight: Radius.circular(MEDIUM_SPACE),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: MEDIUM_SPACE),
          if (widget.isFetching) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: MEDIUM_SPACE),
          ],
        ],
      ),
    );
  }
}
