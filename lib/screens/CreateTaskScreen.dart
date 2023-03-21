import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/RelaySelectSheet.dart';
import 'package:provider/provider.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({Key? key}) : super(key: key);

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _frequencyController = TextEditingController();
  List<String> _relays = [];

  bool _isCreatingTask = false;

  @override
  void dispose() {
    _nameController.dispose();
    _frequencyController.dispose();

    super.dispose();
  }

  Future<void> createTask(final BuildContext context) async {
    setState(() {
      _isCreatingTask = true;
    });

    final taskService = context.read<TaskService>();

    try {
      final task = await Task.create(
        _nameController.text,
        Duration(minutes: int.parse(_frequencyController.text)),
        _relays,
      );

      taskService.add(task);
      await taskService.save();

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
    } finally {
      setState(() {
        _isCreatingTask = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;

    return Scaffold(
      appBar: AppBar(
        title: Text("Create Task"),
        centerTitle: true,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(MEDIUM_SPACE),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    if (!isKeyboardVisible)
                      Column(
                        children: <Widget>[
                          const SizedBox(height: SMALL_SPACE),
                          Text(
                            "Define a name and a frequency for your task",
                            style: getSubTitleTextStyle(context),
                          ),
                          const SizedBox(height: SMALL_SPACE),
                          Text(
                            "Note that a frequency of less than 15 minutes will automatically be set to 15 minutes. This is not set by us, but by the operating system.",
                            style: getCaptionTextStyle(context),
                          ),
                        ],
                      ),
                    const SizedBox(height: LARGE_SPACE),
                    Column(
                      children: <Widget>[
                        PlatformTextField(
                          controller: _nameController,
                          enabled: _isCreatingTask == false,
                          textInputAction: TextInputAction.next,
                          material: (_, __) => MaterialTextFieldData(
                            decoration: InputDecoration(
                              labelText: "Name",
                              prefixIcon: Icon(context.platformIcons.tag),
                            ),
                          ),
                          cupertino: (_, __) => CupertinoTextFieldData(
                            placeholder: "Name",
                            prefix: Icon(context.platformIcons.tag),
                          ),
                        ),
                        const SizedBox(height: MEDIUM_SPACE),
                        PlatformTextField(
                          controller: _frequencyController,
                          enabled: _isCreatingTask == false,
                          textInputAction: TextInputAction.done,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          material: (_, __) => MaterialTextFieldData(
                            decoration: InputDecoration(
                              prefixIcon: Icon(context.platformIcons.time),
                              labelText: "Frequency",
                              prefixText: "Every",
                              suffix: Text("Minutes"),
                            ),
                          ),
                          cupertino: (_, __) => CupertinoTextFieldData(
                            placeholder: "Frequency",
                            prefix: Text("Every"),
                            suffix: Text("Minutes"),
                          ),
                        ),
                        const SizedBox(height: MEDIUM_SPACE),
                        ElevatedButton(
                          child: Text(
                            _relays.isEmpty
                                ? "Select Relays"
                                : "Selected ${_relays.length} Relay${_relays.length == 1 ? "" : "s"}",
                          ),
                          onPressed: _isCreatingTask
                              ? null
                              : () async {
                                  final relays = await showPlatformModalSheet(
                                    context: context,
                                    material: MaterialModalSheetData(
                                      backgroundColor: Colors.transparent,
                                      isScrollControlled: true,
                                      isDismissible: true,
                                    ),
                                    builder: (_) => RelaySelectSheet(),
                                  );

                                  if (relays != null) {
                                    setState(() {
                                      _relays = relays;
                                    });
                                  }
                                },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isKeyboardVisible)
                PlatformElevatedButton(
                  padding: const EdgeInsets.all(MEDIUM_SPACE),
                  child: Text(
                    "Create",
                    style: TextStyle(
                      fontSize: getActionButtonSize(context),
                    ),
                  ),
                  onPressed: _isCreatingTask == true
                      ? null
                      : () => createTask(context),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
