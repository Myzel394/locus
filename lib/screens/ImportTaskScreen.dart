import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:locus/constants/spacing.dart';

import '../utils/theme.dart';

class ImportTaskScreen extends StatefulWidget {
  const ImportTaskScreen({Key? key}) : super(key: key);

  @override
  State<ImportTaskScreen> createState() => _ImportTaskScreenState();
}

class _ImportTaskScreenState extends State<ImportTaskScreen> with ClipboardListener {
  final TextEditingController _urlController = TextEditingController();
  final PageController _pageController = PageController();
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
    _urlController.dispose();
    _pageController.dispose();

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
        _clipboard = newClipboardData?.text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text("Import Task"),
      ),
      body: PageView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(MEDIUM_SPACE),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Text(
                      "Import a task from an URL",
                      style: getSubTitleTextStyle(context),
                    ),
                    const SizedBox(height: SMALL_SPACE),
                    Text(
                      "Enter the URL of the task you want to import or paste it",
                      style: getCaptionTextStyle(context),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Flexible(
                      child: PlatformTextField(
                        controller: _urlController,
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
                          _urlController.text = _clipboard!;
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
                ),
                PlatformElevatedButton(
                  padding: const EdgeInsets.all(MEDIUM_SPACE),
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Text("Import"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
