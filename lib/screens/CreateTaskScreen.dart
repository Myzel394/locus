import 'dart:io';

import 'package:basic_utils/basic_utils.dart';
import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/screens/create_task_screen_widgets/ExampleTasksRoulette.dart';
import 'package:locus/screens/create_task_screen_widgets/SignKeyLottie.dart';
import 'package:locus/screens/create_task_screen_widgets/ViewKeyLottie.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/RelaySelectSheet.dart';
import 'package:locus/widgets/TimerWidget.dart';
import 'package:locus/widgets/TimerWidgetSheet.dart';
import 'package:provider/provider.dart';

import '../widgets/WarningText.dart';

final IN_DURATION = 700.ms;
final IN_DELAY = 80.ms;

class CreateTaskScreen extends StatefulWidget {
  final void Function() onCreated;

  const CreateTaskScreen({
    required this.onCreated,
    Key? key,
  }) : super(key: key);

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _frequencyController = TextEditingController();
  final TimerController _timersController = TimerController();
  final RelayController _relaysController = RelayController();
  final _formKey = GlobalKey<FormState>();
  String? errorMessage;
  bool anotherTaskAlreadyExists = false;
  bool showExamples = false;

  TaskCreationProgress? _taskProgress;

  @override
  void initState() {
    super.initState();

    _nameController.addListener(() {
      final taskService = context.read<TaskService>();
      final lowerCasedName = _nameController.text.toLowerCase();
      final alreadyExists = taskService.tasks
          .any((element) => element.name.toLowerCase() == lowerCasedName);

      setState(() {
        anotherTaskAlreadyExists = alreadyExists;
      });
    });
    _timersController.addListener(() {
      setState(() {
        errorMessage = null;
      });
    });
    _relaysController.addListener(() {
      setState(() {
        errorMessage = null;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _frequencyController.dispose();
    _timersController.dispose();
    _relaysController.dispose();

    super.dispose();
  }

  void rebuild() {
    setState(() {});
  }

  Future<void> createTask(final BuildContext context) async {
    setState(() {
      _taskProgress = TaskCreationProgress.startsSoon;
    });

    final taskService = context.read<TaskService>();

    try {
      final task = await Task.create(
        _nameController.text,
        Duration(minutes: int.parse(_frequencyController.text)),
        _relaysController.relays,
        onProgress: (progress) {
          setState(() {
            _taskProgress = progress;
          });
        },
        timers: _timersController.timers,
      );

      if (!mounted) {
        return;
      }

      taskService.add(task);
      await taskService.save();
      task.startSchedule();

      // Calling this explicitly so the text is cleared when leaving the screen
      setState(() {
        _taskProgress = null;
      });

      if (mounted) {
        widget.onCreated();
      }
    } catch (error) {
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MEDIUM_SPACE),
          child: Center(
            child: Form(
              key: _formKey,
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
                        SizedBox(height: isKeyboardVisible ? 0 : LARGE_SPACE),
                        SingleChildScrollView(
                          child: Column(
                            children: <Widget>[
                              Focus(
                                onFocusChange: (hasFocus) {
                                  if (!hasFocus) {
                                    return;
                                  }

                                  setState(() {
                                    showExamples = true;
                                  });
                                },
                                child: PlatformTextFormField(
                                  controller: _nameController,
                                  enabled: _taskProgress == null,
                                  textInputAction: TextInputAction.next,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please enter a name";
                                    }

                                    if (!StringUtils.isAscii(value)) {
                                      return "Name contains invalid characters";
                                    }

                                    return null;
                                  },
                                  keyboardType: TextInputType.name,
                                  autofillHints: const [AutofillHints.name],
                                  material: (_, __) =>
                                      MaterialTextFormFieldData(
                                    decoration: InputDecoration(
                                      labelText: "Name",
                                      prefixIcon:
                                          Icon(context.platformIcons.tag),
                                    ),
                                  ),
                                  cupertino: (_, __) =>
                                      CupertinoTextFormFieldData(
                                    placeholder: "Name",
                                    prefix: Icon(context.platformIcons.tag),
                                  ),
                                )
                                    .animate()
                                    .slide(
                                      duration: IN_DURATION,
                                      curve: Curves.easeOut,
                                      begin: Offset(0, 0.2),
                                    )
                                    .fadeIn(
                                      delay: IN_DELAY,
                                      duration: IN_DURATION,
                                      curve: Curves.easeOut,
                                    ),
                              ),
                              if (showExamples)
                                ExampleTasksRoulette(
                                  onSelected: (example) {
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();

                                    _nameController.text = example.name;
                                    _frequencyController.text =
                                        example.frequency.inMinutes.toString();
                                    _timersController
                                      ..clear()
                                      ..addAll(example.timers);
                                  },
                                ),
                              if (anotherTaskAlreadyExists) ...[
                                const SizedBox(height: MEDIUM_SPACE),
                                WarningText(
                                  "A task with this name already exists. You can create the task, but you will have two tasks with the same name.",
                                ),
                              ],
                              const SizedBox(height: MEDIUM_SPACE),
                              PlatformTextFormField(
                                controller: _frequencyController,
                                enabled: _taskProgress == null,
                                textInputAction: TextInputAction.done,
                                keyboardType: TextInputType.number,
                                textAlign: Platform.isAndroid
                                    ? TextAlign.center
                                    : null,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Please enter a frequency";
                                  }

                                  if (!StringUtils.isDigit(value)) {
                                    return "Frequency must be a number";
                                  }

                                  final frequency = int.parse(value);

                                  if (frequency < 1) {
                                    return "Frequency must be greater than 0";
                                  }

                                  return null;
                                },
                                material: (_, __) => MaterialTextFormFieldData(
                                  decoration: InputDecoration(
                                    prefixIcon:
                                        Icon(context.platformIcons.time),
                                    labelText: "Frequency",
                                    prefixText: "Every",
                                    suffix: Text("Minutes"),
                                  ),
                                ),
                                cupertino: (_, __) =>
                                    CupertinoTextFormFieldData(
                                  placeholder: "Frequency (in minutes)",
                                  prefix: Icon(context.platformIcons.time),
                                ),
                              )
                                  .animate()
                                  .then(delay: IN_DELAY * 2)
                                  .slide(
                                    duration: IN_DURATION,
                                    curve: Curves.easeOut,
                                    begin: Offset(0, 0.2),
                                  )
                                  .fadeIn(
                                    delay: IN_DELAY,
                                    duration: IN_DURATION,
                                    curve: Curves.easeOut,
                                  ),
                              const SizedBox(height: MEDIUM_SPACE),
                              Wrap(
                                alignment: WrapAlignment.spaceEvenly,
                                spacing: SMALL_SPACE,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                direction: Axis.horizontal,
                                children: <Widget>[
                                  PlatformElevatedButton(
                                    material: (_, __) =>
                                        MaterialElevatedButtonData(
                                      icon: Icon(Icons.dns_rounded),
                                    ),
                                    cupertino: (_, __) =>
                                        CupertinoElevatedButtonData(
                                      padding: getSmallButtonPadding(context),
                                    ),
                                    onPressed: _taskProgress != null
                                        ? null
                                        : () {
                                            showPlatformModalSheet(
                                              context: context,
                                              material: MaterialModalSheetData(
                                                backgroundColor:
                                                    Colors.transparent,
                                                isScrollControlled: true,
                                                isDismissible: true,
                                              ),
                                              builder: (_) => RelaySelectSheet(
                                                controller: _relaysController,
                                              ),
                                            );
                                          },
                                    child: Text(
                                      _relaysController.relays.isEmpty
                                          ? "Select Relays"
                                          : "Selected ${_relaysController.relays.length} Relay${_relaysController.relays.length == 1 ? "" : "s"}",
                                    ),
                                  )
                                      .animate()
                                      .then(delay: IN_DELAY * 4)
                                      .slide(
                                        duration: IN_DURATION,
                                        curve: Curves.easeOut,
                                        begin: Offset(0.2, 0),
                                      )
                                      .fadeIn(
                                        delay: IN_DELAY,
                                        duration: IN_DURATION,
                                        curve: Curves.easeOut,
                                      ),
                                  PlatformElevatedButton(
                                    material: (_, __) =>
                                        MaterialElevatedButtonData(
                                      icon: const Icon(Icons.timer_rounded),
                                    ),
                                    cupertino: (_, __) =>
                                        CupertinoElevatedButtonData(
                                      padding: getSmallButtonPadding(context),
                                    ),
                                    onPressed: _taskProgress != null
                                        ? null
                                        : () async {
                                            await showPlatformModalSheet(
                                              context: context,
                                              material: MaterialModalSheetData(
                                                backgroundColor:
                                                    Colors.transparent,
                                                isScrollControlled: true,
                                                isDismissible: true,
                                              ),
                                              builder: (_) => TimerWidgetSheet(
                                                controller: _timersController,
                                              ),
                                            );
                                          },
                                    child: Text(
                                      _timersController.timers.isEmpty
                                          ? "Select Timers"
                                          : "Selected ${_timersController.timers.length} Timer${_timersController.timers.length == 1 ? "" : "s"}",
                                    ),
                                  )
                                      .animate()
                                      .then(delay: IN_DELAY * 5)
                                      .slide(
                                        duration: IN_DURATION,
                                        curve: Curves.easeOut,
                                        begin: Offset(-0.2, 0),
                                      )
                                      .fadeIn(
                                        delay: IN_DELAY,
                                        duration: IN_DURATION,
                                        curve: Curves.easeOut,
                                      ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (errorMessage != null) ...[
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: getBodyTextTextStyle(context).copyWith(
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: MEDIUM_SPACE),
                  ],
                  if (_taskProgress != null) ...[
                    if (_taskProgress == TaskCreationProgress.creatingViewKeys)
                      const Expanded(
                        child: ViewKeyLottie(),
                      ).animate().fadeIn(duration: 1.seconds),
                    if (_taskProgress == TaskCreationProgress.creatingSignKeys)
                      const Expanded(
                        child: SignKeyLottie(),
                      ).animate().fadeIn(duration: 1.seconds),
                    const SizedBox(height: MEDIUM_SPACE),
                    Text(
                      (() {
                        switch (_taskProgress) {
                          case TaskCreationProgress.startsSoon:
                            return "Task generation started...";
                          case TaskCreationProgress.creatingViewKeys:
                            return "Creating view keys...";
                          case TaskCreationProgress.creatingSignKeys:
                            return "Creating sign keys...";
                          case TaskCreationProgress.creatingTask:
                            return "Creating task...";
                          default:
                            return "";
                        }
                      })(),
                      textAlign: TextAlign.center,
                      style: getCaptionTextStyle(context),
                    ),
                    const SizedBox(height: MEDIUM_SPACE),
                  ],
                  PlatformElevatedButton(
                    padding: const EdgeInsets.all(MEDIUM_SPACE),
                    onPressed: _taskProgress != null
                        ? null
                        : () {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }

                            if (_relaysController.relays.isEmpty) {
                              setState(() {
                                errorMessage =
                                    "Please select at least one relay";
                              });
                              return;
                            }

                            createTask(context);
                          },
                    child: Text(
                      "Create",
                      style: TextStyle(
                        fontSize: getActionButtonSize(context),
                      ),
                    ),
                  )
                      .animate()
                      .then(delay: IN_DELAY * 8)
                      .slide(
                        duration: 500.ms,
                        curve: Curves.easeOut,
                        begin: Offset(0, 1.3),
                      )
                      .fadeIn(
                        duration: 500.ms,
                        curve: Curves.easeOut,
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
