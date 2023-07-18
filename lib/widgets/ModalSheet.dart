import 'package:flutter/cupertino.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/utils/theme.dart';
import 'package:provider/provider.dart';

import '../constants/spacing.dart';
import '../services/settings_service.dart';

class ModalSheet extends StatelessWidget {
  final Widget child;
  final bool miuiIsGapless;
  final EdgeInsets cupertinoPadding;
  final EdgeInsets? materialPadding;

  const ModalSheet({
    Key? key,
    required this.child,
    this.miuiIsGapless = false,
    this.materialPadding,
    this.cupertinoPadding = const EdgeInsets.symmetric(
      vertical: LARGE_SPACE,
      horizontal: MEDIUM_SPACE,
    ),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: PlatformWidget(
        material: (_, __) => Padding(
          padding: settings.isMIUI() && !miuiIsGapless
              ? const EdgeInsets.all(MEDIUM_SPACE)
              : EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(
              maxWidth: 1200,
            ),
            decoration: BoxDecoration(
              color: getSheetColor(context),
              borderRadius: settings.isMIUI() && !miuiIsGapless
                  ? const BorderRadius.all(Radius.circular(LARGE_SPACE))
                  : const BorderRadius.only(
                      topLeft: Radius.circular(LARGE_SPACE),
                      topRight: Radius.circular(LARGE_SPACE),
                    ),
            ),
            child: Padding(
              padding: materialPadding ??
                  EdgeInsets.only(
                    top: settings.isMIUI() && !miuiIsGapless
                        ? MEDIUM_SPACE
                        : LARGE_SPACE,
                    left: MEDIUM_SPACE,
                    right: MEDIUM_SPACE,
                    bottom: SMALL_SPACE,
                  ),
              child: child,
            ),
          ),
        ),
        cupertino: (_, __) => CupertinoPopupSurface(
          isSurfacePainted: true,
          child: Padding(
            padding: cupertinoPadding,
            child: child,
          ),
        ),
      ),
    );
  }
}
