import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart'
    hide PlatformListTile;
import 'package:locus/constants/spacing.dart';
import 'package:locus/screens/create_task_screen_widgets/ExampleTasksRoulette.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/utils/theme.dart';
import 'package:locus/widgets/MIUISelectField.dart';
import 'package:locus/widgets/RelaySelectSheet.dart';
import 'package:locus/widgets/TimerWidget.dart';
import 'package:locus/widgets/TimerWidgetSheet.dart';
import 'package:provider/provider.dart';

import '../models/log.dart';
import '../services/log_service.dart';
import '../services/settings_service.dart';
import '../utils/device.dart';
import '../widgets/PlatformListTile.dart';
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
  final TimerController _timersController = TimerController();
  final RelayController _relaysController = RelayController();
  final _formKey = GlobalKey<FormState>();
  String? errorMessage;
  bool anotherTaskAlreadyExists = false;
  bool showExamples = false;
  bool _scheduleNow = true;
  bool _isError = false;

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

    final settings = context.read<SettingsService>();

    _relaysController.addAll(settings.getRelays());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timersController.dispose();
    _relaysController.dispose();

    super.dispose();
  }

  void rebuild() {
    setState(() {});
  }

  Future<void> createTask() async {
    final taskService = context.read<TaskService>();
    final settings = context.read<SettingsService>();
    final logService = context.read<LogService>();

    setState(() {
      _isError = false;
    });

    try {
      final task = await Task.create(
        _nameController.text,
        _relaysController.relays,
        timers: _timersController.timers,
      );

      if (!mounted) {
        return;
      }

      taskService.add(task);
      await taskService.save();

      await logService.addLog(
        Log.createTask(
          initiator: LogInitiator.user,
          taskId: task.id,
          taskName: task.name,
          creationContext: TaskCreationContext.inApp,
        ),
      );

      if (_scheduleNow) {
        await task.startSchedule(startNowIfNextRunIsUnknown: true);
      }

      if (mounted) {
        widget.onCreated();
      }
    } catch (error) {
      setState(() {
        _isError = true;
      });
    }
  }

  Future<void> showRelaysSheet() => showPlatformModalSheet(
        context: context,
        material: MaterialModalSheetData(
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          isDismissible: true,
        ),
        builder: (_) => RelaySelectSheet(
          controller: _relaysController,
        ),
      );

  Future<void> showTimersSheet() => showPlatformModalSheet(
        context: context,
        material: MaterialModalSheetData(
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          isDismissible: true,
        ),
        builder: (_) => TimerWidgetSheet(
          controller: _timersController,
        ),
      );

  Widget getScheduleNowWidget() {
    final l10n = AppLocalizations.of(context);
    final switchWidget = PlatformSwitch(
      value: _scheduleNow,
      onChanged: (value) {
        setState(() {
          _scheduleNow = value;
        });
      },
    );
    final explanationWidget = PlatformIconButton(
      icon: Icon(context.platformIcons.help),
      onPressed: () {
        showPlatformDialog(
          context: context,
          builder: (context) => PlatformAlertDialog(
            title: Text(l10n.mainScreen_createTask_scheduleNow_help_title),
            content:
                Text(l10n.mainScreen_createTask_scheduleNow_help_description),
            actions: [
              PlatformDialogAction(
                child: PlatformText(l10n.closeNeutralAction),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );

    return PlatformListTile(
      title: Text(l10n.mainScreen_createTask_scheduleNow),
      leading: isMIUI() ? explanationWidget : switchWidget,
      trailing: isMIUI() ? switchWidget : explanationWidget,
    )
        .animate()
        .then(delay: IN_DELAY * 6)
        .slide(
          duration: IN_DURATION,
          curve: Curves.easeOut,
          begin: const Offset(0, 0.2),
        )
        .fadeIn(
          delay: IN_DELAY,
          duration: IN_DURATION,
          curve: Curves.easeOut,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text(l10n.mainScreen_createTask),
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
                        Column(
                          children: <Widget>[
                            const SizedBox(height: SMALL_SPACE),
                            Text(
                              l10n.createTask_title,
                              style: getSubTitleTextStyle(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: LARGE_SPACE),
                        Column(
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
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return l10n.fields_errors_isEmpty;
                                  }

                                  if (!StringUtils.isAscii(value)) {
                                    return l10n.fields_errors_invalidCharacters;
                                  }

                                  return null;
                                },
                                keyboardType: TextInputType.name,
                                autofillHints: const [AutofillHints.name],
                                material: (_, __) => MaterialTextFormFieldData(
                                  decoration: InputDecoration(
                                    labelText:
                                        l10n.createTask_fields_name_label,
                                    prefixIcon: Icon(context.platformIcons.tag),
                                  ),
                                ),
                                cupertino: (_, __) =>
                                    CupertinoTextFormFieldData(
                                  placeholder:
                                      l10n.createTask_fields_name_label,
                                  prefix: Icon(context.platformIcons.tag),
                                ),
                              )
                                  .animate()
                                  .slide(
                                    duration: IN_DURATION,
                                    curve: Curves.easeOut,
                                    begin: const Offset(0, 0.2),
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
                                  FocusManager.instance.primaryFocus?.unfocus();

                                  _nameController.text = example.name;
                                  _timersController
                                    ..clear()
                                    ..addAll(example.timers);
                                },
                              ),
                            if (anotherTaskAlreadyExists) ...[
                              const SizedBox(height: MEDIUM_SPACE),
                              WarningText(
                                l10n.createTask_sameTaskNameAlreadyExists,
                              ),
                            ],
                            const SizedBox(height: MEDIUM_SPACE),
                            if (isMIUI()) ...[
                              MIUISelectField(
                                label: l10n.createTask_fields_relays_label,
                                actionText:
                                    l10n.createTask_fields_relays_selectLabel(
                                  _relaysController.relays.length,
                                ),
                                icon: const Icon(Icons.dns_rounded),
                                onPressed: showRelaysSheet,
                              ).animate().then(delay: IN_DELAY * 4).fadeIn(
                                    delay: IN_DELAY,
                                    duration: IN_DURATION,
                                    curve: Curves.easeOut,
                                  ),
                              MIUISelectField(
                                label: l10n.createTask_fields_timers_label,
                                actionText:
                                    l10n.createTask_fields_timers_selectLabel(
                                  _timersController.timers.length,
                                ),
                                icon: const Icon(Icons.timer_rounded),
                                onPressed: showTimersSheet,
                              ).animate().then(delay: IN_DELAY * 4).fadeIn(
                                    delay: IN_DELAY,
                                    duration: IN_DURATION,
                                    curve: Curves.easeOut,
                                  ),
                            ] else
                              Wrap(
                                alignment: WrapAlignment.spaceEvenly,
                                spacing: SMALL_SPACE,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                direction: Axis.horizontal,
                                children: <Widget>[
                                  PlatformElevatedButton(
                                    material: (_, __) =>
                                        MaterialElevatedButtonData(
                                      icon: PlatformWidget(
                                        material: (_, __) =>
                                            const Icon(Icons.dns_rounded),
                                        cupertino: (_, __) => const Icon(
                                            CupertinoIcons.list_bullet),
                                      ),
                                    ),
                                    cupertino: (_, __) =>
                                        CupertinoElevatedButtonData(
                                      padding: getSmallButtonPadding(context),
                                    ),
                                    onPressed: showRelaysSheet,
                                    child: Text(
                                      l10n.createTask_fields_relays_selectLabel(
                                        _relaysController.relays.length,
                                      ),
                                    ),
                                  )
                                      .animate()
                                      .then(delay: IN_DELAY * 4)
                                      .slide(
                                        duration: IN_DURATION,
                                        curve: Curves.easeOut,
                                        begin: const Offset(0.2, 0),
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
                                    onPressed: showTimersSheet,
                                    child: Text(
                                      l10n.createTask_fields_timers_selectLabel(
                                        _timersController.timers.length,
                                      ),
                                    ),
                                  )
                                      .animate()
                                      .then(delay: IN_DELAY * 5)
                                      .slide(
                                        duration: IN_DURATION,
                                        curve: Curves.easeOut,
                                        begin: const Offset(-0.2, 0),
                                      )
                                      .fadeIn(
                                        delay: IN_DELAY,
                                        duration: IN_DURATION,
                                        curve: Curves.easeOut,
                                      ),
                                ],
                              ),
                            const SizedBox(height: MEDIUM_SPACE),
                            getScheduleNowWidget(),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (errorMessage != null) ...[
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: getBodyTextTextStyle(context).copyWith(
                        color: getErrorColor(context),
                      ),
                    ),
                    const SizedBox(height: MEDIUM_SPACE),
                  ],
                  if (_isError) ...[
                    Text(
                      l10n.unknownError,
                      style: getBodyTextTextStyle(context).copyWith(
                        color: getErrorColor(context),
                      ),
                    ),
                  ],
                  PlatformElevatedButton(
                    padding: const EdgeInsets.all(MEDIUM_SPACE),
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) {
                        return;
                      }

                      if (_relaysController.relays.isEmpty) {
                        setState(() {
                          errorMessage = l10n.createTask_errors_emptyRelays;
                        });
                        return;
                      }

                      createTask();
                    },
                    child: Text(
                      l10n.createTask_createLabel,
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
                        begin: const Offset(0, 1.3),
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
