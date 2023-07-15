import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:lottie/lottie.dart';

import '../../../constants/spacing.dart';
import '../../../utils/theme.dart';
import '../../CreateTaskScreen.dart';
import '../../ImportTaskSheet.dart';

class EmptyScreen extends StatefulWidget {
  const EmptyScreen({Key? key}) : super(key: key);

  @override
  State<EmptyScreen> createState() => _EmptyScreenState();
}

class _EmptyScreenState extends State<EmptyScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shades = getPrimaryColorShades(context);

    return SafeArea(
      child: Center(
        child: Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Lottie.asset(
                "assets/lotties/task.json",
                width: 250,
                repeat: false,
                frameRate: FrameRate.max,
                delegates: LottieDelegates(values: [
                  ValueDelegate.strokeColor(
                    const ["list Outlines 3", "Group 4", "Stroke 1"],
                    value: shades[0],
                  ),
                  ValueDelegate.strokeColor(
                    const ["list Outlines 2", "Group 5", "Stroke 1"],
                    value: shades[0],
                  ),
                  ValueDelegate.strokeColor(
                    const ["list Outlines 4", "Group 3", "Stroke 1"],
                    value: shades[0],
                  ),
                  ValueDelegate.strokeColor(
                    const ["list Outlines 5", "Group 2", "Stroke 1"],
                    value: shades[0],
                  ),
                  ValueDelegate.strokeColor(
                    const ["list Outlines 6", "Group 1", "Stroke 1"],
                    value: shades[0],
                  ),
                ]),
              ),
              const SizedBox(height: MEDIUM_SPACE),
              Text(
                l10n.sharesOverviewScreen_createTask_tasksEmpty,
                style: getSubTitleTextStyle(context),
              ),
              const SizedBox(height: SMALL_SPACE),
              Text(
                l10n.sharesOverviewScreen_createTask_description,
                style: getCaptionTextStyle(context),
              ),
              const SizedBox(height: LARGE_SPACE),
              Wrap(
                direction:
                    isCupertino(context) ? Axis.vertical : Axis.horizontal,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: SMALL_SPACE,
                children: [
                  OpenContainer(
                    transitionDuration: const Duration(milliseconds: 700),
                    transitionType: ContainerTransitionType.fade,
                    openBuilder: (context, action) => CreateTaskScreen(
                      onCreated: () {
                        Navigator.pop(context);
                      },
                    ),
                    closedShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(
                            isCupertino(context) ? 8.0 : HUGE_SPACE),
                      ),
                    ),
                    closedBuilder: (context, action) => GestureDetector(
                      onTap: action,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: MEDIUM_SPACE,
                          vertical: SMALL_SPACE,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.add,
                              color: getButtonTextColor(context),
                            ),
                            const SizedBox(width: SMALL_SPACE),
                            Text(
                              l10n.sharesOverviewScreen_createTask_action_create,
                              style: TextStyle(
                                color: getButtonTextColor(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    openColor: Theme.of(context).scaffoldBackgroundColor,
                    closedColor: getButtonBackgroundColor(context),
                  ),
                  const SizedBox(width: SMALL_SPACE),
                  PlatformElevatedButton(
                    onPressed: () async {
                      ImportScreen? initialScreen;

                      if (isCupertino(context)) {
                        initialScreen = await showCupertinoModalPopup(
                          context: context,
                          barrierDismissible: true,
                          builder: (cupertino) => CupertinoActionSheet(
                            title: Text(l10n
                                .sharesOverviewScreen_importTask_action_import),
                            message: Text(l10n
                                .sharesOverviewScreen_importTask_action_importMethod),
                            cancelButton: CupertinoActionSheetAction(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text(l10n.cancelLabel),
                            ),
                            actions: [
                              CupertinoActionSheetAction(
                                isDefaultAction: true,
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(ImportScreen.askURL);
                                },
                                child: Text(l10n
                                    .sharesOverviewScreen_importTask_action_importMethod_url),
                              ),
                              CupertinoActionSheetAction(
                                isDefaultAction: true,
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(ImportScreen.importFile);
                                },
                                child: Text(l10n
                                    .sharesOverviewScreen_importTask_action_importMethod_file),
                              ),
                            ],
                          ),
                        );
                      } else {
                        initialScreen = ImportScreen.ask;
                      }

                      if (initialScreen == null) {
                        return;
                      }

                      if (!mounted) {
                        return;
                      }

                      await showPlatformModalSheet(
                        context: context,
                        material: MaterialModalSheetData(
                          isScrollControlled: true,
                          isDismissible: true,
                          backgroundColor: Colors.transparent,
                        ),
                        builder: (context) =>
                            ImportTaskSheet(initialScreen: initialScreen),
                      );
                    },
                    material: (_, __) => MaterialElevatedButtonData(
                      icon: const Icon(Icons.file_download_outlined),
                    ),
                    child: Text(
                        l10n.sharesOverviewScreen_importTask_action_import),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
