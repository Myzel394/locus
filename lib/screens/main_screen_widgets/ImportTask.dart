import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/screens/ImportTaskSheet.dart';
import 'package:lottie/lottie.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../constants/spacing.dart';
import '../../utils/theme.dart';

class ImportTask extends StatefulWidget {
  const ImportTask({Key? key}) : super(key: key);

  @override
  State<ImportTask> createState() => _ImportTaskState();
}

class _ImportTaskState extends State<ImportTask> with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shades = getPrimaryColorShades(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        VisibilityDetector(
          key: const Key("import-task-lottie"),
          onVisibilityChanged: (info) {
            if (info.visibleFraction == 0) {
              _controller.reset();
            } else if (info.visibleFraction == 1) {
              _controller.forward();
            }
          },
          child: Lottie.asset(
            "assets/lotties/url-link.json",
            frameRate: FrameRate.max,
            width: 250,
            controller: _controller,
            delegates: LottieDelegates(values: [
              ValueDelegate.strokeColor(
                const ["linkTop 3", "Shape 1", "Stroke 1"],
                value: shades[0],
              ),
              ValueDelegate.strokeColor(
                const ["linkTop 2", "Shape 1", "Stroke 1"],
                value: shades[700],
              ),
              ValueDelegate.strokeColor(
                const ["linkTop", "Shape 1", "Stroke 1"],
                value: shades[900],
              ),
              // `linkBottom 2` coming before `linkBottom 3` is correct (lottie file is probably wrong)
              ValueDelegate.strokeColor(
                const ["linkBottom 2", "Shape 1", "Stroke 1"],
                value: shades[0],
              ),
              ValueDelegate.strokeColor(
                const ["linkBottom 3", "Shape 1", "Stroke 1"],
                value: shades[700],
              ),
              ValueDelegate.strokeColor(
                const ["linkBottom", "Shape 1", "Stroke 1"],
                value: shades[900],
              ),
            ]),
            onLoaded: (composition) {
              _controller.duration = composition.duration;
            },
          ),
        ),
        const SizedBox(height: MEDIUM_SPACE),
        Text(
          l10n.mainScreen_importTask_title,
          style: getSubTitleTextStyle(context),
        ),
        const SizedBox(height: SMALL_SPACE),
        Text(
          l10n.mainScreen_importTask_description,
          style: getCaptionTextStyle(context),
        ),
        const SizedBox(height: MEDIUM_SPACE),
        PlatformElevatedButton(
          onPressed: () async {
            ImportScreen initialScreen = ImportScreen.ask;

            _controller.reverse();

            if (isCupertino(context)) {
              initialScreen = await showCupertinoModalPopup(
                context: context,
                barrierDismissible: true,
                builder: (cupertino) => CupertinoActionSheet(
                  title: Text(l10n.mainScreen_importTask_action_import),
                  message: Text(l10n.mainScreen_importTask_action_importMethod),
                  actions: createCancellableDialogActions(
                    context,
                    [
                      CupertinoActionSheetAction(
                        isDefaultAction: true,
                        onPressed: () {
                          Navigator.of(context).pop(ImportScreen.askURL);
                        },
                        child: Text(
                            l10n.mainScreen_importTask_action_importMethod_url),
                      ),
                      CupertinoActionSheetAction(
                        isDefaultAction: true,
                        onPressed: () {
                          Navigator.of(context).pop(ImportScreen.importFile);
                        },
                        child: Text(l10n
                            .mainScreen_importTask_action_importMethod_file),
                      ),
                    ],
                  ),
                ),
              );
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

            _controller.forward();
          },
          material: (_, __) => MaterialElevatedButtonData(
            icon: const Icon(Icons.file_download_outlined),
          ),
          child: Text(l10n.mainScreen_importTask_action_import),
        ),
      ],
    );
  }
}
