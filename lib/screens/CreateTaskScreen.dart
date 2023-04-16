import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/screens/create_task_screen_widgets/TimerWidget.dart';
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

  TaskProgress? _taskProgress;

  @override
  void dispose() {
    _nameController.dispose();
    _frequencyController.dispose();

    super.dispose();
  }

  Future<void> createTask(final BuildContext context) async {
    setState(() {
      _taskProgress = TaskProgress.creationStartsSoon;
    });

    final taskService = context.read<TaskService>();

    try {
      final task = await Task.create(
        _nameController.text,
        Duration(minutes: int.parse(_frequencyController.text)),
        _relays,
        onProgress: (progress) {
          setState(() {
            _taskProgress = progress;
          });
        },
        timers: [],
      );

      taskService.add(task);
      await taskService.save();

      // Calling this explicitly so the text is cleared when leaving the screen
      setState(() {
        _taskProgress = null;
      });

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
    } finally {
      setState(() {
        _taskProgress = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text("Create Task"),
        material: (_, __) => MaterialAppBarData(
          centerTitle: true,
        ),
      ),
      material: (_, __) => MaterialScaffoldData(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
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
                          enabled: _taskProgress == null,
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
                          enabled: _taskProgress == null,
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
                        PlatformElevatedButton(
                          child: Text(
                            _relays.isEmpty
                                ? "Select Relays"
                                : "Selected ${_relays.length} Relay${_relays.length == 1 ? "" : "s"}",
                          ),
                          material: (_, __) => MaterialElevatedButtonData(
                            icon: Icon(Icons.dns_rounded),
                          ),
                          onPressed: _taskProgress != null
                              ? null
                              : () async {
                                  final relays = await showPlatformModalSheet(
                                    context: context,
                                    material: MaterialModalSheetData(
                                      backgroundColor: Colors.transparent,
                                      isScrollControlled: true,
                                      isDismissible: true,
                                    ),
                                    builder: (_) => RelaySelectSheet(
                                      selectedRelays: _relays,
                                    ),
                                  );

                                  if (relays != null) {
                                    setState(() {
                                      _relays = relays;
                                    });
                                  }
                                },
                        ),
                        const SizedBox(height: MEDIUM_SPACE),
                        PlatformElevatedButton(
                          child: Text("Select Timers"),
                          material: (_, __) => MaterialElevatedButtonData(
                            icon: Icon(Icons.timer_rounded),
                          ),
                          onPressed: () async {
                            await showPlatformModalSheet(
                              context: context,
                              material: MaterialModalSheetData(
                                backgroundColor: Colors.transparent,
                                isScrollControlled: true,
                                isDismissible: true,
                              ),
                              builder: (_) => TimerWidget(),
                            );
                          },
                        )
                      ],
                    ),
                  ],
                ),
              ),
              if (_taskProgress != null) ...[
                Center(
                  child: PlatformCircularProgressIndicator(),
                ),
                Text(
                  (() {
                    switch (_taskProgress) {
                      case TaskProgress.creationStartsSoon:
                        return "Task generation started...";
                      case TaskProgress.creatingViewKeys:
                        return "Creating view keys...";
                      case TaskProgress.creatingSignKeys:
                        return "Creating sign keys...";
                      case TaskProgress.creatingTask:
                        return "Creating task...";
                      default:
                        return "";
                    }
                  })(),
                  textAlign: TextAlign.center,
                  style: getCaptionTextStyle(context),
                ),
              ],
              PlatformElevatedButton(
                padding: const EdgeInsets.all(MEDIUM_SPACE),
                onPressed: _taskProgress != null ? null : () => createTask(context),
                child: Text(
                  "Create",
                  style: TextStyle(
                    fontSize: getActionButtonSize(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
