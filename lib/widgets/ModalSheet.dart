import 'package:flutter/cupertino.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:locus/utils/theme.dart';

import '../constants/spacing.dart';
import '../utils/device.dart';

class ModalSheet extends StatelessWidget {
  final Widget child;

  const ModalSheet({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PlatformWidget(
      material: (_, __) => Padding(
        padding:
            isMIUI() ? const EdgeInsets.all(MEDIUM_SPACE) : EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            color: getSheetColor(context),
            borderRadius: isMIUI()
                ? const BorderRadius.all(Radius.circular(LARGE_SPACE))
                : const BorderRadius.only(
                    topLeft: Radius.circular(LARGE_SPACE),
                    topRight: Radius.circular(LARGE_SPACE),
                  ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              top: isMIUI() ? MEDIUM_SPACE : LARGE_SPACE,
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
          padding: const EdgeInsets.symmetric(
            vertical: LARGE_SPACE,
            horizontal: MEDIUM_SPACE,
          ),
          child: child,
        ),
      ),
    );
  }
}
