import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/constants/spacing.dart';
import 'package:locus/init_quick_actions.dart';
import 'package:locus/services/task_service.dart';
import 'package:locus/services/timers_service.dart';
import 'package:locus/utils/platform.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../services/settings_service.dart';
import '../utils/theme.dart';

class ShortcutScreen extends StatefulWidget {
  final ShortcutType type;

  const ShortcutScreen({
    required this.type,
    Key? key,
  }) : super(key: key);

  @override
  State<ShortcutScreen> createState() => _ShortcutScreenState();
}

class _ShortcutScreenState extends State<ShortcutScreen> {
  bool isDone = false;
  bool isError = false;

  Map<ShortcutType, String> getShortcutTranslationMap() {
    final l10n = AppLocalizations.of(context);

    return {
      ShortcutType.createOneHour: l10n.quickActions_createOneHour,
      ShortcutType.shareNow: l10n.quickActions_shareNow,
      ShortcutType.stopAllTasks: l10n.quickActions_stopTasks,
    };
  }

  Future<void> _runAction() async {
    try {
      final l10n = AppLocalizations.of(context);
      final taskService = context.read<TaskService>();
      final settings = context.read<SettingsService>();
      await taskService.checkup();

      switch (widget.type) {
        case ShortcutType.createOneHour:
          final task = await Task.create(
            l10n.quickActions_createOneHour_labelFromNow(DateTime.now()),
            settings.getRelays(),
            timers: [
              DurationTimer(duration: const Duration(hours: 1)),
            ],
            deleteAfterRun: true,
          );

          await task.startSchedule(startNowIfNextRunIsUnknown: true);
          await task.publishCurrentLocationNow();

          taskService.add(task);
          await taskService.save();

          break;
        case ShortcutType.shareNow:
          final tasks = await taskService.getRunningTasks().toList();
          await Future.wait(
            tasks.map((task) => task.publishCurrentLocationNow()),
          );
          break;
        case ShortcutType.stopAllTasks:
          final tasks = await taskService.getRunningTasks().toList();
          await Future.wait(
            tasks.map((task) => task.stopExecutionImmediately()),
          );
          break;
      }

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) {
        return;
      }

      if (isPlatformApple()) {
        Navigator.of(context).pop();
      } else {
        SystemNavigator.pop();
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        isError = true;
      });
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        isDone = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runAction();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PlatformScaffold(
      body: Padding(
        padding: const EdgeInsets.all(MEDIUM_SPACE),
        child: Center(
          child: (() {
            if (isError) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    l10n.unknownError,
                    style: getBodyTextTextStyle(context).copyWith(
                      color: getErrorColor(context),
                    ),
                  ),
                  const SizedBox(height: MEDIUM_SPACE),
                  PlatformElevatedButton(
                    child: Text(l10n.goBack),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  )
                ],
              );
            }

            if (isDone) {
              // Success
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Lottie.asset(
                    'assets/lotties/success.json',
                    width: 200,
                    height: 200,
                    frameRate: FrameRate.max,
                    repeat: false,
                  ),
                  const SizedBox(height: MEDIUM_SPACE),
                  PlatformElevatedButton(
                    child: Text(l10n.closePositiveSheetAction),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  )
                ],
              );
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  getShortcutTranslationMap()[widget.type]!,
                  style: getTitleTextStyle(context),
                ),
                Icon(
                  SHORTCUT_TYPE_ICON_MAP[widget.type],
                  size: 100,
                ),
                Text(
                  l10n.quickActions_generationExplanation,
                  style: getBodyTextTextStyle(context),
                ),
                PlatformCircularProgressIndicator(),
              ],
            );
          })(),
        ),
      ),
    );
  }
}
