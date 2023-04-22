import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/spacing.dart';

class URLImporter extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;

  const URLImporter({
    required this.controller,
    this.enabled = true,
    Key? key,
  }) : super(key: key);

  @override
  State<URLImporter> createState() => _URLImporterState();
}

class _URLImporterState extends State<URLImporter> with ClipboardListener {
  String? _clipboard;

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
      _clipboard = null;
    });

    final newClipboardData = await Clipboard.getData(Clipboard.kTextPlain);

    final result = Uri.tryParse(newClipboardData?.text ?? "");

    if (result?.hasAbsolutePath ?? false) {
      setState(() {
        _clipboard = result!.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Flexible(
          child: PlatformTextField(
            controller: widget.controller,
            enabled: widget.enabled,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.url,
            hintText: "https://locus.app#",
            material: (_, __) => MaterialTextFieldData(
              decoration: InputDecoration(
                labelText: "URL",
                border: _clipboard == null
                    ? OutlineInputBorder(
                        borderRadius: BorderRadius.circular(MEDIUM_SPACE),
                      )
                    : OutlineInputBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(MEDIUM_SPACE),
                          bottomLeft: Radius.circular(MEDIUM_SPACE),
                        ),
                      ),
              ),
            ),
          ),
        ),
        if (_clipboard != null)
          PlatformElevatedButton(
            padding: const EdgeInsets.all(MEDIUM_SPACE),
            onPressed: () {
              widget.controller.text = _clipboard!;
            },
            child: Icon(Icons.paste_rounded),
            material: (_, __) => MaterialElevatedButtonData(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(MEDIUM_SPACE - 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(MEDIUM_SPACE),
                    bottomRight: Radius.circular(MEDIUM_SPACE),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
