import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/screens/import_task_screen_widgets/URLImporter.dart';
import 'package:locus/services/view_service.dart';

import '../utils/theme.dart';

enum TaskImportProgress {
  fetchingFromNostr,
  parsing,
  done,
}

const Map<TaskImportProgress, String> TASK_IMPORT_PROGRESS_TEXT_MAP = {
  TaskImportProgress.fetchingFromNostr: "Fetching data from Nostr",
  TaskImportProgress.parsing: "Parsing data",
  TaskImportProgress.done: "Done",
};

class ImportTaskScreen extends StatefulWidget {
  const ImportTaskScreen({Key? key}) : super(key: key);

  @override
  State<ImportTaskScreen> createState() => _ImportTaskScreenState();
}

class _ImportTaskScreenState extends State<ImportTaskScreen> {
  final TextEditingController _urlController = TextEditingController();
  final PageController _pageController = PageController();
  TaskImportProgress? _progress;
  TaskView? _taskView;

  Future<void> importFromLink() async {
    try {
      final parameters = TaskView.parseLink(_urlController.text);

      setState(() {
        _progress = TaskImportProgress.fetchingFromNostr;
      });

      final task = await TaskView.fetchFromNostr(parameters);

      setState(() {
        _progress = TaskImportProgress.done;
        _taskView = task;
      });

      _pageController.animateTo(
        1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    } catch (error) {
      final scaffold = ScaffoldMessenger.of(context);

      scaffold.showSnackBar(
        SnackBar(
          content: Text("An error occurred while importing the task"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _progress = null;
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
                      "Import a task",
                      style: getSubTitleTextStyle(context),
                    ),
                    const SizedBox(height: SMALL_SPACE),
                    Text(
                      "If you have an url of an task you want to import, enter it or paste it; If you have a viewkey file, you can import it from the file manager",
                      style: getCaptionTextStyle(context),
                    ),
                  ],
                ),
                URLImporter(
                  controller: _urlController,
                  enabled: _progress == null,
                ),
                if (_progress != null) ...[
                  Center(
                    child: PlatformCircularProgressIndicator(),
                  ),
                  Text(
                    TASK_IMPORT_PROGRESS_TEXT_MAP[_progress]!,
                    textAlign: TextAlign.center,
                    style: getCaptionTextStyle(context),
                  ),
                ],
                PlatformElevatedButton(
                  padding: const EdgeInsets.all(MEDIUM_SPACE),
                  onPressed: _progress == null ? importFromLink : null,
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
