import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:lottie/lottie.dart';

import '../../constants/spacing.dart';
import '../../utils/theme.dart';

class ImportSuccess extends StatefulWidget {
  final void Function() onClose;

  const ImportSuccess({
    required this.onClose,
    Key? key,
  }) : super(key: key);

  @override
  State<ImportSuccess> createState() => _ImportSuccessState();
}

class _ImportSuccessState extends State<ImportSuccess> with TickerProviderStateMixin {
  late final AnimationController _lottieController;

  @override
  void initState() {
    super.initState();

    _lottieController = AnimationController(vsync: this)
      ..addStatusListener((status) async {
        if (status == AnimationStatus.completed) {
          await Future.delayed(const Duration(seconds: 3));

          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      });
  }

  @override
  void dispose() {
    _lottieController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Lottie.asset(
          "assets/lotties/success.json",
          frameRate: FrameRate.max,
          controller: _lottieController,
          onLoaded: (composition) {
            _lottieController
              ..duration = composition.duration
              ..forward();
          },
        ),
        const SizedBox(height: MEDIUM_SPACE),
        Text(
          l10n.mainScreen_importTask_successMessage,
          textAlign: TextAlign.center,
          style: getSubTitleTextStyle(context),
        ),
        const SizedBox(height: MEDIUM_SPACE),
        PlatformElevatedButton(
          padding: const EdgeInsets.all(MEDIUM_SPACE),
          onPressed: widget.onClose,
          material: (_, __) => MaterialElevatedButtonData(
            icon: const Icon(Icons.check_rounded),
          ),
          child: Text(l10n.closePositiveSheetAction),
        ),
      ],
    );
  }
}
